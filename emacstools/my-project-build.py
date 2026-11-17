#!/usr/bin/env python3
"""Run a reviewed project command in its image/mount-matched Docker container."""
import argparse
import importlib.util
import os
from pathlib import Path
import posixpath
import shlex
import sys

# Reuse exactly the same image/mount selection rules as the Eglot launcher.
spec = importlib.util.spec_from_file_location(
    'my_docker_clangd', Path(__file__).resolve().with_name('my-docker-clangd.py'))
docker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(docker)


def command(container, container_root, directory, shell_command):
    root = posixpath.normpath(container_root)
    work = posixpath.normpath(posixpath.join(root, directory))
    if not root.startswith('/') or posixpath.isabs(directory) or not (
            work == root or work.startswith(root.rstrip('/') + '/')):
        raise ValueError('Task directory must be relative and stay inside the project mount')
    return ['docker', 'exec', '--workdir', work, container,
            'sh', '-c', shell_command]


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--image', required=True)
    parser.add_argument('--host-root', required=True, type=Path)
    parser.add_argument('--container-root', required=True)
    parser.add_argument('--directory', default='.')
    parser.add_argument('--command', required=True)
    parser.add_argument('--print-command', action='store_true')
    args = parser.parse_args(argv)
    root = args.host_root.expanduser().resolve()
    if not root.is_dir():
        parser.error('--host-root must be an existing directory')
    # Validate before discovery, then select by exact image + checkout bind mount.
    command('', args.container_root, args.directory, args.command)
    container = docker.discover(args.image, root, posixpath.normpath(args.container_root))
    execute = command(container, args.container_root, args.directory, args.command)
    if args.print_command:
        print(shlex.join(execute))
        return
    print(f'Build container: {container} ({args.image})', flush=True)
    # No TTY or interactive stdin: ordinary compilation output, including failures.
    os.execvp(execute[0], execute)


if __name__ == '__main__':
    try:
        main()
    except (docker.LauncherError, OSError, ValueError) as error:
        print(f'project-build: {error}', file=sys.stderr)
        sys.exit(1)
