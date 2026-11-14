#!/usr/bin/env python3
"""Build pinned vterm/booster sources and install for the current user."""
import argparse
import importlib.util
import os
from pathlib import Path
import platform
import shlex
import shutil
import subprocess
import sys

REPO = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('config_installer', REPO / 'install.py')
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


def commands(repo, jobs, cmake_args=()):
    vterm = repo / 'emacstools/emacs-libvterm'
    booster = repo / 'emacstools/emacs-lsp-booster'
    return [
        ['cmake', '-S', str(vterm), '-B', str(vterm / 'build'), *cmake_args],
        ['cmake', '--build', str(vterm / 'build'), '--parallel', str(jobs)],
        ['cargo', 'build', '--release', '--locked', '--manifest-path', str(booster / 'Cargo.toml'),
         '--target-dir', str(booster / 'target'), '--jobs', str(jobs)],
    ]


def deployment(repo, home, binary):
    plan = []
    for source in installer.submodule_sources(repo):
        target = home / source.relative_to(repo)
        installer.check_parents(home, target)
        if target.is_symlink() and target.resolve() == source.resolve():
            continue
        plan.append({'target': str(source.relative_to(repo)), 'kind': 'link', 'source': str(source),
                     'original': installer.fingerprint(target),
                     'expected': {'type': 'link', 'target': str(source)}})
    target = home / '.local/bin/emacs-lsp-booster'
    installer.check_parents(home, target)
    expected = installer.fingerprint(binary)
    if installer.fingerprint(target) != expected or not os.access(target, os.X_OK):
        plan.append({'target': str(target.relative_to(home)), 'kind': 'copy', 'source': str(binary),
                     'original': installer.fingerprint(target), 'expected': expected})
    installer.check_parents(home, home / 'emacstools/backup/install/session/manifest.json')
    return plan


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--home', type=Path, default=Path.home(), help='existing target home directory')
    parser.add_argument('--jobs', type=int, default=min(os.cpu_count() or 2, 8))
    parser.add_argument('--dry-run', action='store_true', help='print commands; do not build or install')
    parser.add_argument('--build-only', action='store_true', help='compile without changing installed paths')
    parser.add_argument('--backup', action='store_true', help='approve recoverable replacement of existing destinations')
    parser.add_argument('--cmake-arg', action='append', default=[], help='extra CMake option; use --cmake-arg=-DNAME=value')
    args = parser.parse_args(argv)
    if platform.system() not in ('Linux', 'Darwin'):
        parser.error('Supported systems: Linux and macOS')
    home = args.home.expanduser().resolve()
    if not home.is_dir() or args.jobs < 1:
        parser.error('--home must exist and --jobs must be positive')
    installer.submodule_sources(REPO)
    for command in commands(REPO, args.jobs, args.cmake_arg):
        print('+ ' + shlex.join(command), flush=True)
        if not args.dry_run:
            if not shutil.which(command[0]):
                raise installer.InstallError(f'Missing {command[0]}; see readme.md native-build requirements')
            subprocess.run(command, check=True)
    if args.dry_run:
        if args.build_only:
            print('Build-only dry run; no deployment planned.')
            return
        print(f'Would link both source directories under {home / "emacstools"} and install booster to {home / ".local/bin"}.')
        print('Existing destinations use the installer backup/skip/cancel prompt; no files written.')
        return
    if args.build_only:
        return
    vterm = REPO / 'emacstools/emacs-libvterm/vterm-module.so'
    binary = REPO / 'emacstools/emacs-lsp-booster/target/release/emacs-lsp-booster'
    if not vterm.is_file() or not binary.is_file():
        raise installer.InstallError('Build outputs missing; nothing installed')
    installer.install(REPO, home, backup=args.backup, plan=deployment(REPO, home, binary))
    print('Ensure ~/.local/bin is in PATH and Emacs exec-path. Restart Emacs to load a rebuilt native module.')


if __name__ == '__main__':
    try:
        main()
    except (installer.InstallError, subprocess.CalledProcessError) as error:
        print(f'Error: {error}', file=sys.stderr)
        sys.exit(1)
