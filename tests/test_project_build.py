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

    def record(self, root, image='image', mount='/project'):
        return {'Id': 'managed', 'Image': image, 'Running': False,
                'Mounts': [{'Type': 'bind', 'Source': str(root), 'Destination': mount}]}

    def test_auto_start_reuses_running_match_without_mutation(self):
        with mock.patch.object(build.docker, 'discover', return_value='existing') as discover, \
                mock.patch.object(build.docker, 'docker_output') as output:
            self.assertEqual(build.ensure_container('image', Path('/tmp/project'), '/project', True), 'existing')
            discover.assert_called_once()
            output.assert_not_called()

    def test_auto_start_creates_once_and_rechecks_image_mount(self):
        root = Path('/tmp/project with spaces')
        with mock.patch.object(build.docker, 'discover', side_effect=[
                build.docker.NoMatchingContainerError('missing'), 'new']) as discover, \
                mock.patch.object(build.docker, 'docker_output', side_effect=['', 'new']) as output, \
                contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(build.ensure_container('image', root, '/project', True), 'new')
            self.assertEqual(discover.call_count, 2)
            command = output.call_args_list[1].args[0]
            self.assertEqual(command[0], 'run')
            self.assertIn('--pull=never', command)
            self.assertIn('--detach', command)
            self.assertIn('type=bind,source=/tmp/project with spaces,target=/project', command)
            self.assertIn(f'{build.os.getuid()}:{build.os.getgid()}', command)
            self.assertIn('HOME=/tmp', command)
            self.assertNotIn('--privileged', command)

    def test_auto_start_restarts_only_matching_stopped_managed_container(self):
        root = Path('/tmp/project')
        with mock.patch.object(build.docker, 'discover', side_effect=[
                build.docker.NoMatchingContainerError('missing'), 'managed']), \
                mock.patch.object(build.docker, 'inspect_records', return_value=[self.record(root)]), \
                mock.patch.object(build.docker, 'docker_output', side_effect=['managed', 'managed']) as output, \
                contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(build.ensure_container('image', root, '/project', True), 'managed')
            self.assertEqual(output.call_args_list[-1].args[0],
                             ['start', build.managed_name('image', root, '/project')])
        with mock.patch.object(build.docker, 'discover', side_effect=build.docker.NoMatchingContainerError('missing')), \
                mock.patch.object(build.docker, 'inspect_records', return_value=[self.record(root, image='other')]), \
                mock.patch.object(build.docker, 'docker_output', return_value='occupied') as output:
            with self.assertRaises(build.docker.LauncherError):
                build.ensure_container('image', root, '/project', True)
            self.assertEqual(output.call_count, 1)  # lookup only; no start or run

    def test_ambiguity_daemon_and_permissions_do_not_trigger_startup(self):
        for message in ('2 matching containers', 'permission denied', 'daemon unavailable'):
            with mock.patch.object(build.docker, 'discover', side_effect=build.docker.LauncherError(message)), \
                    mock.patch.object(build.docker, 'docker_output') as output:
                with self.assertRaisesRegex(build.docker.LauncherError, message):
                    build.ensure_container('image', Path('/tmp/project'), '/project', True)
                output.assert_not_called()

    def test_conflicting_concurrent_start_reuses_winner(self):
        with mock.patch.object(build.docker, 'discover', side_effect=[
                build.docker.NoMatchingContainerError('missing'),
                build.docker.NoMatchingContainerError('still starting'), 'winner']), \
                mock.patch.object(build.docker, 'docker_output', side_effect=[
                    '', build.docker.LauncherError('name already in use')]), \
                contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(build.ensure_container('image', Path('/tmp/project'), '/project', True), 'winner')

    def test_startup_failure_preserves_original_error(self):
        with mock.patch.object(build.time, 'sleep'), \
                mock.patch.object(build.docker, 'discover', side_effect=build.docker.NoMatchingContainerError('missing')), \
                mock.patch.object(build.docker, 'docker_output', side_effect=[
                    '', build.docker.LauncherError('image is not available locally')]), \
                contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaisesRegex(build.docker.LauncherError, 'image is not available locally'):
                build.ensure_container('image', Path('/tmp/project'), '/project', True)

    def test_auto_start_is_disabled_for_print_command(self):
        with tempfile.TemporaryDirectory() as folder:
            args = ['--image', 'image', '--host-root', folder, '--container-root', '/project',
                    '--command', 'make', '--auto-start', '--print-command']
            with mock.patch.object(build, 'ensure_container', return_value='existing') as ensure, \
                    mock.patch.object(build.os, 'execvp') as execute, \
                    contextlib.redirect_stdout(io.StringIO()):
                build.main(args)
                self.assertFalse(ensure.call_args.kwargs['auto_start'])
                execute.assert_not_called()

    def test_managed_names_distinguish_checkout_image_and_mount(self):
        base = build.managed_name('image', Path('/a'), '/project')
        self.assertEqual(base, build.managed_name('image', Path('/a'), '/project'))
        self.assertNotEqual(base, build.managed_name('image', Path('/b'), '/project'))
        self.assertNotEqual(base, build.managed_name('other', Path('/a'), '/project'))
        self.assertNotEqual(base, build.managed_name('image', Path('/a'), '/other'))
