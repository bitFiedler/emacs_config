"""Installer integration checks using isolated homes and miniature repositories."""
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

spec = importlib.util.spec_from_file_location('emacs_config_install', Path(__file__).resolve().parents[1] / 'install.py')
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='emacs-config-installer-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.home = self.root / 'home'
        self.repo = self.root / 'repo'
        self.home.mkdir()
        for name, text in {'.emacs': 'new init', '.emacs.d/early-init.el': 'early init',
                           '.emacs.d/custom.el': 'custom seed', 'emacstools/my-personal.el': 'personal module',
                           'emacstools/my-personal-tests.el': 'test suite',
                           'emacstools/my-docker-clangd.py': 'launcher',
                           'emacstools/assets/theme.css': 'theme'}.items():
            p = self.repo / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(text)
        self.stdout = io.StringIO()
        self.redirect = contextlib.redirect_stdout(self.stdout)
        self.redirect.__enter__()
        self.addCleanup(self.redirect.__exit__, None, None, None)

    def write(self, name, text):
        p = self.home / name
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)
        return p

    def install(self, **kwargs):
        return installer.install(self.repo, self.home, **kwargs)

    def session(self, identifier):
        return self.home / 'emacstools/backup/install' / identifier

    def test_submodule_directory_install_and_recovery(self):
        name = 'emacstools/emacs-libvterm'
        (self.repo / '.gitmodules').write_text(f'[submodule "vterm"]\npath = {name}\nurl = https://example.invalid/vterm\n')
        module = self.repo / name
        module.mkdir()
        (module / '.git').write_text('gitdir: ../../.git/modules/vterm')
        (module / 'vterm.el').write_text('upstream')
        self.write(name + '/vterm-module.so', 'old native module')
        identifier = self.install(backup=True)
        self.assertEqual((self.home / name).resolve(), module)
        self.assertIsNone(self.install())
        installer.restore(self.home, identifier)
        self.assertFalse((self.home / name).is_symlink())
        self.assertEqual((self.home / name / 'vterm-module.so').read_text(), 'old native module')

    def test_uninitialized_submodule_stops_before_writes(self):
        (self.repo / '.gitmodules').write_text('[submodule "vterm"]\npath = emacstools/emacs-libvterm\n')
        with self.assertRaisesRegex(installer.InstallError, 'submodule update'):
            self.install()
        self.assertEqual(list(self.home.iterdir()), [])

    def test_fresh_install_links_assets_seeds_custom_and_is_repeatable(self):
        identifier = self.install()
        self.assertEqual((self.home / '.emacs').resolve(), self.repo / '.emacs')
        self.assertEqual((self.home / 'emacstools/assets/theme.css').resolve(), self.repo / 'emacstools/assets/theme.css')
        self.assertFalse((self.home / '.emacs.d/custom.el').is_symlink())
        self.assertEqual((self.home / '.emacs.d/custom.el').read_text(), 'custom seed')
        self.assertFalse((self.home / 'emacstools/my-personal-tests.el').exists())
        self.assertEqual((self.home / 'emacstools/my-docker-clangd.py').resolve(),
                         self.repo / 'emacstools/my-docker-clangd.py')
        self.assertIsNone(self.install())
        self.assertEqual(len(installer.sessions(self.home)), 1)
        installer.restore(self.home, 'latest')
        self.assertFalse(installer.exists(self.home / '.emacs'))
        self.assertFalse((self.home / '.emacs.d').exists())
        installer.restore(self.home, identifier)  # Already restored is harmless.

    def test_replaces_and_restores_file_mode_dangling_symlink_directory_and_compiled_file(self):
        original = self.write('.emacs', 'old init')
        original.chmod(0o600)
        module = self.home / 'emacstools/my-personal.el'
        module.parent.mkdir()
        module.symlink_to('missing-old-module.el')
        target = self.home / 'emacstools/assets/theme.css'
        target.mkdir(parents=True)
        (target / 'preserved.txt').write_text('directory data')
        self.write('.emacs.elc', 'old compiled init')
        identifier = self.install(backup=True)
        self.assertFalse((self.home / '.emacs.elc').exists())
        self.assertTrue((self.session(identifier) / 'files/emacstools/my-personal.el').is_symlink())
        installer.restore(self.home, identifier)
        self.assertEqual(original.read_text(), 'old init')
        self.assertEqual(original.stat().st_mode & 0o777, 0o600)
        self.assertEqual(module.readlink(), Path('missing-old-module.el'))
        self.assertEqual((target / 'preserved.txt').read_text(), 'directory data')
        self.assertEqual((self.home / '.emacs.elc').read_text(), 'old compiled init')

    def test_existing_custom_packages_and_upstream_sources_remain_local(self):
        custom = self.write('.emacs.d/custom.el', 'device preferences')
        package = self.write('.emacs.d/elpa/package/state', 'installed package')
        upstream = self.write('emacstools/upstream/library.el', 'upstream')
        identifier = self.install()
        self.assertEqual(custom.read_text(), 'device preferences')
        self.assertFalse(custom.is_symlink())
        installer.restore(self.home, identifier)
        for p, expected in [(custom, 'device preferences'), (package, 'installed package'), (upstream, 'upstream')]:
            self.assertEqual(p.read_text(), expected)

    def test_dry_run_makes_no_directories_and_does_not_prompt(self):
        with mock.patch.object(installer, 'ask', side_effect=AssertionError('unexpected prompt')):
            self.install(dry_run=True)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_quit_and_skip_preserve_existing_configuration(self):
        original = self.write('.emacs', 'original')
        with mock.patch.object(installer, 'ask', return_value='q'):
            self.assertIsNone(self.install())
        self.assertEqual(list(self.home.iterdir()), [original])
        with mock.patch.object(installer, 'ask', return_value='s'):
            identifier = self.install()
        self.assertEqual(original.read_text(), 'original')
        self.assertTrue((self.home / '.emacs.d/early-init.el').is_symlink())
        installer.restore(self.home, identifier)
        self.assertEqual(original.read_text(), 'original')

    def test_noninteractive_conflict_requires_explicit_backup_approval(self):
        original = self.write('.emacs', 'original')
        with mock.patch.object(installer.sys.stdin, 'isatty', return_value=False):
            with self.assertRaises(installer.InstallError):
                self.install()
        self.assertEqual(list(self.home.iterdir()), [original])

    def test_recovery_preserves_newer_edits_and_edited_custom_seed(self):
        original = self.write('.emacs', 'original')
        identifier = self.install(backup=True)
        original.unlink()
        original.write_text('new local edits')
        custom = self.home / '.emacs.d/custom.el'
        custom.write_text('new device customization')
        with mock.patch.object(installer, 'ask', return_value='n'):
            installer.restore(self.home, identifier)
        self.assertEqual(original.read_text(), 'new local edits')
        installer.restore(self.home, identifier, backup=True)
        saved = self.session(identifier) / 'recovery-saved'
        self.assertEqual((saved / '.emacs').read_text(), 'new local edits')
        self.assertEqual((saved / '.emacs.d/custom.el').read_text(), 'new device customization')
        self.assertEqual(original.read_text(), 'original')
        self.assertFalse(custom.exists())

    def test_interrupted_install_can_restore_original_before_link_creation(self):
        self.write('.emacs', 'original')
        errors = io.StringIO()
        with contextlib.redirect_stderr(errors):
            with mock.patch.object(Path, 'symlink_to', side_effect=OSError('simulated failure')):
                with self.assertRaises(OSError):
                    self.install(backup=True)
        self.assertIn('--restore', errors.getvalue())
        self.assertFalse((self.home / '.emacs').exists())
        installer.restore(self.home, 'latest')
        self.assertEqual((self.home / '.emacs').read_text(), 'original')

    def test_symlinked_parent_directory_is_rejected_before_any_writes(self):
        outside = self.root / 'outside'
        outside.mkdir()
        (self.home / '.emacs.d').symlink_to(outside, target_is_directory=True)
        with self.assertRaises(installer.InstallError):
            self.install(backup=True)
        self.assertFalse((self.home / 'emacstools').exists())
        self.assertEqual(list(outside.iterdir()), [])

    def test_recovery_rejects_unsafe_manifest_and_corrupted_backup(self):
        self.write('.emacs', 'original')
        identifier = self.install(backup=True)
        manifest = self.session(identifier) / 'manifest.json'
        data = json.loads(manifest.read_text())
        data['entries'][0]['target'] = '../outside'
        manifest.write_text(json.dumps(data))
        with self.assertRaises(installer.InstallError):
            installer.restore(self.home, identifier)
        data['entries'][0]['target'] = '.emacs'
        manifest.write_text(json.dumps(data))
        (self.session(identifier) / 'files/.emacs').write_text('corrupted backup')
        with self.assertRaises(installer.InstallError):
            installer.restore(self.home, identifier)
        self.assertTrue((self.home / '.emacs').is_symlink())


if __name__ == '__main__':
    unittest.main()
