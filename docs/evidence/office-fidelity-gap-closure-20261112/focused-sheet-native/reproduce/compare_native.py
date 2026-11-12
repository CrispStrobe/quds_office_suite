"""Strict focused comparison against the independently authored native result.

No pixel masking, text normalization, or tolerance is applied. All rendered
pages of each saved file must match the separate expected-native package.
The original source's first page must also match exactly. Per-cell cache/type
classification is explicit and complements, rather than replaces, full-page
and three-save equality.
"""
from decimal import Decimal, InvalidOperation
import difflib
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
from xml.etree import ElementTree as E
from zipfile import ZipFile

X = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
CATEGORIES = {
    'D1': 'supported_numeric_recalculation',
    'D2': 'supported_numeric_recalculation',
    'D8': 'supported_exact_string_result',
    'D13': 'intended_indirect_reference_error',
    'D14': 'supported_numeric_recalculation',
}


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def cells(path):
    with ZipFile(path) as archive:
        root = E.fromstring(archive.read('xl/worksheets/sheet2.xml'))
    result = {}
    for row in range(1, 15):
        address = f'D{row}'
        cell = root.find(f'.//{X}c[@r="{address}"]')
        value = cell.find(X + 'v')
        result[address] = {'formula': cell.findtext(X + 'f'), 'type': cell.get('t'),
                           'value': value.text if value is not None else None}
    return result


def equal_cache(expected, actual):
    if expected['type'] in (None, 'n'):
        if actual['type'] not in (None, 'n'):
            return False
        try:
            # Numeric spelling such as 42/42.0 is semantically identical.
            # Decimal equality uses no rounding, threshold, or tolerance.
            return Decimal(actual['value']) == Decimal(expected['value'])
        except (InvalidOperation, TypeError):
            return False
    return (actual['type'], actual['value']) == (expected['type'], expected['value'])


def page_text(record):
    pages = record['text'].split('\f')
    assert len(pages) == record['pages'] + 1 and pages[-1] == ''
    return pages[:-1]


def compare(proof, expected_root, renderer_path):
    spec = importlib.util.spec_from_file_location('native_render_oracle', renderer_path)
    render = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(render)
    manifest = json.loads((proof / 'input-manifest.json').read_text())
    inputs = {Path(item['file']).name: Path(item['file']) for item in manifest['files']}
    assert set(inputs) == {'source.xlsx', 'renamed-1.xlsx', 'renamed-2.xlsx', 'renamed-3.xlsx'}
    for item in manifest['files']:
        assert digest(item['file']) == item['sha256']
    schema = json.loads((proof / 'schema-report.json').read_text())
    assert schema['Files'] == 4 and schema['Failures'] == 0
    receipts = {Path(item['File']).resolve(): item for item in schema['Reports']}
    assert set(receipts) == {path.resolve() for path in inputs.values()}
    for path in inputs.values():
        receipt = receipts[path.resolve()]
        assert receipt.get('Errors') == [] and 'Exception' not in receipt
        assert receipt['Sha256'] == digest(path)

    author = json.loads((expected_root / 'renamed-expected.json').read_text())
    expected_file = expected_root / 'renamed-expected.xlsx'
    assert digest(inputs['source.xlsx']) == author['source_sha256']
    assert digest(expected_file) == author['reference_sha256']
    expected_schema = json.loads((expected_root / 'schema-report.json').read_text())
    assert expected_schema['Files'] == 1 and expected_schema['Failures'] == 0
    assert expected_schema['Reports'][0]['Sha256'] == digest(expected_file)
    expected_record = json.loads((expected_root / 'render/render-record.json').read_text())
    assert expected_record['input_sha256'] == digest(expected_file)
    expected = expected_record['record']
    native = json.loads((proof / 'render/render-report.json').read_text())
    assert native['files'] == 4 and native['rendered_files'] == 4
    assert native['native_schema_only_files'] == 0
    records = {Path(item['file']).name: item for item in native['reports']}
    assert set(records) == set(inputs)
    original = records['source.xlsx']
    source_cells, expected_cells = cells(inputs['source.xlsx']), cells(expected_file)
    failures, cell_evidence, native_evidence = [], [], []
    if native['failures']:
        failures.extend(native['failures'])
    for cycle in range(1, 4):
        name = f'renamed-{cycle}.xlsx'
        actual_cells, actual = cells(inputs[name]), records[name]
        for address, wanted in expected_cells.items():
            observed = actual_cells[address]
            entry = {'file': name, 'cell': address, 'source': source_cells[address],
                     'expected': wanted, 'actual': observed,
                     'classification': CATEGORIES.get(address, 'retained_unsupported_cache'),
                     'formula_exact': wanted['formula'] == observed['formula'],
                     'cache_and_type_exact': equal_cache(wanted, observed)}
            entry['passed'] = entry['formula_exact'] and entry['cache_and_type_exact']
            if not entry['passed']:
                failures.append({'file': name, 'cell': address, 'error': 'Unresolved formula/cache/type difference'})
            cell_evidence.append(entry)
        entry = {'file': name, 'expected_native_match': False, 'source_page1_exact': False,
                 'cycle_stable': False, 'source_to_actual_text_diff': ''.join(difflib.unified_diff(
                     original['text'].splitlines(True), actual['text'].splitlines(True),
                     fromfile='source.xlsx', tofile=name))}
        try:
            render.compare_records(expected, actual)
            entry['expected_native_match'] = True
            render.compare_records(records['renamed-1.xlsx'], actual)
            entry['cycle_stable'] = True
            assert original['pixel_sha256'][0] == actual['pixel_sha256'][0]
            assert page_text(original)[0] == page_text(actual)[0]
            entry['source_page1_exact'] = True
            assert 'Data!A1 "quoted"' in actual['text']
        except (render.FidelityError, AssertionError) as error:
            failures.append({'file': name, 'error': 'Unresolved native render difference: ' + str(error)})
        native_evidence.append(entry)
    report = {'status': 'passed' if not failures else 'failed', 'source_equality_claimed': False,
              'expected_native_package': str(expected_file), 'expected_native_sha256': digest(expected_file),
              'expected_native_authoring_report_sha256': digest(expected_root / 'renamed-expected.json'),
              'input_manifest_sha256': digest(proof / 'input-manifest.json'),
              'renderer_sha256': digest(renderer_path),
              'comparison_script_sha256': digest(Path(__file__)),
              'masking_or_tolerance': False, 'cache_classifications': cell_evidence,
              'native_comparisons': native_evidence, 'failures': failures}
    (proof / 'classified-native-comparison.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'status': report['status'], 'cell_checks': len(cell_evidence),
                      'native_checks': len(native_evidence), 'failures': failures}, indent=2))
    return 1 if failures else 0


if __name__ == '__main__':
    raise SystemExit(compare(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])))
