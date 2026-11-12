"""Snapshot bookmark-copy outputs, validate schema and compare native rendering."""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import sys


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def write(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, required=True)
    parser.add_argument('--runtime', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    repo, runtime, output = (path.resolve() for path in (args.repo, args.runtime, args.output))
    output.mkdir(parents=True, exist_ok=False)
    build = json.loads((runtime / 'validator/build-receipt.json').read_text())
    assert digest(repo / 'tool/office-validation/Program.cs') == build['source_sha256']
    assert digest(runtime / 'validator/OfficeValidation.dll') == build['assembly_sha256']
    sys.path.insert(0, str(repo / 'packages/quds_office_engine/tool/fidelity'))
    import bookmark_copy_oracle as oracle
    manifest = []
    for kind in ('engine', 'editor'):
        source_root = repo / f'packages/quds_office_{kind}/build/fidelity-bookmark-copy'
        receipt = oracle.verify(source_root, editor=kind == 'editor')
        write(output / f'{kind}-oracle.json', receipt)
        for item in receipt['files']:
            source = source_root / item['name']
            target = output / f'input/{kind}/fidelity-bookmark-copy' / item['name']
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
            assert digest(target) == item['sha256']
            manifest.append({'source': str(source), 'file': str(target), 'sha256': item['sha256']})
    expected = output / 'input/engine/fidelity-bookmark-copy/copied-expected.docx'
    assert digest(expected) == digest(repo / 'packages/quds_office_engine/test/fixtures/fidelity/bookmark_copy_expected.docx')
    write(output / 'input-manifest.json', {'count': len(manifest), 'files': manifest})
    commands = [
        ('schema', ['dotnet', str(runtime / 'validator/OfficeValidation.dll'),
                    str(output / 'input'), str(output / 'schema-report.json')]),
        ('render', ['python3', str(repo / 'tool/office-validation/render.py'),
                    str(output / 'input'), str(output / 'render'),
                    '--schema-report', str(output / 'schema-report.json')]),
    ]
    receipts = []
    for name, command in commands:
        with (output / (name + '.log')).open('w') as log:
            result = subprocess.run(command, cwd=repo, stdout=log, stderr=subprocess.STDOUT,
                                    timeout=600)
        receipts.append({'name': name, 'command': command, 'exit_code': result.returncode,
                         'log_sha256': digest(output / (name + '.log'))})
        write(output / 'commands.json', receipts)
        if result.returncode:
            raise RuntimeError(f'{name} failed; inspect preserved logs')
    schema = json.loads((output / 'schema-report.json').read_text())
    rendered = json.loads((output / 'render/render-report.json').read_text())
    assert schema['Files'] == 9 and schema['Failures'] == 0
    assert rendered['files'] == rendered['rendered_files'] == 9 and not rendered['failures']
    records = {record['file']: record for record in rendered['reports']}
    spec = importlib.util.spec_from_file_location('bookmark_native_renderer', repo / 'tool/office-validation/render.py')
    render_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(render_module)
    expected_name = 'engine/fidelity-bookmark-copy/copied-expected.docx'
    expected_record = records[expected_name]
    comparisons = []
    for name, record in records.items():
        if name == expected_name or name.endswith('/source.docx'):
            continue
        render_module.compare_records(expected_record, record, root=output / 'input')
        comparisons.append({'file': name, 'baseline': expected_name,
                            'status': 'exact_native_match'})
    for item in manifest:
        assert digest(item['file']) == item['sha256']
        if item['source']:
            assert digest(item['source']) == item['sha256']
    result = {'status': 'passed', 'source_commit': subprocess.check_output(
        ['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip(),
        'producer_files': 9, 'source_export_files': 7, 'independent_native_reference_files': 2,
        'schema_files': schema['Files'], 'schema_failures': schema['Failures'],
        'rendered_files': rendered['rendered_files'],
        'native_pages': sum(record['pages'] for record in records.values()),
        'native_schema_only_files': rendered['native_schema_only_files'],
        'cycle_groups': rendered['cycle_groups'], 'comparisons': comparisons,
        'renderer_source_sha256': digest(repo / 'tool/office-validation/render.py'),
        'validator_source_sha256': build['source_sha256'],
        'validator_build_receipt_sha256': digest(runtime / 'validator/build-receipt.json'),
        'renderer_provenance_sha256': digest(runtime / 'renderer-provenance.json'),
        'producer_and_snapshot_hashes_unchanged': True}
    write(output / 'acceptance-summary.json', result)
    print(json.dumps({key: value for key, value in result.items() if key != 'comparisons'}, indent=2))


if __name__ == '__main__':
    main()
