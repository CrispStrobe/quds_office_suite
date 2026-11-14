#!/usr/bin/env python3
"""Bind final host outputs to independent schema and scoped rendering checks.

Run only after the full host gate has completed and restored pubspec.yaml.
Requires the genuine Open XML SDK validator, LibreOfficeKit adapter and Poppler.
The archive retains exact inputs, PDF/PNG renders, raw reports and source hashes.
No source package, test expectation or renderer comparison is modified here.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess
import sys
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


def digest(path):
    value = hashlib.sha256()
    with path.open('rb') as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b''):
            value.update(chunk)
    return value.hexdigest()


def json_file(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8')


def module(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


def capture(command, *, cwd=None, env=None):
    result = subprocess.run(command, cwd=cwd, env=env, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            check=True, timeout=60)
    return result.stdout.strip()


def copy_verified(source, target, expected):
    if digest(source) != expected:
        raise ValueError(f'Input changed before copy: {source}')
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target)
    if digest(target) != expected or digest(source) != expected:
        raise ValueError(f'Input changed during copy: {source}')


def run_logged(command, log, env, commands):
    commands.append(command)
    with log.open('w', encoding='utf-8') as stream:
        result = subprocess.run(command, stdout=stream, stderr=subprocess.STDOUT,
                                env=env, check=False)
    if result.returncode:
        raise ValueError(f'Exit {result.returncode}; inspect {log}')


def check_schema(report_path, inputs):
    report = json.loads(report_path.read_text())
    records = report.get('Reports', [])
    found = {str(Path(record['File']).resolve()): record for record in records}
    if (report.get('Files') != len(inputs) or report.get('Failures') != 0
            or len(records) != len(inputs) or set(found) != set(inputs)):
        raise ValueError(f'Incomplete or failing schema evidence: {report_path}')
    for path, expected in inputs.items():
        record = found[path]
        if (record.get('Sha256') != expected or record.get('Errors') != []
                or 'Exception' in record or digest(Path(path)) != expected):
            raise ValueError(f'Schema receipt does not bind passing bytes: {path}')
    return {'files': len(inputs), 'failures': 0}


def namespace_visible_ink(record, render_root, renderer, environment, commands):
    """The authored blue theme text must paint, beyond the black cell border.

    A narrow source column previously clipped every glyph while retaining text
    extraction and matching reference pixels. Require visible blue glyph ink in
    this exact fixture; the independent baseline still requires exact pixels.
    """
    if record['pages'] != 1:
        raise ValueError('Namespace style witness must remain a single page')
    command = ['pdftoppm', '-r', '72', '-f', '1', '-l', '1',
               str(render_root / record['pdf'])]
    commands.append(command)
    result = subprocess.run(command, env=environment, check=True, capture_output=True, timeout=60)
    width, height, pixels = renderer.ppm_pixels(result.stdout)
    fingerprint = hashlib.sha256(struct.pack('>II', width, height) + pixels).hexdigest()
    if record['pixel_sha256'] != [fingerprint]:
        raise ValueError('Visibility check did not read the exact compared namespace pixels')
    blue_ink = sum(blue >= red + 16 and blue >= green + 8
                   for red, green, blue in zip(pixels[0::3], pixels[1::3], pixels[2::3]))
    if blue_ink < 100:
        raise ValueError(f'Namespace theme text is not visibly painted: {blue_ink} blue pixels')
    return {'file': record['file'], 'blue_ink_pixels': blue_ink,
            'minimum_blue_ink_pixels': 100,
            'blue_ink_definition': 'blue >= red + 16 and blue >= green + 8',
            'pixel_sha256': fingerprint}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--suite', required=True, type=Path)
    parser.add_argument('--app', required=True, type=Path)
    parser.add_argument('--toolchain', required=True, type=Path)
    parser.add_argument('--collection-receipt', required=True, type=Path)
    parser.add_argument('--work', required=True, type=Path,
                        help='New scratch directory, retained if a check fails')
    parser.add_argument('--out', type=Path, default=Path(__file__).resolve().parent)
    args = parser.parse_args()
    suite, app, toolchain, work, out = (
        path.resolve() for path in (args.suite, args.app, args.toolchain, args.work, args.out))
    work.mkdir(parents=True, exist_ok=False)
    out.mkdir(parents=True, exist_ok=True)
    for name in ('external-validation.json', 'external-artifacts.zip'):
        if (out / name).exists():
            raise ValueError(f'Refusing to replace completed evidence: {out / name}')
    inventory_tool = module(app / 'tool/office_host_evidence.py', 'host_inventory')
    sources_tool = module(app / 'tool/collect_office_host_coverage.py', 'host_sources')
    sqlite_tool = module(app / 'tool/with_ci_system_sqlite.py', 'sqlite_wrapper')
    source_snapshot = sources_tool.source_snapshot(app)
    collection = json.loads(args.collection_receipt.read_text())
    collected = collection.get('input_sha256', {})
    if (collection.get('status') != 'complete' or collection.get('returncode') != 0
            or collection.get('input_tree_sha256') != sources_tool.snapshot_digest(collected)):
        raise ValueError('Full host collection receipt is missing, unsuccessful or inconsistent')
    differences = sources_tool._changes(collected, source_snapshot)
    original_pubspec = (app / 'pubspec.yaml').read_bytes()
    hooked_pubspec = original_pubspec.rstrip(b'\r\n') + b'\n' + sqlite_tool.HOOK
    hooked_sha256 = hashlib.sha256(hooked_pubspec).hexdigest()
    if differences not in ([], ['pubspec.yaml']):
        raise ValueError('Host sources differ from successful collection: ' + ', '.join(differences))
    if differences and collected['pubspec.yaml'] != hooked_sha256:
        raise ValueError('Collected pubspec is not the exact documented SQLite wrapper view')
    lcov = args.collection_receipt.parent / 'lcov.info'
    if digest(lcov) != collection.get('coverage_sha256', {}).get('lcov.info'):
        raise ValueError('Coverage bytes no longer match the successful collection receipt')
    host_inventory = inventory_tool.inspect(app)
    if (host_inventory['failures'] or host_inventory['verified_host_outputs'] != 146
            or host_inventory['verified_references'] != 3 or host_inventory['verified'] != 149):
        raise ValueError('Final host inventory must contain 146 outputs and 3 exact references')
    gate_inventory_path = app / 'build/fidelity-host/inventory.json'
    gate_inventory_sha256 = digest(gate_inventory_path)
    if json.loads(gate_inventory_path.read_text()) != host_inventory:
        raise ValueError('Current host output hashes differ from the completed gate inventory')
    suite_evidence = suite / 'docs/evidence/office-recovery-20261114'
    engine_inventory = json.loads((suite_evidence / 'engine-inventory.json').read_text())
    namespace_names = [f'namespace-style-{number}.xlsx' for number in range(1, 4)]
    namespace_names.append('namespace-style-reference.xlsx')
    namespace_records = {entry['path']: entry for entry in engine_inventory['files']
                         if Path(entry['path']).name in namespace_names}
    if len(namespace_records) != 4:
        raise ValueError('Source inventory does not bind all four namespace fixtures')
    inputs, schema_host, schema_namespace, render_inputs = {}, {}, {}, {}
    for record in host_inventory['files']:
        source = app / record['path']
        target = work / 'schema-inputs/host' / record['path']
        copy_verified(source, target, record['sha256'])
        inputs[str(source)] = record['sha256']
        schema_host[str(target)] = record['sha256']
        if source.name.startswith(('native-word-', 'native-sheet-', 'native-slide-')):
            relative = Path(record['path']).relative_to('build')
            render_target = work / 'render-inputs' / relative
            copy_verified(source, render_target, record['sha256'])
            render_inputs[relative.as_posix()] = record['sha256']
    for name, record in namespace_records.items():
        source = suite / 'packages/quds_office_engine/build' / name
        target = work / 'schema-inputs/namespace' / name
        copy_verified(source, target, record['sha256'])
        inputs[str(source)] = record['sha256']
        schema_namespace[str(target)] = record['sha256']
        copy_verified(source, work / 'render-inputs' / name, record['sha256'])
        render_inputs[name] = record['sha256']
    if len(render_inputs) != 16:
        raise ValueError('Rendering scope must contain exactly twelve native and four namespace files')
    json_file(work / 'host-inventory.json', host_inventory)
    copy_verified(gate_inventory_path, work / 'host-gate-inventory.json', gate_inventory_sha256)
    json_file(work / 'restored-source-snapshot.json', source_snapshot)
    shutil.copyfile(args.collection_receipt, work / 'host-collection-receipt.json')
    shutil.copyfile(suite_evidence / 'engine-inventory.json', work / 'engine-inventory.json')
    shutil.copyfile(suite_evidence / 'suite-validation.json', work / 'suite-validation.json')
    shutil.copyfile(app / 'tool/office_host_evidence.json', work / 'host-manifest.json')
    for source, name in (
        (toolchain / 'libreoffice-242/runtime-receipt.json', 'libreoffice-runtime.json'),
        (toolchain / 'clang-root/runtime-receipt.json', 'clang-runtime.json'),
        (toolchain / 'validator/build-receipt.json', 'validator-build.json'),
    ):
        shutil.copyfile(source, work / name)
    environment = dict(os.environ, SAL_USE_VCLPLUGIN='svp',
                       TMPDIR=str(toolchain.parent / 'tmp'),
                       PATH=str(toolchain / 'lok242-bin') + os.pathsep + os.environ['PATH'],
                       DOTNET_ROOT=str(toolchain / 'dotnet'),
                       DOTNET_CLI_HOME=str(toolchain / 'dotnet-user'),
                       DOTNET_SKIP_FIRST_TIME_EXPERIENCE='1', DOTNET_CLI_TELEMETRY_OPTOUT='1')
    commands = []
    validator = toolchain / 'validator/OfficeValidation.dll'
    dotnet = toolchain / 'dotnet/dotnet'
    renderer = suite / 'tool/office-validation/render.py'
    tool_files = {
        'collector': Path(__file__),
        'renderer': renderer,
        'schema_source': suite / 'tool/office-validation/Program.cs',
        'schema_assembly': validator,
        'host_inventory_tool': app / 'tool/office_host_evidence.py',
        'host_source_snapshot_tool': app / 'tool/collect_office_host_coverage.py',
        'sqlite_wrapper': app / 'tool/with_ci_system_sqlite.py',
        'native_fixture_author': app / 'test/fixtures/office_native_workflows/generate.py',
        'native_fixture_manifest': app / 'test/fixtures/office_native_workflows/manifest.json',
        'namespace_fixture_producer': suite / 'packages/quds_office_engine/test/sheet_style_namespace_fidelity_test.dart',
        'libreoffice_launcher': toolchain / 'lok242-bin/libreoffice',
        'libreoffice_kit_adapter': toolchain / 'libreoffice-242/lok_convert',
        'libreoffice_engine': toolchain / 'libreoffice-242/root/opt/libreoffice24.2/program/libmergedlo.so',
    }
    validator_build = json.loads((toolchain / 'validator/build-receipt.json').read_text())
    if (digest(tool_files['schema_source']) != validator_build['source_sha256']
            or digest(validator) != validator_build['assembly_sha256']):
        raise ValueError('Actual validator source/assembly differ from the build receipt')
    for name, expected in validator_build['dependencies_sha256'].items():
        path = toolchain / 'validator' / name
        if digest(path) != expected:
            raise ValueError(f'Actual validator dependency differs from build receipt: {name}')
        tool_files['schema_dependency/' + name] = path
    libreoffice_runtime = json.loads((toolchain / 'libreoffice-242/runtime-receipt.json').read_text())
    for name, expected in libreoffice_runtime['files_sha256'].items():
        path = toolchain / 'libreoffice-242' / name
        if digest(path) != expected:
            raise ValueError(f'Actual LibreOfficeKit adapter differs from runtime receipt: {name}')
        tool_files['libreoffice_kit/' + name] = path
    for name in ('pdfinfo', 'pdftoppm', 'pdftotext'):
        tool_files[name] = Path(shutil.which(name))
    tools_before = {name: digest(path) for name, path in tool_files.items()}
    for name in ('host', 'namespace'):
        command = [str(dotnet), str(validator), str(work / 'schema-inputs' / name),
                   str(work / f'{name}-schema-report.json')]
        run_logged(command, work / f'{name}-schema.log', environment, commands)
    host_schema = check_schema(work / 'host-schema-report.json', schema_host)
    namespace_schema = check_schema(work / 'namespace-schema-report.json', schema_namespace)
    run_logged([sys.executable, str(renderer), str(work / 'render-inputs'), str(work / 'render')],
               work / 'render.log', environment, commands)
    rendered = json.loads((work / 'render/render-report.json').read_text())
    if (rendered.get('failures') or rendered.get('files') != 16
            or rendered.get('rendered_files') != 16 or rendered.get('cycle_groups') != 4
            or rendered.get('baseline_comparisons') != 4
            or rendered.get('native_schema_only_files') != 0):
        raise ValueError('Independent renderer did not pass all sixteen scoped files/four baselines')
    actual_rendered = {entry['file']: entry['input_sha256'] for entry in rendered['reports']}
    if actual_rendered != render_inputs:
        raise ValueError('Render report does not bind the exact selected inputs')
    renderer_tool = module(renderer, 'independent_renderer')
    namespace_visibility = [
        namespace_visible_ink(record, work / 'render', renderer_tool, environment, commands)
        for record in rendered['reports']
        if record['file'].startswith('fidelity-schema/namespace-style-')]
    if len(namespace_visibility) != 4:
        raise ValueError('All four namespace pages require a visible-text witness')
    json_file(work / 'namespace-visibility.json', namespace_visibility)
    if sources_tool.source_snapshot(app) != source_snapshot:
        raise ValueError('Host sources changed during external validation')
    if digest(gate_inventory_path) != gate_inventory_sha256:
        raise ValueError('The completed host gate inventory changed during validation')
    for path, expected in inputs.items():
        if digest(Path(path)) != expected:
            raise ValueError(f'Original output changed during external validation: {path}')
    for name, expected in render_inputs.items():
        if digest(work / 'render-inputs' / name) != expected:
            raise ValueError(f'Render input changed during external validation: {name}')
    for path, expected in {**schema_host, **schema_namespace}.items():
        if digest(Path(path)) != expected:
            raise ValueError(f'Schema input changed during external validation: {path}')
    if {name: digest(path) for name, path in tool_files.items()} != tools_before:
        raise ValueError('Validation tools changed during external validation')
    font_list = capture(['fc-list', '--format=%{file}\t%{family}\t%{style}\n'])
    (work / 'font-inventory.txt').write_text('\n'.join(sorted(font_list.splitlines())) + '\n')
    versions = {name: capture([name, '-v'], env=environment).splitlines()[0]
                for name in ('pdfinfo', 'pdftoppm', 'pdftotext')}
    versions['libreoffice'] = rendered['renderer']
    versions['dotnet'] = capture([str(dotnet), '--version'], env=environment)
    versions['font_resolutions'] = {}
    for name in ('Calibri', 'Cambria', 'Arial', 'Noto Sans', 'Noto Serif',
                 'Liberation Sans', 'Liberation Sans:style=Bold',
                 'Liberation Sans:style=Italic', 'Liberation Sans:style=Bold Italic'):
        family, file = capture(['fc-match', name, '--format=%{family}\t%{file}']).split('\t')
        versions['font_resolutions'][name] = {'family': family, 'file': file,
                                            'sha256': digest(Path(file))}
    pin = json.loads((app / 'tool/office_fidelity_manifest.json').read_text())
    receipt = {
        'schema_version': 1, 'status': 'complete',
        'completed_at': datetime.now(timezone.utc).isoformat(),
        'source': {
            'suite_commit': capture(['git', 'rev-parse', 'HEAD'], cwd=suite),
            'app_commit': capture(['git', 'rev-parse', 'HEAD'], cwd=app),
            'app_pinned_suite_commit': pin['source_commit'],
            'app_pin_manifest_sha256': digest(app / 'tool/office_fidelity_manifest.json'),
            'restored_input_files': len(source_snapshot),
            'restored_input_tree_sha256': sources_tool.snapshot_digest(source_snapshot),
            'collected_input_tree_sha256': collection['input_tree_sha256'],
            'collection_receipt_sha256': digest(args.collection_receipt),
            'completed_gate_inventory_sha256': gate_inventory_sha256,
            'sqlite_test_view': {
                'only_changed_path': differences,
                'original_pubspec_sha256': source_snapshot['pubspec.yaml'],
                'collected_pubspec_sha256': collected['pubspec.yaml'],
                'exact_reconstructed_hooked_pubspec_sha256': hooked_sha256,
                'transformation': "original.rstrip(b'\\r\\n') + b'\\n' + checked-in HOOK",
                'all_other_inputs_equal': True,
            },
        },
        'scope': {
            'host_schema': dict(host_schema, actual_outputs=146, independent_references=3),
            'namespace_schema': dict(namespace_schema, actual_outputs=3, independent_references=1),
            'render': {'files': 16, 'actual_native_host_outputs': 9, 'native_references': 3,
                       'namespace_outputs': 3, 'namespace_reference': 1,
                       'three_save_groups': 4, 'independent_first_save_baselines': 4,
                       'equal_page_text_and_rgb_pixels': True, 'failures': 0},
            'boundary': 'Only these sixteen files are rendered here. The separate source schema receipt covers 350 engine files; this receipt makes no whole-engine or whole-host visual claim.',
        },
        'tools_sha256': tools_before,
        'versions': versions, 'commands': commands,
        'renderer_input_sha256': render_inputs,
        'namespace_visible_text': namespace_visibility,
        'replay_after_archive_extraction': [
            'dotnet OfficeValidation.dll schema-inputs/host host-schema-replayed.json',
            'dotnet OfficeValidation.dll schema-inputs/namespace namespace-schema-replayed.json',
            'SAL_USE_VCLPLUGIN=svp python3 <suite>/tool/office-validation/render.py render-inputs render-replayed',
        ],
    }
    archive_manifest = {path.relative_to(work).as_posix(): {'bytes': path.stat().st_size, 'sha256': digest(path)}
                        for path in sorted(work.rglob('*')) if path.is_file()}
    json_file(work / 'archive-manifest.json', archive_manifest)
    archive = out / 'external-artifacts.zip'
    with ZipFile(archive, 'x', compression=ZIP_DEFLATED, compresslevel=9) as destination:
        for path in sorted(work.rglob('*')):
            if not path.is_file():
                continue
            info = ZipInfo(path.relative_to(work).as_posix(), date_time=(2026, 11, 14, 0, 0, 0))
            info.compress_type = ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            destination.writestr(info, path.read_bytes(), compress_type=ZIP_DEFLATED, compresslevel=9)
    receipt['archive'] = {'file': archive.name, 'bytes': archive.stat().st_size,
                          'sha256': digest(archive), 'manifest_sha256': digest(work / 'archive-manifest.json')}
    for name in ('host-schema-report.json', 'namespace-schema-report.json',
                 'host-inventory.json', 'archive-manifest.json'):
        shutil.copyfile(work / name, out / name)
    shutil.copyfile(work / 'render/render-report.json', out / 'render-report.json')
    receipt['reports_sha256'] = {name: digest(out / name) for name in (
        'host-schema-report.json', 'namespace-schema-report.json', 'host-inventory.json',
        'archive-manifest.json', 'render-report.json')}
    json_file(out / 'external-validation.json', receipt)
    print(json.dumps({'status': 'complete', 'host_schema_files': 149,
                      'namespace_schema_files': 4, 'rendered_files': 16,
                      'three_save_groups': 4, 'independent_baselines': 4,
                      'archive_bytes': archive.stat().st_size, 'out': str(out)}, indent=2))


if __name__ == '__main__':
    main()
