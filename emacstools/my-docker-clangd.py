#!/usr/bin/env python3
"""Run clangd in the running Docker container matching an image and project mount."""
import argparse
import json
import os
from pathlib import Path
import posixpath
import shlex
import subprocess
import sys


class LauncherError(Exception):
    pass


def docker_output(arguments):
    try:
        result = subprocess.run(['docker', *arguments], stdin=subprocess.DEVNULL,
                                capture_output=True, text=True, timeout=15, check=True)
    except FileNotFoundError as error:
        raise LauncherError('docker is not available on PATH') from error
    except subprocess.TimeoutExpired as error:
        raise LauncherError('Docker discovery timed out after 15 seconds') from error
    except subprocess.CalledProcessError as error:
        raise LauncherError(error.stderr.strip() or 'Docker discovery failed') from error
    return result.stdout


def select_container(records, image, host_root, container_root):
    matches = []
    for record in records:
        if not record['Running'] or record['Image'] != image:
            continue
        if any(mount.get('Type') == 'bind'
               and Path(mount['Source']).resolve() == host_root
               and posixpath.normpath(mount['Destination']) == container_root
               for mount in record['Mounts']):
            matches.append(record['Id'])
    if not matches:
        raise LauncherError(f'No running container for {image} mounting {host_root} at {container_root}. Start the project build container first.')
    if len(matches) != 1:
        raise LauncherError(f'{len(matches)} matching containers: {", ".join(matches)}. Stop duplicate project containers before starting Eglot.')
    return matches[0]


def discover(image, host_root, container_root):
    identifiers = docker_output(['ps', '--filter', f'ancestor={image}', '--format', '{{.ID}}']).split()
    records = []
    if identifiers:
        # Select only metadata required for matching; never fetch container environment/secrets.
        template = ('{"Id":{{json .Id}},"Image":{{json .Config.Image}},'
                    '"Running":{{json .State.Running}},"Mounts":{{json .Mounts}}}')
        output = docker_output(['inspect', '--format', template, *identifiers])
        records = [json.loads(line) for line in output.splitlines() if line.strip()]
    return select_container(records, image, host_root, container_root)


def command(container, host_root, container_root, database, clangd, extra):
    if ',' in str(host_root) or '=' in str(host_root):
        raise LauncherError('Host path cannot contain comma or equals: clangd path-mapping delimiters')
    if any(char in container_root for char in ',='):
        raise LauncherError('Container path cannot contain comma or equals')
    return ['docker', 'exec', '-i', container, clangd,
            '--compile-commands-dir=' + database,
            f'--path-mappings={host_root}={container_root}',
            '--background-index', '--clang-tidy=false', '--header-insertion=never', *extra]


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--image', required=True)
    parser.add_argument('--host-root', required=True, type=Path)
    parser.add_argument('--container-root', default='/leo')
    parser.add_argument('--database', help='absolute compilation database directory inside container')
    parser.add_argument('--clangd', default='clangd', help='clangd executable inside container')
    parser.add_argument('--print-command', action='store_true', help='show selected command without starting clangd')
    parser.add_argument('clangd_args', nargs=argparse.REMAINDER, help='additional clangd options after --')
    args = parser.parse_args(argv)
    host_root = args.host_root.expanduser().resolve()
    container_root = posixpath.normpath(args.container_root)
    if not host_root.is_dir() or not container_root.startswith('/'):
        parser.error('host root must be an existing directory; container root must be absolute')
    database = args.database or posixpath.join(container_root, 'images/scratch/tools_build')
    if not database.startswith('/'):
        parser.error('--database must be absolute inside the container')
    container = discover(args.image, host_root, container_root)
    extra = args.clangd_args
    if extra[:1] == ['--']:
        extra = extra[1:]
    argv = command(container, host_root, container_root, database, args.clangd, extra)
    if args.print_command:
        print(shlex.join(argv))
        return
    # Replace ourselves: preserve raw LSP stdin/stdout, stderr and exit status. No TTY.
    os.execvp(argv[0], argv)


if __name__ == '__main__':
    try:
        main()
    except (LauncherError, OSError, ValueError) as error:
        print(f'docker-clangd: {error}', file=sys.stderr)
        sys.exit(1)
