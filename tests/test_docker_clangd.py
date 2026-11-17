"""Docker launcher selection and raw language-server handoff checks."""
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest import mock

spec = importlib.util.spec_from_file_location('docker_clangd', Path(__file__).resolve().parents[1] / 'emacstools/my-docker-clangd.py')
launcher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(launcher)
IMAGE = 'registry.example/leo:trixie'


class DockerClangdTests(unittest.TestCase):
    def record(self, identifier='correct', source='/tmp/project', image=IMAGE, running=True):
        return {'Id': identifier, 'Image': image, 'Running': running,
                'Mounts': [{'Type': 'bind', 'Source': source, 'Destination': '/leo'}]}

    def test_matches_image_and_mount_and_running_state(self):
        records = [self.record('wrong-checkout', '/tmp/another'),
                   self.record('wrong-image', image='other'),
                   self.record('stopped', running=False), self.record()]
        self.assertEqual(launcher.select_container(records, IMAGE, Path('/tmp/project'), '/leo'), 'correct')

    def test_missing_and_ambiguous_containers_fail(self):
        for records, message in [([], 'No running container'),
                                 ([self.record(), self.record('duplicate')], '2 matching containers')]:
            with self.assertRaisesRegex(launcher.LauncherError, message):
                launcher.select_container(records, IMAGE, Path('/tmp/project'), '/leo')

    def test_discovery_does_not_read_lsp_input_or_dump_environment(self):
        output = '{"Id":"correct","Image":"' + IMAGE + '","Running":true,"Mounts":[{"Type":"bind","Source":"/tmp/project","Destination":"/leo"}]}\n'
        with mock.patch.object(launcher.subprocess, 'run', side_effect=[
                subprocess.CompletedProcess([], 0, 'correct\n', ''),
                subprocess.CompletedProcess([], 0, output, '')]) as run:
            self.assertEqual(launcher.discover(IMAGE, Path('/tmp/project'), '/leo'), 'correct')
            for call in run.call_args_list:
                self.assertEqual(call.kwargs['stdin'], subprocess.DEVNULL)
            template = run.call_args_list[1].args[0][3]
            self.assertNotIn('Env', template)
            self.assertIn('.Mounts', template)

    def test_permission_errors_are_actionable(self):
        with mock.patch.object(launcher.subprocess, 'run', side_effect=
                               subprocess.CalledProcessError(1, ['docker'], stderr='permission denied')):
            with self.assertRaisesRegex(launcher.LauncherError, 'permission denied'):
                launcher.docker_output(['ps'])

    def test_analysis_database_preserves_source_and_container_paths(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            source = root / 'compile_commands.json'
            entries = [{'directory': '/project', 'file': '/project/a.c',
                        'arguments': ['gcc', '-fstack-usage', '-c', '/project/a.c']},
                       {'directory': '/project', 'file': '/project/b.c',
                        'command': 'gcc -fstack-usage -c /project/b.c'}]
            raw = json.dumps(entries).encode();source.write_bytes(raw)
            directory = launcher.analysis_database(root, '/project', '/project', ['-fstack-usage'], write=False)
            self.assertFalse((root / '.cache').exists())
            self.assertEqual(directory, launcher.analysis_database(root, '/project', '/project', ['-fstack-usage']))
            result = json.loads((root / directory.removeprefix('/project/') / 'compile_commands.json').read_text())
            self.assertEqual(source.read_bytes(), raw)
            for entry in result:
                self.assertNotIn('-fstack-usage', entry['arguments'])
                self.assertEqual(entry['directory'], '/project')
            with self.assertRaises(launcher.LauncherError):
                launcher.analysis_database(root, '/project', '/elsewhere', ['-flag'])
            source.write_text('[]')
            self.assertNotEqual(directory, launcher.analysis_database(root, '/project', '/project', ['-fstack-usage']))

    def test_handoff_uses_selected_id_without_shell_or_tty(self):
        with tempfile.TemporaryDirectory(prefix='project with spaces ') as root:
            args = ['--image', IMAGE, '--host-root', root, '--', '--log=verbose']
            with mock.patch.object(launcher, 'discover', return_value='new-generated-id'), \
                    mock.patch.object(launcher.os, 'execvp') as execute:
                launcher.main(args)
            program, command = execute.call_args.args
            self.assertEqual(program, 'docker')
            self.assertEqual(command[:4], ['docker', 'exec', '-i', 'new-generated-id'])
            self.assertIn(f'--path-mappings={Path(root).resolve()}=/leo', command)
            self.assertEqual(command[-1], '--log=verbose')
            self.assertNotIn('-t', command)
            with mock.patch.object(launcher, 'discover', return_value='new-generated-id'), \
                    mock.patch.object(launcher.os, 'execvp') as execute, \
                    contextlib.redirect_stdout(io.StringIO()):
                launcher.main(['--image', IMAGE, '--host-root', root, '--print-command'])
                execute.assert_not_called()
