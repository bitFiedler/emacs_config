"""Native-build orchestration checks; no compiler, network or live home needed."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('build_native', Path(__file__).resolve().parents[1] / 'build-native.py')
build = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build)


class NativeTests(unittest.TestCase):
    def test_commands_pin_lockfile_and_handle_spaces(self):
        commands = build.commands(Path('/tmp/repo with spaces'), 3, ['-DUSE_SYSTEM_LIBVTERM=OFF'])
        self.assertIn('-DUSE_SYSTEM_LIBVTERM=OFF', commands[0])
        self.assertIn('--locked', commands[2])
        self.assertIn('/tmp/repo with spaces/emacstools/emacs-lsp-booster/target', commands[2])
        self.assertEqual(commands[1][-1], '3')

    def test_native_binary_install_is_repeatable_and_recoverable(self):
        with tempfile.TemporaryDirectory() as root:
            repo = Path(root) / 'repo'
            home = Path(root) / 'home'
            repo.mkdir()
            home.mkdir()
            binary = repo / 'booster'
            binary.write_bytes(b'new executable')
            binary.chmod(0o755)
            target = home / '.local/bin/emacs-lsp-booster'
            target.parent.mkdir(parents=True)
            target.write_bytes(b'old executable')
            identifier = build.installer.install(repo, home, backup=True, plan=build.deployment(repo, home, binary))
            self.assertEqual(target.read_bytes(), binary.read_bytes())
            self.assertEqual(target.stat().st_mode & 0o777, 0o755)
            self.assertEqual(build.deployment(repo, home, binary), [])
            target.chmod(0o644)
            self.assertEqual(len(build.deployment(repo, home, binary)), 1)
            target.chmod(0o755)
            build.installer.restore(home, identifier)
            self.assertEqual(target.read_bytes(), b'old executable')
