"""Collect exact accepted source bytes, run SDK/native gates, classify Sheet.

Requires completed engine/editor receipts from run_source_acceptance.py. All
new evidence stays outside the repository. Full-corpus render records supply
the final four-file Sheet comparison without rerendering or masking any pages.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def read(path):
    return json.loads(Path(path).read_text())


def write(path, value):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text(json.dumps(value, indent=2) + '\n')


def main(args):
    repo, runtime, output = args.repo.resolve(), args.runtime.resolve(), args.output.resolve()
    if output == repo or repo in output.parents:
        raise ValueError('External evidence must be outside the checkout')
    receipts = {kind: read(folder / 'acceptance.json')
                for kind, folder in [('engine', args.engine), ('editor', args.editor)]}
    if any(item['status'] != 'passed' for item in receipts.values()):
        raise ValueError('Both source gates must pass before external collection')
    if (receipts['engine']['commit'] != receipts['editor']['commit']
            or receipts['engine']['source_before']['snapshot_sha256'] !=
            receipts['editor']['source_before']['snapshot_sha256']):
        raise ValueError('Source gates do not describe the same frozen revision')
    commit = receipts['engine']['commit']
    build = read(runtime / 'validator/build-receipt.json')
    if sha(repo / 'tool/office-validation/Program.cs') != build['source_sha256']:
        raise ValueError('Validator source differs from the pinned compiled SDK receipt')
    if sha(runtime / 'validator/OfficeValidation.dll') != build['assembly_sha256']:
        raise ValueError('Compiled validator changed')
    runtime_provenance = read(runtime / 'renderer-provenance.json')
    for item in runtime_provenance['adapter']['artifacts']:
        if sha(item['path']) != item['sha256']:
            raise ValueError('Frozen native adapter/runtime changed: ' + item['path'])
    if Path(shutil.which('libreoffice') or '').resolve() != (runtime / 'lok242-bin/libreoffice').resolve():
        raise ValueError('Source runtime/env-render-lok242.sh before running native acceptance')
    output.mkdir(parents=True, exist_ok=False)
    files = []
    for kind, folder in [('engine', args.engine), ('editor', args.editor)]:
        inventory_path = folder / 'inventory.json'
        if sha(inventory_path) != receipts[kind]['artifacts']['inventory.json']:
            raise ValueError('Source inventory receipt changed')
        inventory = read(inventory_path)
        package = 'quds_office_' + kind
        for item in inventory['files']:
            relative = Path(item['path'])
            if relative.is_absolute() or '..' in relative.parts:
                raise ValueError('Unsafe inventory path')
            source = repo / 'packages' / package / 'build' / relative
            if sha(source) != item['sha256']:
                raise ValueError('Export changed after its producer gate: ' + str(source))
            target = output / 'input' / package / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
            if sha(target) != item['sha256']:
                raise ValueError('Snapshot copy differs')
            files.append({'source': str(source), 'file': str(target), 'sha256': item['sha256'],
                          'package': package, 'path': relative.as_posix(), 'producer': item['producer']})
        shutil.copyfile(inventory_path, output / (kind + '-inventory.json'))
        shutil.copyfile(folder / 'acceptance.json', output / (kind + '-acceptance.json'))
    if len(files) != args.expected_count:
        raise ValueError(f'Expected {args.expected_count} source packages, got {len(files)}')
    render_source = repo / 'tool/office-validation/render.py'
    manifest = {'source_commit': commit, 'count': len(files), 'files': files,
                'engine_source_tree_sha256': receipts['engine']['coverage']['source_tree_sha256'],
                'renderer_source_sha256': sha(render_source), 'validator_source_sha256': build['source_sha256'],
                'producer_receipts_sha256': {kind: sha(output / (kind + '-acceptance.json'))
                                             for kind in receipts}}
    write(output / 'input-manifest.json', manifest)
    report = {'status': 'running', 'source_commit': commit,
              'started_utc': datetime.now(timezone.utc).isoformat(), 'commands': []}

    def save():
        write(output / 'acceptance-summary.json', report)

    def command(name, values):
        entry = {'name': name, 'command': values, 'cwd': str(repo)}
        report['commands'].append(entry)
        save()
        print(json.dumps({'stage': name, 'status': 'running'}), flush=True)
        start = time.monotonic()
        log_path = output / (name + '.log')
        with log_path.open('w') as log:
            result = subprocess.run(values, cwd=repo, stdout=log, stderr=subprocess.STDOUT, timeout=1800)
        entry.update(exit_code=result.returncode, elapsed_seconds=time.monotonic() - start,
                     log=str(log_path), log_sha256=sha(log_path))
        save()
        if result.returncode:
            raise RuntimeError('External gate failed: ' + name)
        print(json.dumps({'stage': name, 'status': 'passed', 'elapsed_seconds': entry['elapsed_seconds']}), flush=True)

    save()
    try:
        command('sdk-selftest', ['dotnet', str(runtime / 'validator/OfficeValidation.dll'), '--self-test'])
        command('schema', ['dotnet', str(runtime / 'validator/OfficeValidation.dll'),
                           str(output / 'input'), str(output / 'schema-report.json')])
        command('renderer-controls', ['python3', '-m', 'unittest', 'discover', '-s',
                                      'tool/office-validation', '-p', 'test_*.py', '-v'])
        command('native-render', ['python3', str(render_source), str(output / 'input'),
                                  str(output / 'render'), '--schema-report', str(output / 'schema-report.json')])
        schema, native = read(output / 'schema-report.json'), read(output / 'render/render-report.json')
        if schema['Files'] != len(files) or schema['Failures'] or native['files'] != len(files) or native['failures']:
            raise RuntimeError('External reports contain failures or omit inputs')
        sdk = {Path(item['File']).resolve(): item for item in schema['Reports']}
        if set(sdk) != {Path(item['file']).resolve() for item in files}:
            raise RuntimeError('SDK receipt path set differs from frozen snapshot')
        for item in files:
            receipt = sdk[Path(item['file']).resolve()]
            if (sha(item['file']) != item['sha256'] or receipt.get('Errors') != []
                    or 'Exception' in receipt or receipt.get('Sha256') != item['sha256']):
                raise RuntimeError('Missing/stale SDK byte receipt')
        if sha(render_source) != manifest['renderer_source_sha256']:
            raise RuntimeError('Renderer source changed during acceptance')
        expected_names = {Path(item['file']).relative_to(output / 'input').as_posix() for item in files}
        rendered_names = {item['file'] for item in native['reports']}
        qualified_names = {item['file'] for item in native['native_schema_only']}
        if rendered_names & qualified_names or rendered_names | qualified_names != expected_names:
            raise RuntimeError('Native report does not account for every exact input')

        # Derive a transparent four-file receipt from the completed aggregate.
        # Full records and SDK entries are copied unchanged; no rerender, text
        # normalization, pixel filtering, or artifact substitution occurs.
        focused = output / 'focused-sheet'
        selected = [item for item in files if item['package'] == 'quds_office_engine'
                    and Path(item['path']).parent.as_posix() == 'fidelity-sheet-rename']
        if {Path(item['file']).name for item in selected} != {'source.xlsx', 'renamed-1.xlsx', 'renamed-2.xlsx', 'renamed-3.xlsx'}:
            raise RuntimeError('Final source lacks the exact Sheet rename corpus')
        names = {Path(item['file']).relative_to(output / 'input').as_posix() for item in selected}
        selected_records = [item for item in native['reports'] if item['file'] in names]
        if len(selected_records) != 4:
            raise RuntimeError('Final Sheet files did not all render successfully')
        write(focused / 'input-manifest.json', {'source_commit': commit, 'files': selected, 'count': 4,
                                               'derived_from': str(output / 'input-manifest.json'),
                                               'derived_from_sha256': sha(output / 'input-manifest.json')})
        write(focused / 'schema-report.json', {'Files': 4, 'Failures': 0,
                                              'Reports': [sdk[Path(item['file']).resolve()] for item in selected],
                                              'derived_from': str(output / 'schema-report.json'),
                                              'derived_from_sha256': sha(output / 'schema-report.json')})
        write(focused / 'render/render-report.json', {'files': 4, 'rendered_files': 4,
                                                     'native_schema_only_files': 0, 'reports': selected_records,
                                                     'failures': [], 'derived_from': str(output / 'render/render-report.json'),
                                                     'derived_from_sha256': sha(output / 'render/render-report.json'),
                                                     'artifact_root': str(output / 'render')})
        comparator = repo / 'docs/evidence/office-fidelity-gap-closure-20261112/focused-sheet-native/reproduce/compare_native.py'
        command('sheet-classification', ['python3', str(comparator), str(focused),
                                        str(args.expected_sheet.resolve()), str(render_source)])
        classified = read(focused / 'classified-native-comparison.json')
        if classified['status'] != 'passed' or classified['failures']:
            raise RuntimeError('Final Sheet native expectation did not match')
        provenance = {key: runtime_provenance[key] for key in
                      ('format_version', 'renderer', 'adapter', 'supporting_tools')}
        provenance.update(source_commit=commit, renderer_source_sha256=manifest['renderer_source_sha256'],
                          input_manifest_sha256=sha(output / 'input-manifest.json'), commands=report['commands'])
        write(output / 'renderer-provenance.json', provenance)
        write(output / 'schema-validator-provenance.json', {'build_receipt': build,
                                                           'current_source_sha256': sha(repo / 'tool/office-validation/Program.cs'),
                                                           'current_assembly_sha256': sha(runtime / 'validator/OfficeValidation.dll')})
        report.update(status='passed', inputs=len(files), schema_failures=0,
                      rendered_files=native['rendered_files'], rendered_pages=sum(item['pages'] for item in native['reports']),
                      native_schema_only_files=native['native_schema_only_files'], cycle_groups=native['cycle_groups'],
                      baseline_comparisons=native['baseline_comparisons'], page_order_comparisons=native['page_order_comparisons'],
                      sheet_expected_native_matches=3, sheet_classified_cell_checks=len(classified['cache_classifications']),
                      failures=[], report_sha256={str(path.relative_to(output)): sha(path) for path in
                       [output / 'input-manifest.json', output / 'schema-report.json', output / 'render/render-report.json',
                        output / 'renderer-provenance.json', output / 'schema-validator-provenance.json',
                        focused / 'classified-native-comparison.json']})
    except Exception as error:
        report.update(status='failed', error=repr(error))
        raise
    finally:
        report['finished_utc'] = datetime.now(timezone.utc).isoformat()
        save()
    print(json.dumps({key: report[key] for key in ('status', 'inputs', 'rendered_files', 'rendered_pages',
                                                 'native_schema_only_files', 'cycle_groups', 'sheet_classified_cell_checks')}), flush=True)
    return 0


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, required=True)
    parser.add_argument('--runtime', type=Path, required=True)
    parser.add_argument('--engine', type=Path, required=True)
    parser.add_argument('--editor', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--expected-sheet', type=Path, required=True)
    parser.add_argument('--expected-count', type=int, default=299)
    raise SystemExit(main(parser.parse_args()))
