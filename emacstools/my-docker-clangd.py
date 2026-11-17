#!/usr/bin/env python3
"""Run clangd in the running Docker container matching an image and project mount."""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import posixpath
import shlex
import subprocess
import sys
import tempfile


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


def analysis_database(host_root, container_root, database, remove_flags, write=True):
    """Create a derived Bear/CMake database without changing the original."""
    if not remove_flags:
        return database
    try:
        relative = PurePosixPath(posixpath.normpath(database)).relative_to(container_root)
    except ValueError as error:
        raise LauncherError('Flag filtering requires the database inside the project bind mount') from error
    source = host_root / str(relative) / 'compile_commands.json'
    raw = source.read_bytes()
    entries = json.loads(raw)
    for entry in entries:
        arguments = entry.get('arguments')
        if arguments is None:
            arguments = shlex.split(entry.pop('command'))
        entry['arguments'] = [arg for arg in arguments if arg not in remove_flags]
    identity = hashlib.sha256(raw + json.dumps(sorted(remove_flags)).encode()).hexdigest()[:20]
    relative_cache = Path('.cache/my-docker-clangd') / identity
    cache = host_root / relative_cache
    current = host_root
    for part in relative_cache.parts:
        current /= part
        if current.is_symlink():
            raise LauncherError(f'Analysis cache parent must not be a symlink: {current}')
    if write:
        cache.mkdir(parents=True, exist_ok=True, mode=0o700)
        # Atomic publication prevents a second server from reading partial JSON.
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(mode='w', dir=cache, delete=False) as stream:
                temporary = Path(stream.name)
                json.dump(entries, stream, indent=2)
                stream.write('\n')
            temporary.replace(cache / 'compile_commands.json')
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)
    return posixpath.join(container_root, relative_cache.as_posix())


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--image', required=True)
    parser.add_argument('--host-root', required=True, type=Path)
    parser.add_argument('--container-root', default='/leo')
    parser.add_argument('--database', help='absolute compilation database directory inside container')
    parser.add_argument('--clangd', default='clangd', help='clangd executable inside container')
    parser.add_argument('--remove-compile-flag', action='append', default=[],
                        help='exact compiler flag to omit from a derived analysis database; use --remove-compile-flag=-flag')
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
    database = analysis_database(host_root, container_root, database,
                                 args.remove_compile_flag, write=not args.print_command)
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
