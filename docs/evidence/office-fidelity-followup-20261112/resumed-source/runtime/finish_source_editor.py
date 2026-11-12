"""Finish editor acceptance after its shared engine-output prerequisites exist.

Preserves the initial attempt and reuses its successful unchanged-source full
suite. The historical runner assumed independent oracles; the bookmark/control
commands actually verify both engine and editor outputs.
"""
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time

ROOT = Path('/workspace/scratch/07eb2580faa9')
REPO = ROOT / 'quds_office_suite'
OUTPUT = ROOT / 'validation/source-editor'
SOURCE = REPO / 'docs/evidence/office-fidelity-gap-closure-20261112/runtime/run_source_acceptance.py'
EXPECTED = '7641d9cfa167987216134ebfc4772918cc945d97'


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def utc():
    return datetime.now(timezone.utc).isoformat()


def main():
    spec = importlib.util.spec_from_file_location('source_acceptance', SOURCE)
    helper = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = helper
    spec.loader.exec_module(helper)
    original = OUTPUT / 'acceptance.json'
    receipt = json.loads(original.read_text())
    assert receipt['status'] == 'failed' and receipt['commit'] == EXPECTED
    assert receipt['stages'][-1]['name'] == 'bookmark-oracle'
    assert receipt['stages'][-1]['exit_code'] == 1
    tests = next(s for s in receipt['stages'] if s['name'] == 'full-tests')
    assert tests['exit_code'] == 0 and tests['tests']['passed'] == 478
    assert os.environ.get('CI') == 'true'
    failure = (OUTPUT / 'bookmark-oracle.log').read_text()
    assert "Bookmark corpus missing=" in failure and 'extra=[]' in failure
    initial = receipt['source_before']

    def check_source():
        current = helper.source_snapshot(REPO)
        assert current['head'] == initial['head'] == EXPECTED
        assert not current['dirty']
        assert current['snapshot_sha256'] == initial['snapshot_sha256']
        return current

    check_source()
    receipt['original_attempt'] = {
        'receipt': str(original), 'sha256': sha(original),
        'status': receipt['status'], 'error': receipt.pop('error'),
        'explanation': 'The historical runner scheduled editor shared-output oracles before the concurrent engine producer had completed. Engine and editor tests themselves passed. CI schedules the engine first.',
    }
    receipt['resumed_utc'] = utc()
    receipt['status'] = 'waiting_for_engine_exports'
    receipt['stages'][-1]['superseded_after_engine_completion'] = True
    target = OUTPUT / 'acceptance-sequential.json'

    def save():
        target.write_text(json.dumps(receipt, indent=2) + '\n')

    save()
    deadline = time.monotonic() + 1500
    while True:
        check_source()
        engine_path = ROOT / 'validation/source-engine/acceptance.json'
        engine = json.loads(engine_path.read_text())
        assert engine['status'] != 'failed', 'Engine acceptance failed'
        if engine['status'] == 'passed':
            break
        assert time.monotonic() < deadline, 'Engine wait timed out'
        time.sleep(5)
    assert engine['commit'] == EXPECTED
    receipt['engine_prerequisite'] = {'receipt': str(engine_path), 'sha256': sha(engine_path),
                                     'status': engine['status'], 'inventory': engine['inventory']}
    receipt['status'] = 'running'
    save()
    print('Engine prerequisites complete; finishing editor oracles.', flush=True)
    commands = receipt['plan']['commands']['editor']
    start = next(i for i, (name, _) in enumerate(commands) if name == 'bookmark-oracle')
    package = REPO / 'packages/quds_office_editor'
    try:
        for name, command in commands[start:]:
            check_source()
            stage = {'name': name, 'command': command, 'cwd': str(package),
                     'started_utc': utc(), 'phase': 'sequential_completion'}
            receipt['stages'].append(stage)
            log_path = OUTPUT / (name + '-sequential.log')
            started = time.monotonic()
            with log_path.open('w') as log:
                result = subprocess.run(command, cwd=package, stdout=log,
                                        stderr=subprocess.STDOUT, timeout=1200)
            stage.update(exit_code=result.returncode, elapsed_seconds=time.monotonic() - started,
                         log=str(log_path), log_sha256=sha(log_path))
            save()
            assert result.returncode == 0, 'Gate failed: ' + name
            check_source()
            print(name + ' passed', flush=True)
        inventory_path = package / 'build/fidelity-inventory.json'
        inventory = json.loads(inventory_path.read_text())
        expected = receipt['plan']['expected_inventory']['editor']
        assert inventory['ok'] and not inventory['errors']
        assert inventory['verified_files'] == inventory['observed_files'] == inventory['expected_files'] == expected['files']
        assert inventory['manifest_sha256'] == expected['manifest_sha256']
        for row in inventory['files']:
            assert sha(package / 'build' / row['path']) == row['sha256']
        shutil.copyfile(inventory_path, OUTPUT / 'inventory.json')
        receipt['inventory'] = {key: value for key, value in inventory.items() if key != 'files'}
        receipt['artifacts']['inventory.json'] = sha(OUTPUT / 'inventory.json')
        receipt['source_after'] = check_source()
        receipt['status'] = 'passed'
    except Exception as error:
        receipt['status'] = 'failed'
        receipt['error'] = repr(error)
        raise
    finally:
        receipt['finished_utc'] = utc()
        save()
    print(json.dumps({'status': receipt['status'], 'receipt': str(target),
                      'verified_exports': inventory['verified_files']}), flush=True)


if __name__ == '__main__':
    main()
