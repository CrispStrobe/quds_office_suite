"""Prepare or run the exact source CI gates against an explicitly frozen commit.

Run only after the parent declares the source frozen. Complete engine acceptance
before starting editor acceptance: editor oracles also validate engine outputs.
Editor mode requires --engine-receipt from that passed engine run at the same
commit and source fingerprint. Separate output directories do not make these
gates independent. This helper does not commit, update goldens, upgrade
dependencies, or collect external render inputs.

Supply --flutter-root explicitly: the current flutter executable is a small
cached-tool wrapper outside the SDK, so its parent directory is not an SDK root.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time

sys.dont_write_bytecode = True
SCOPES = ['packages/quds_office_engine', 'packages/quds_office_editor',
          'tool/office-validation', '.github/workflows/office-fidelity.yml',
          'pubspec.yaml', 'pubspec.lock']


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def git(repo, *args):
    return subprocess.check_output(['git', *args], cwd=repo).decode()


def utc():
    return datetime.now(timezone.utc).isoformat()


def load_inventory(repo):
    path = repo / 'packages/quds_office_engine/tool/fidelity/inventory.py'
    spec = importlib.util.spec_from_file_location('acceptance_inventory', path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def plan(repo):
    inv = load_inventory(repo)
    directory = repo / 'packages/quds_office_engine/tool/fidelity'
    expected = {}
    for kind in ('engine', 'editor'):
        path = directory / ('output_manifest.json' if kind == 'engine' else 'editor_output_manifest.json')
        manifest = inv.load_manifest(path, package='quds_office_' + kind)
        expected[kind] = {'manifest': str(path), 'manifest_sha256': sha(path),
                          'files': len(manifest.paths), 'three_cycle_series': manifest.series_count,
                          'standalone_files': manifest.standalone_count}
    editor_inventory = ['python3', '../quds_office_engine/tool/fidelity/inventory.py']
    editor_options = ['--package', 'quds_office_editor', '--manifest',
                      '../quds_office_engine/tool/fidelity/editor_output_manifest.json',
                      '--package-root', '.']
    commands = {
        'engine': [
            ('analyze', ['dart', 'analyze']),
            ('full-tests', ['dart', 'test', '--coverage=coverage/vm', '--reporter', 'expanded']),
            ('mandatory-fidelity', ['bash', 'tool/fidelity/check.sh']),
            ('coverage-report', ['python3', 'tool/fidelity/coverage_report.py']),
        ],
        'editor': [
            ('analyze', ['flutter', 'analyze', '--no-pub', 'lib']),
            ('inventory-clean', editor_inventory + ['clean'] + editor_options),
            ('full-tests', ['flutter', 'test', '--no-pub', '--reporter', 'expanded']),
            ('corpus-oracle', ['python3', '../quds_office_engine/tool/fidelity/corpus.py', 'verify', 'build/fidelity']),
            ('bookmark-oracle', ['python3', '../quds_office_engine/tool/fidelity/bookmarks_oracle.py', '--editor-dir', 'build/fidelity-bookmarks-legacy']),
            ('control-oracle', ['python3', '../quds_office_engine/tool/fidelity/content_controls_oracle.py', '--editor-dir', 'build/fidelity-content-controls-legacy']),
            ('inventory-verify', editor_inventory + ['verify'] + editor_options),
        ],
    }
    return {'created_utc': utc(), 'current_head': git(repo, 'rev-parse', 'HEAD').strip(),
            'expected_inventory': expected, 'expected_source_aggregate': sum(item['files'] for item in expected.values()),
            'commands': commands, 'required_flutter': '3.44.0',
            'execution_order': ['engine', 'editor'],
            'editor_prerequisite': 'A passed --engine-receipt at the same frozen commit and source fingerprint is required before editor acceptance; editor oracles also read engine outputs.',
            'fresh_engine_coverage': 'Existing coverage/vm moves outside the checkout before the full test run.',
            'goldens': 'No update flag; every tracked source/golden hash must remain unchanged.'}


def source_snapshot(repo):
    names = git(repo, 'ls-files', '-z', '--', *SCOPES).split('\0')
    hashes = {name: sha(repo / name) for name in names if name and (repo / name).is_file()}
    dirty = git(repo, 'status', '--porcelain', '--untracked-files=all', '--', *SCOPES)
    return {'head': git(repo, 'rev-parse', 'HEAD').strip(), 'dirty': dirty,
            'files_sha256': hashes,
            'snapshot_sha256': hashlib.sha256(json.dumps(hashes, sort_keys=True).encode()).hexdigest()}


def engine_prerequisite(path, initial, expected_commit, engine_commands):
    if path is None:
        raise ValueError('Editor acceptance requires --engine-receipt from a completed, passed engine acceptance run')
    path = path.resolve()
    raw = path.read_bytes()
    receipt = json.loads(raw)
    if receipt.get('mode') != 'engine' or receipt.get('status') != 'passed':
        raise ValueError('Editor prerequisite must be a passed engine acceptance receipt')
    if receipt.get('commit') != expected_commit:
        raise ValueError('Engine prerequisite commit does not match the frozen editor commit')
    for name in ('source_before', 'source_after'):
        snapshot = receipt.get(name, {})
        if (snapshot.get('head') != initial['head'] or snapshot.get('dirty') != ''
                or snapshot.get('snapshot_sha256') != initial['snapshot_sha256']):
            raise ValueError('Engine prerequisite source fingerprint does not match the frozen editor source: ' + name)
    stages = receipt.get('stages', [])
    if ([stage.get('name') for stage in stages] != [name for name, _ in engine_commands]
            or any(stage.get('exit_code') != 0 for stage in stages)
            or not receipt.get('finished_utc')):
        raise ValueError('Engine prerequisite does not contain all completed engine acceptance stages')
    return {'path': str(path), 'sha256': hashlib.sha256(raw).hexdigest(),
            'commit': expected_commit, 'source_snapshot_sha256': initial['snapshot_sha256'],
            'finished_utc': receipt['finished_utc']}


def test_counts(path):
    text = re.sub(r'\x1b\[[0-?]*[ -/]*[@-~]', '', path.read_text(errors='replace')).replace('\r', '\n')
    lines = text.splitlines()
    success = [line for line in lines if 'All tests passed!' in line]
    result = {'success_marker': success[-1] if success else None}
    if success:
        result['passed'] = int(re.search(r'\+(\d+)', success[-1])[1])
        skipped = re.search(r'~(\d+)', success[-1])
        result['skipped'] = int(skipped[1]) if skipped else 0
    controls = re.findall(r'^Ran (\d+) tests? in ', text, re.MULTILINE)
    if controls:
        result['python_controls'] = int(controls[-1])
    result['skip_diagnostics'] = []
    previous = 0
    for index, line in enumerate(lines):
        status = re.match(r'^\d+:\d+(?::\d+)? \+\d+\s+~(\d+)', line)
        if status and int(status[1]) > previous:
            result['skip_diagnostics'].append('\n'.join(lines[max(0, index - 2):index + 1]))
            previous = int(status[1])
    return result


def run(args):
    repo, output = args.repo.resolve(), args.output.resolve()
    flutter_root = args.flutter_root.resolve()
    planned = plan(repo)
    planned['flutter_root'] = str(flutter_root)
    if args.mode == 'plan':
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(planned, indent=2) + '\n')
        print(json.dumps(planned, indent=2))
        return 0
    if not args.expected_commit or not re.fullmatch('[0-9a-f]{40}', args.expected_commit):
        raise ValueError('A literal frozen 40-character --expected-commit is required')
    initial = source_snapshot(repo)
    if initial['head'] != args.expected_commit or initial['dirty']:
        raise ValueError('Source is not clean at the explicitly frozen commit: ' + initial['dirty'])
    prerequisite = None
    if args.mode == 'editor':
        prerequisite = engine_prerequisite(args.engine_receipt, initial, args.expected_commit,
                                          planned['commands']['engine'])
    if os.environ.get('CI') != 'true':
        raise ValueError('Source runtime must set CI=true; source runtime/env-source.sh first')
    runtime_metadata = flutter_root / 'bin/cache/flutter.version.json'
    if not runtime_metadata.is_file():
        raise ValueError('Explicit Flutter root has no cached version metadata: ' + str(flutter_root))
    pinned_runtime = json.loads(runtime_metadata.read_text())
    if pinned_runtime['frameworkVersion'] != '3.44.0':
        raise ValueError('Explicit Flutter root must be pinned Flutter 3.44.0')
    if args.mode == 'engine':
        # Avoid Flutter's shell wrapper/stamp updates. Gate-script child
        # commands inherit this direct cached Dart SDK path.
        dart_sdk = flutter_root / 'bin/cache/dart-sdk/bin'
        if not (dart_sdk / 'dart').is_file():
            raise ValueError('Pinned Flutter cached Dart SDK is unavailable')
        os.environ['PATH'] = str(dart_sdk) + os.pathsep + os.environ['PATH']
        runtime = dict(pinned_runtime)
        runtime['direct_dart_version'] = subprocess.check_output(
            ['dart', '--version'], stderr=subprocess.STDOUT, text=True).strip()
        runtime['direct_dart_path'] = str(dart_sdk / 'dart')
    else:
        runtime = json.loads(subprocess.check_output(['flutter', '--version', '--machine'], text=True))
        if runtime.get('frameworkRevision') != pinned_runtime.get('frameworkRevision'):
            raise ValueError('Flutter wrapper does not match the explicit pinned SDK revision')
    if runtime['frameworkVersion'] != '3.44.0':
        raise ValueError('Expected pinned Flutter 3.44.0, got ' + runtime['frameworkVersion'])
    output.mkdir(parents=True, exist_ok=False)
    package = repo / ('packages/quds_office_' + args.mode)
    receipt = {'status': 'running', 'mode': args.mode, 'started_utc': utc(),
               'commit': args.expected_commit, 'runtime': runtime,
               'flutter_root': str(flutter_root), 'runtime_metadata_sha256': sha(runtime_metadata),
               'runtime_paths': {name: shutil.which(name) for name in ('dart', 'flutter', 'python3')},
               'plan': planned, 'source_before': initial, 'stages': [], 'artifacts': {}}
    if prerequisite is not None:
        receipt['engine_prerequisite'] = prerequisite
    receipt_path = output / 'acceptance.json'

    def save():
        receipt_path.write_text(json.dumps(receipt, indent=2) + '\n')

    def check_source():
        current = source_snapshot(repo)
        if (current['head'] != initial['head'] or current['dirty']
                or current['snapshot_sha256'] != initial['snapshot_sha256']):
            raise RuntimeError('Frozen source changed while acceptance was running')
        return current

    save()
    try:
        if args.mode == 'engine':
            coverage = package / 'coverage/vm'
            if coverage.exists():
                shutil.move(str(coverage), output / 'previous-coverage-vm')
            assert not coverage.exists()
            receipt['coverage_started_empty'] = True
        for name, command in planned['commands'][args.mode]:
            check_source()
            stage = {'name': name, 'command': command, 'cwd': str(package), 'started_utc': utc()}
            receipt['stages'].append(stage)
            save()
            print(json.dumps({'mode': args.mode, 'stage': name, 'status': 'running'}), flush=True)
            started = time.monotonic()
            log_path = output / (name + '.log')
            try:
                with log_path.open('w') as log:
                    completed = subprocess.run(command, cwd=package, stdout=log, stderr=subprocess.STDOUT,
                                               timeout=args.stage_timeout)
                stage['exit_code'] = completed.returncode
            finally:
                stage['elapsed_seconds'] = time.monotonic() - started
                if log_path.exists():
                    stage['log'] = str(log_path)
                    stage['log_sha256'] = sha(log_path)
                save()
            if completed.returncode != 0:
                raise RuntimeError('Gate failed: ' + name)
            if name in ('full-tests', 'mandatory-fidelity'):
                stage['tests'] = test_counts(log_path)
                if not stage['tests']['success_marker']:
                    raise RuntimeError('Missing test completion marker: ' + name)
            check_source()
            save()
            print(json.dumps({'mode': args.mode, 'stage': name, 'status': 'passed',
                              'elapsed_seconds': stage['elapsed_seconds']}), flush=True)
        inventory_path = package / 'build/fidelity-inventory.json'
        inventory = json.loads(inventory_path.read_text())
        expected = planned['expected_inventory'][args.mode]
        if (not inventory['ok'] or inventory['errors']
                or inventory['verified_files'] != expected['files']
                or inventory['manifest_sha256'] != expected['manifest_sha256']):
            raise RuntimeError('Final inventory does not match the frozen authored manifest')
        for item in inventory['files']:
            if sha(package / 'build' / item['path']) != item['sha256']:
                raise RuntimeError('Export changed after inventory verification: ' + item['path'])
        shutil.copyfile(inventory_path, output / 'inventory.json')
        receipt['inventory'] = {key: value for key, value in inventory.items() if key != 'files'}
        receipt['artifacts']['inventory.json'] = sha(output / 'inventory.json')
        if args.mode == 'engine':
            coverage_path = package / 'build/fidelity/coverage-gaps.json'
            coverage = json.loads(coverage_path.read_text())
            prefix = 'packages/quds_office_engine/'
            hashes = {name[len(prefix):]: value for name, value in initial['files_sha256'].items()
                      if name.startswith(prefix + 'lib/') and name.endswith('.dart')}
            fingerprint = hashlib.sha256(json.dumps(hashes, sort_keys=True).encode()).hexdigest()
            if coverage['source_tree_sha256'] != fingerprint or coverage['source_git_dirty']:
                raise RuntimeError('Coverage is not bound to the frozen engine source')
            shutil.copyfile(coverage_path, output / 'coverage-gaps.json')
            receipt['artifacts']['coverage-gaps.json'] = sha(output / 'coverage-gaps.json')
            receipt['coverage'] = {key: coverage[key] for key in
                                   ('covered_lines', 'instrumented_lines', 'source_tree_sha256', 'components')}
            receipt['coverage']['fresh_vm_files'] = len(list((package / 'coverage/vm').rglob('*.json')))
            receipt['operations'] = json.loads((package / 'build/fidelity-scripted/operation-coverage.json').read_text())['operations']
        receipt['source_after'] = check_source()
        receipt['status'] = 'passed'
    except Exception as error:
        receipt['status'] = 'failed'
        receipt['error'] = repr(error)
        raise
    finally:
        receipt['finished_utc'] = utc()
        save()
    print(json.dumps({'mode': args.mode, 'status': receipt['status'], 'receipt': str(receipt_path),
                      'verified_exports': receipt['inventory']['verified_files']}), flush=True)
    return 0


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=['plan', 'engine', 'editor'])
    parser.add_argument('--repo', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--flutter-root', type=Path, required=True,
                        help='Explicit pinned Flutter SDK root; do not infer it from wrapper paths')
    parser.add_argument('--expected-commit')
    parser.add_argument('--engine-receipt', type=Path,
                        help='Required for editor mode: passed engine acceptance.json from the same frozen commit and source fingerprint')
    parser.add_argument('--stage-timeout', type=int, default=1200)
    raise SystemExit(run(parser.parse_args()))
