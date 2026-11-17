"""Docker project build command composition and handoff tests (no real builds)."""
import contextlib
import importlib.util
import io
from pathlib import Path
import tempfile
import unittest
from unittest import mock

spec = importlib.util.spec_from_file_location(
    'project_build', Path(__file__).resolve().parents[1] / 'emacstools/my-project-build.py')
build = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build)


class ProjectBuildTests(unittest.TestCase):
    def test_exec_preserves_command_and_directory_without_tty(self):
        script = 'make -j"$(nproc)" && printf "%s" "a;b"'
        command = build.command('selected-id', '/workspace', 'build dir', script)
        self.assertEqual(command, ['docker', 'exec', '--workdir', '/workspace/build dir',
                                   'selected-id', 'sh', '-c', script])
        self.assertNotIn('-t', command)
        self.assertNotIn('-i', command)

    def test_rejects_task_directory_outside_mount(self):
        for directory in ('/tmp', '..', 'build/../../elsewhere'):
            with self.assertRaisesRegex(ValueError, 'inside the project mount'):
                build.command('id', '/workspace', directory, 'make')
        with self.assertRaises(ValueError):
            build.command('id', 'relative', '.', 'make')

    def test_uses_shared_discovery_then_exec_to_preserve_exit_status(self):
        with tempfile.TemporaryDirectory(prefix='project with spaces ') as folder:
            with mock.patch.object(build.docker, 'discover', return_value='matching-id') as discover, \
                    mock.patch.object(build.os, 'execvp') as execute, \
                    contextlib.redirect_stdout(io.StringIO()):
                build.main(['--image', 'registry.example/build:tag', '--host-root', folder,
                            '--container-root', '/workspace', '--command', './build.sh'])
                discover.assert_called_once_with('registry.example/build:tag', Path(folder).resolve(), '/workspace')
                self.assertEqual(execute.call_args.args,
                                 ('docker', ['docker', 'exec', '--workdir', '/workspace',
                                             'matching-id', 'sh', '-c', './build.sh']))

    def test_print_command_does_not_build_and_missing_container_fails(self):
        with tempfile.TemporaryDirectory() as folder:
            args = ['--image', 'image', '--host-root', folder, '--container-root', '/project', '--command', 'make']
            with mock.patch.object(build.docker, 'discover', return_value='id'), \
                    mock.patch.object(build.os, 'execvp') as execute, \
                    contextlib.redirect_stdout(io.StringIO()) as output:
                build.main([*args, '--print-command'])
                execute.assert_not_called()
                self.assertIn('docker exec --workdir /project id sh -c make', output.getvalue())
            with mock.patch.object(build.docker, 'discover', side_effect=build.docker.LauncherError('No running container')):
                with self.assertRaisesRegex(build.docker.LauncherError, 'No running container'):
                    build.main(args)
