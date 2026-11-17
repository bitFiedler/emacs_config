#!/usr/bin/env python3
"""Run a reviewed project command in its image/mount-matched Docker container."""
import argparse
import hashlib
import importlib.util
import os
from pathlib import Path
import posixpath
import shlex
import sys
import time

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



def managed_name(image, host_root, container_root):
    """A stable name makes repeated/concurrent starts reuse the same container."""
    identity = '\0'.join((image, str(host_root), container_root, str(os.getuid())))
    return 'emacs-build-' + hashlib.sha256(identity.encode()).hexdigest()[:20]


def start_command(name, image, host_root, container_root):
    """Create an unprivileged persistent build environment, without pulling."""
    if ',' in str(host_root) or ',' in container_root:
        raise ValueError('Automatic startup cannot use commas in bind-mount paths')
    return ['run', '--detach', '--pull=never', '--name', name,
            '--label', 'emacs.project-build=1',
            '--user', f'{os.getuid()}:{os.getgid()}',
            '--mount', f'type=bind,source={host_root},target={container_root}',
            '--mount', 'type=bind,source=/etc/passwd,target=/etc/passwd,readonly',
            '--env', 'HOME=/tmp', '--workdir', container_root,
            '--entrypoint', '/bin/sh', image, '-c',
            "trap 'exit 0' TERM INT; while :; do sleep 3600 & wait $!; done"]


def ensure_container(image, host_root, container_root, auto_start=False):
    """Reuse a match; optionally create/restart only our deterministic container."""
    try:
        return docker.discover(image, host_root, container_root)
    except docker.NoMatchingContainerError:
        if not auto_start:
            raise
    # Permission, daemon and ambiguous-match errors never reach startup here.
    name = managed_name(image, host_root, container_root)
    identifiers = docker.docker_output(
        ['ps', '--all', '--filter', f'name=^/{name}$', '--format', '{{.ID}}']).split()
    if identifiers:
        records = docker.inspect_records(identifiers)
        # Validate image + mount even for a stopped container with this name.
        # Never start an unrelated container that happens to occupy the name.
        docker.select_container([{**record, 'Running': True} for record in records],
                                image, host_root, container_root)
        print(f'Restarting build container: {name}', flush=True)
        operation = ['start', name]
    else:
        print(f'Starting build container: {name}', flush=True)
        operation = start_command(name, image, host_root, container_root)
    startup_error = None
    try:
        docker.docker_output(operation)
    except docker.LauncherError as error:
        # Docker's unique name arbitrates concurrent starts.  The winner may
        # still be between create and start, so allow its startup to settle.
        startup_error = error
    for attempt in range(10):
        try:
            return docker.discover(image, host_root, container_root)
        except docker.NoMatchingContainerError:
            if attempt == 9:
                if startup_error is not None:
                    raise startup_error
                raise docker.LauncherError(
                    f'Build container {name} did not remain running. Inspect it with docker logs {name}.')
            time.sleep(0.1)



def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--image', required=True)
    parser.add_argument('--host-root', required=True, type=Path)
    parser.add_argument('--container-root', required=True)
    parser.add_argument('--directory', default='.')
    parser.add_argument('--command', required=True)
    parser.add_argument('--print-command', action='store_true')
    parser.add_argument('--auto-start', action='store_true',
                        help='start a background container only when no running image/mount match exists')
    args = parser.parse_args(argv)
    root = args.host_root.expanduser().resolve()
    if not root.is_dir():
        parser.error('--host-root must be an existing directory')
    # Validate before discovery, then select by exact image + checkout bind mount.
    command('', args.container_root, args.directory, args.command)
    container = ensure_container(args.image, root, posixpath.normpath(args.container_root),
                                 auto_start=args.auto_start and not args.print_command)
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
