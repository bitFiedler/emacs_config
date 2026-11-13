#!/usr/bin/env python3
"""Install bundled Emacs fonts without root; preserve changed destinations."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    home = Path.home()
    root = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--font-dir', type=Path,
                        default=Path(os.environ.get('XDG_DATA_HOME', home / '.local/share')) / 'fonts/emacs-config')
    parser.add_argument('--asset-dir', type=Path, default=home / 'emacstools/assets')
    parser.add_argument('--backup-dir', type=Path, default=home / 'emacstools/backup/fonts')
    parser.add_argument('--dry-run', action='store_true', help='Show changes without writing files or refreshing caches')
    parser.add_argument('--skip-cache', action='store_true', help='Do not run fc-cache')
    args = parser.parse_args()
    for entry in json.loads((root / 'fonts/manifest.json').read_text()):
        source = root / entry['path']
        if digest(source) != entry['sha256']:
            parser.error('Font checksum mismatch: ' + entry['path'])

    sources = sorted((root / 'fonts/JetBrainsMono').iterdir())
    sources += sorted((root / 'fonts/SymbolsNerdFontMono').iterdir())
    plan = [(src, args.font_dir / src.relative_to(root / 'fonts')) for src in sources if src.is_file()]
    plan.append((root / 'emacstools/assets/nerd-symbols.woff2', args.asset_dir / 'nerd-symbols.woff2'))
    backup_root = args.backup_dir / (datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f') + '-' + str(os.getpid()))
    changed = 0
    for source, target in plan:
        if target.is_file() and digest(target) == digest(source):
            continue
        print(('Would install: ' if args.dry_run else 'Installing: ') + str(target))
        changed += 1
        if args.dry_run:
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists():
            if not target.is_file():
                parser.error('Destination is not a regular file: ' + str(target))
            # Encode destination identity so duplicate basenames do not collide.
            backup = backup_root / (hashlib.sha256(str(target.absolute()).encode()).hexdigest()[:16] + '-' + target.name)
            backup.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(target, backup)
            if digest(backup) != digest(target):
                raise RuntimeError('Backup verification failed: ' + str(target))
            print('  Backup: ' + str(backup))
        shutil.copyfile(source, target)
        target.chmod(0o644)
        if digest(target) != digest(source):
            raise RuntimeError('Installed font verification failed: ' + str(target))
    if changed and not args.dry_run and not args.skip_cache:
        cache = shutil.which('fc-cache')
        if cache:
            subprocess.run([cache, '-f', str(args.font_dir)], check=True)
        else:
            print('fc-cache is unavailable; refresh your font cache when available.')
    print(('Planned' if args.dry_run else 'Installed') + f' {changed} changed files; unchanged files skipped.')


if __name__ == '__main__':
    main()
