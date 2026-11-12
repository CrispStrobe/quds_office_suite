"""Derive focused fidelity receipts from the completed native source corpus.

This does not rerender, normalize text, filter pixels, or replace inputs.
Every comparison uses the complete records from the accepted aggregate run.
"""
from collections import Counter
from pathlib import Path
import argparse
import hashlib
import json


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def read(path):
    return json.loads(Path(path).read_text())


def compare(reference, actual):
    keys = ('pages', 'text', 'pixel_sha256')
    matched = {key: reference[key] == actual[key] for key in keys}
    return {'reference': reference['file'], 'actual': actual['file'],
            'matched': matched, 'passed': all(matched.values())}


def main(root):
    summary = read(root / 'acceptance-summary.json')
    assert summary['status'] == 'passed'
    native = read(root / 'render/render-report.json')
    assert native['files'] == 321 and not native['failures']
    records = {item['file']: item for item in native['reports']}
    manifest = read(root / 'input-manifest.json')
    for item in manifest['files']:
        assert sha(item['file']) == item['sha256'] == sha(item['source'])
    prefix = 'quds_office_engine/fidelity-sheet-normal-font/'
    source = records[prefix + 'source.xlsx']
    unchanged = [compare(source, records[prefix + f'unchanged-{cycle}.xlsx'])
                 for cycle in range(1, 4)]
    assert all(item['passed'] for item in unchanged)
    # This fixture also changes the width of a blank column. Compare its full
    # native appearance diagnostically; native repeat-cycle equality remains
    # the required contract for an intentional width edit.
    edited = [compare(source, records[prefix + f'normal-font-{cycle}.xlsx'])
              for cycle in range(1, 4)]
    font_cycles = [item for item in native['cycle_comparisons']
                   if '/fidelity-sheet-normal-font/' in item['case']]
    table_cycles = [item for item in native['cycle_comparisons']
                   if '/fidelity-table-grid/' in item['case']]
    tabs = [item for item in native['cycle_comparisons']
            if item['case'] == 'quds_office_editor/fidelity-custom-tabs/editor-tabs.docx']
    assert len(font_cycles) == 2 and len(table_cycles) == 3 and len(tabs) == 1
    assert all(item['passed'] for item in font_cycles + table_cycles + tabs)
    expected_baselines = {
        'quds_office_engine/fidelity-table-grid/omitted.docx':
            'quds_office_engine/fidelity-table-grid/omitted-source.docx',
        'quds_office_engine/fidelity-table-grid/omitted-edited.docx':
            'quds_office_engine/fidelity-table-grid/omitted-edited-expected.docx',
    }
    for cycle in table_cycles:
        if cycle['case'] in expected_baselines:
            assert cycle['baseline'] == expected_baselines[cycle['case']]
    cache = read(root / 'focused-sheet/classified-native-comparison.json')
    assert cache['status'] == 'passed' and not cache['failures']
    assert len(cache['cache_classifications']) == 42
    result = {
        'status': 'passed', 'source_commit': summary['source_commit'],
        'derived_from_native_report_sha256': sha(root / 'render/render-report.json'),
        'input_manifest_sha256': sha(root / 'input-manifest.json'),
        'summary_script_sha256': sha(__file__),
        'all_original_and_snapshot_hashes_unchanged': True,
        'masking_normalization_or_tolerance': False,
        'normal_font': {
            'unchanged_three_saves_match_native_source': unchanged,
            'blank_column_width_edits_source_comparison': edited,
            'required_repeat_cycle_comparisons': font_cycles,
            'scope': 'One authored non-default Normal-font workbook; unknown fonts retain explicit fallbacks.'},
        'logical_table_grid': {
            'required_repeat_cycle_comparisons': table_cycles,
            'scope': 'Authored merged-cell and omitted-row fixtures; unchanged and whole-story-edited omitted rows use separate native baselines.'},
        'shared_custom_tabs': {
            'required_repeat_cycle_comparisons': tabs,
            'scope': 'Three actual Quds editor exports; full rendering compared without a source equality claim for intentional edits.'},
        'worksheet_formula_caches': {
            'cell_checks': len(cache['cache_classifications']),
            'classifications': dict(Counter(row['classification'] for row in cache['cache_classifications'])),
            'native_expected_matches': sum(row['expected_native_match'] for row in cache['native_comparisons']),
            'source_page1_exact_matches': sum(row['source_page1_exact'] for row in cache['native_comparisons']),
            'report_sha256': sha(root / 'focused-sheet/classified-native-comparison.json'),
            'scope': 'Three renamed saves match the independently authored native result; intentional recalculation and INDIRECT #REF! are distinct from retained unsupported caches.'},
    }
    (root / 'focused-followup-summary.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'status': result['status'], 'font_source_matches': sum(row['passed'] for row in unchanged),
                      'edited_blank_column_source_matches': sum(row['passed'] for row in edited),
                      'table_cycles': len(table_cycles), 'editor_tab_cycles': len(tabs),
                      'cache_cell_checks': len(cache['cache_classifications'])}))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output_directory', type=Path)
    main(parser.parse_args().output_directory.resolve())
