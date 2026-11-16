#!/usr/bin/env python3
"""Link personal Emacs configuration into a home directory, with recoverable backups."""
import argparse
import configparser
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import shlex
import sys


class InstallError(Exception):
    """An installation cannot proceed without risking existing data."""


def exists(path):
    return os.path.lexists(path)


def fingerprint(path):
    if path.is_symlink():
        return {'type': 'link', 'target': os.readlink(path)}
    if path.is_file():
        return {'type': 'file', 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    if path.is_dir():
        return {'type': 'directory'}
    if exists(path):
        raise InstallError(f'Unsupported special file: {path}')
    return None


def relative(value):
    path = Path(value)
    if path.is_absolute() or not path.parts or '..' in path.parts or path == Path('.'):
        raise InstallError(f'Unsafe relative path: {value}')
    return path


def check_parents(home, destination):
    """Reject redirecting directory symlinks before making any changes."""
    try:
        parts = destination.relative_to(home).parts[:-1]
    except ValueError as error:
        raise InstallError(f'Destination is outside the selected home: {destination}') from error
    current = home
    for part in parts:
        current /= part
        if current.is_symlink() or (exists(current) and not current.is_dir()):
            raise InstallError(f'Parent must be a real directory, not a link or file: {current}')


def submodule_sources(repo):
    """Read pinned source directories without downloading anything."""
    manifest = repo / '.gitmodules'
    if not manifest.exists():
        return []
    config = configparser.ConfigParser(interpolation=None)
    config.read(manifest)
    sources = []
    for section in config.sections():
        name = relative(config[section]['path'])
        if len(name.parts) != 2 or name.parts[0] != 'emacstools':
            raise InstallError(f'Unsupported submodule path: {name}')
        source = repo / name
        if source.is_symlink() or not source.is_dir() or not (source / '.git').exists():
            raise InstallError('Initialize submodules first: git submodule update --init --recursive')
        sources.append(source)
    return sources


def make_plan(repo, home):
    sources = [repo / '.emacs', repo / '.emacs.d/early-init.el']
    sources += sorted(p for p in (repo / 'emacstools').iterdir()
                      if p.is_file() and p.suffix in ('.el', '.cjs', '.py')
                      and not p.name.endswith('-tests.el'))
    sources += sorted(p for p in (repo / 'emacstools/assets').iterdir()
                      if p.is_file() and p.suffix in ('.css', '.js', '.html', '.woff2'))
    modules = submodule_sources(repo)
    plan = []
    for source in sources + modules:
        if source.is_symlink() or (source not in modules and not source.is_file()):
            raise InstallError(f'Expected a regular repository file: {source}')
        target = home / source.relative_to(repo)
        check_parents(home, target)
        if not (target.is_symlink() and target.resolve() == source.resolve()):
            plan.append({'target': str(source.relative_to(repo)), 'kind': 'link',
                         'source': str(source), 'expected': {'type': 'link', 'target': str(source)}})
    # Custom writes remain local. Seed a new machine without replacing its existing preferences.
    custom = home / '.emacs.d/custom.el'
    check_parents(home, custom)
    if not exists(custom):
        seed = repo / '.emacs.d/custom.el'
        if not seed.is_file() or seed.is_symlink():
            raise InstallError(f'Missing regular Custom seed: {seed}')
        plan.append({'target': '.emacs.d/custom.el', 'kind': 'copy', 'source': str(seed),
                     'expected': fingerprint(seed)})
    # These compiled files can shadow the linked source. Back them up rather than load stale code.
    compiled = ['.emacs.elc', '.emacs.d/early-init.elc']
    compiled += [str(p.relative_to(repo).with_suffix('.elc')) for p in sources if p.suffix == '.el']
    for name in dict.fromkeys(compiled):
        target = home / name
        check_parents(home, target)
        if exists(target):
            plan.append({'target': name, 'kind': 'disable', 'source': None, 'expected': None})
    for entry in plan:
        entry['original'] = fingerprint(home / entry['target'])
    check_parents(home, home / 'emacstools/backup/install/session/manifest.json')
    return plan


def ask(message, choices):
    if not sys.stdin.isatty():
        raise InstallError('Existing data requires a decision. Run interactively, or use --backup to approve backups and replacement.')
    try:
        return input(message).strip().lower() or choices[-1]
    except EOFError:
        return choices[-1]


def save_journal(session, data):
    temporary = session / 'manifest.json.tmp'
    with temporary.open('w', encoding='utf-8') as stream:
        json.dump(data, stream, indent=2)
        stream.write('\n')
        stream.flush()
        os.fsync(stream.fileno())
    temporary.chmod(0o600)
    temporary.replace(session / 'manifest.json')


def ensure_parent(home, target, data, session):
    missing = []
    parent = target.parent
    while parent != home and not exists(parent):
        missing.append(parent)
        parent = parent.parent
    for directory in reversed(missing):
        name = str(directory.relative_to(home))
        if name not in data['created_dirs']:
            data['created_dirs'].append(name)
            save_journal(session, data)
        directory.mkdir()


def install(repo, home, backup=False, dry_run=False, plan=None):
    if plan is None:
        plan = make_plan(repo, home)
    conflicts = [entry for entry in plan if entry['original'] is not None]
    for entry in plan:
        action = 'BACK UP + ' if entry['original'] else ''
        print(f"{action}{entry['kind'].upper()}: {home / entry['target']}")
    if not plan:
        print('Already installed; no changes and no new backup session.')
        return None
    if dry_run:
        print(f'Dry run: {len(plan)} changes; {len(conflicts)} existing paths would require approval. Nothing written.')
        return None
    if conflicts and not backup:
        choice = ask(f'Existing data at {len(conflicts)} paths. [b]ack up and replace all, [s]kip existing paths, [q]uit (default): ', ['b', 's', 'q'])
        if choice == 's':
            plan = [entry for entry in plan if entry['original'] is None]
        elif choice != 'b':
            print('Cancelled; nothing changed.')
            return None
    if not plan:
        print('All proposed changes skipped; nothing changed.')
        return None
    identifier = datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f') + '-' + str(os.getpid())
    session = home / 'emacstools/backup/install' / identifier
    session.mkdir(parents=True, mode=0o700)
    data = {'version': 1, 'home': str(home), 'repo': str(repo), 'id': identifier,
            'status': 'installing', 'created_dirs': [], 'entries': []}
    for entry in plan:
        entry = dict(entry)
        entry['backup'] = str(Path('files') / entry['target']) if entry['original'] else None
        entry['state'] = 'pending'
        data['entries'].append(entry)
    save_journal(session, data)
    try:
        for entry in data['entries']:
            target = home / entry['target']
            # Catch concurrent edits after the decision, before moving the original.
            if fingerprint(target) != entry['original']:
                raise InstallError(f'Destination changed during installation: {target}')
            ensure_parent(home, target, data, session)
            if entry['backup']:
                stored = session / entry['backup']
                stored.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(target), str(stored))
                entry['state'] = 'backed-up'
                save_journal(session, data)
            if entry['kind'] == 'link':
                target.symlink_to(entry['source'])
            elif entry['kind'] == 'copy':
                shutil.copy2(entry['source'], target)
            entry['state'] = 'installed'
            save_journal(session, data)
        data['status'] = 'installed'
        save_journal(session, data)
    except (Exception, KeyboardInterrupt):
        command = shlex.join(['python3', str(repo / 'install.py'), '--home', str(home), '--restore', identifier])
        print(f'Installation interrupted. Recover with: {command}', file=sys.stderr)
        raise
    print(f'Installed. Recovery ID: {identifier}\nBackup manifest: {session / "manifest.json"}')
    print('Existing custom.el, packages, upstream checkouts and runtime state were kept local.')
    return identifier


def sessions(home):
    directory = home / 'emacstools/backup/install'
    check_parents(home, directory / 'session/manifest.json')
    return sorted(directory.glob('*/manifest.json'), reverse=True) if directory.is_dir() else []


def read_session(home, identifier):
    candidates = sessions(home)
    if identifier == 'latest':
        candidates = [p for p in candidates if json.loads(p.read_text())['status'] != 'restored']
        if not candidates:
            raise InstallError('No unrestored backup sessions found.')
        manifest = candidates[0]
    else:
        if Path(identifier).name != identifier or identifier in ('.', '..'):
            raise InstallError('Use a backup ID or latest, not a path.')
        manifest = home / 'emacstools/backup/install' / identifier / 'manifest.json'
    check_parents(home, manifest)
    if manifest.is_symlink():
        raise InstallError('Recovery manifest must not be a symlink.')
    data = json.loads(manifest.read_text())
    if data.get('version') != 1 or data.get('home') != str(home):
        raise InstallError('Recovery manifest version or home directory does not match.')
    session = manifest.parent
    for name in data['created_dirs']:
        check_parents(home, home / relative(name) / '.check-parent')
    for entry in data['entries']:
        target = home / relative(entry['target'])
        check_parents(home, target)
        if entry['backup']:
            stored = relative(entry['backup'])
            if stored != Path('files') / relative(entry['target']):
                raise InstallError('Invalid backup path in manifest.')
            check_parents(session, session / stored)
    return session, data


def restore(home, identifier, backup=False, dry_run=False):
    session, data = read_session(home, identifier)
    if data['status'] == 'restored':
        print('This session is already restored; nothing changed.')
        return
    work = []
    for entry in reversed(data['entries']):
        if entry['state'] == 'restored':
            continue
        target = home / entry['target']
        stored = session / entry['backup'] if entry['backup'] else None
        current = fingerprint(target)
        if stored is not None and not exists(stored):
            # Pending operations never moved the original; a previously completed restore may
            # also have moved the original back before its journal update was interrupted.
            if current == entry['original']:
                continue
            raise InstallError(f'Original backup is missing; refusing to change {target}')
        if stored is not None and fingerprint(stored) != entry['original']:
            raise InstallError(f'Backup no longer matches the original: {stored}')
        if stored is None and current is None:
            continue
        changed = current is not None and current != entry['expected']
        print(('SAVE CHANGED DATA + ' if changed else '') + f'RESTORE: {target}')
        work.append((entry, target, stored, current, changed))
    if dry_run:
        print('Recovery dry run; nothing written.')
        return
    if any(item[4] for item in work) and not backup:
        choice = ask('Some destinations changed since installation. Back up these newer files before rollback? [y/N]: ', ['y', 'n'])
        if choice != 'y':
            print('Recovery cancelled; nothing changed.')
            return
    for entry, target, stored, current, changed in work:
        if fingerprint(target) != current:
            raise InstallError(f'Destination changed during recovery: {target}')
        if current is not None:
            if changed:
                saved = session / 'recovery-saved' / entry['target']
                while exists(saved):
                    saved = saved.with_name(saved.name + '.saved')
                saved.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(target), str(saved))
                print(f'Newer data preserved at: {saved}')
            else:
                # An unchanged installed destination can only be our symlink or seeded file.
                target.unlink()
        if stored is not None:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(stored), str(target))
        entry['state'] = 'restored'
        save_journal(session, data)
    # Preserve backup journals and every nonempty directory, including runtime data.
    for name in sorted(data['created_dirs'], key=lambda value: len(Path(value).parts), reverse=True):
        directory = home / relative(name)
        if directory.is_dir() and not directory.is_symlink():
            try:
                directory.rmdir()
            except OSError:
                pass
    data['status'] = 'restored'
    save_journal(session, data)
    print(f'Restored session {data["id"]}. Backup journal retained at {session}.')


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--home', type=Path, default=Path.home(), help='Target home directory (default: current user)')
    parser.add_argument('--dry-run', action='store_true', help='Show the install or recovery plan without writing')
    parser.add_argument('--backup', action='store_true', help='Approve backing up existing/changed data without prompting')
    actions = parser.add_mutually_exclusive_group()
    actions.add_argument('--restore', '--recover', metavar='ID', help='Roll back ID or latest; supports --dry-run')
    actions.add_argument('--list-backups', action='store_true', help='List recovery IDs and status')
    args = parser.parse_args(argv)
    home = args.home.expanduser().resolve()
    repo = Path(__file__).resolve().parent
    try:
        if not home.is_dir():
            raise InstallError(f'Target home must already exist: {home}')
        if home == repo or repo in home.parents or home in (repo / '.emacs.d', repo / 'emacstools'):
            raise InstallError('Target home must not be inside the repository.')
        if args.list_backups:
            for path in sessions(home):
                data = json.loads(path.read_text())
                print(f'{data["id"]}  {data["status"]}')
        elif args.restore:
            restore(home, args.restore, args.backup, args.dry_run)
        else:
            install(repo, home, args.backup, args.dry_run)
        return 0
    except (InstallError, OSError, ValueError, KeyError) as error:
        print(f'Error: {error}', file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print('Cancelled.', file=sys.stderr)
        return 130


if __name__ == '__main__':
    sys.exit(main())
