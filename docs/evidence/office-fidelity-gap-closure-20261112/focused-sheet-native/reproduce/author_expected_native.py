"""Author the explicitly expected native rename, independently of Quds.

This diagnostic reference starts with the frozen, independent source package.
Only declared sheet-reference owners/name and five explicitly approved formula
cache results change. Every other package part stays byte-for-byte identical.
It is not a replacement source fixture or a product renderer baseline mapping.
"""
from pathlib import Path
import hashlib
import json
import sys
from xml.etree import ElementTree as E
from zipfile import ZipFile

X = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
C = '{http://schemas.openxmlformats.org/drawingml/2006/chart}'
NAME = "O'Brien 2026"
FORMULAS = {
    'D1': "'O''Brien 2026'!$B$2",
    'D2': "'O''Brien 2026'!$B$3",
    'D3': "SUM('O''Brien 2026:Summary'!B2)",
    'D4': "SUM('O''Brien 2026:Summary'!B2)",
    'D5': "SUM('O''Brien 2026:Summary'!B2)",
    'D6': '[1]Data!B2',
    'D7': "'[Remote.xlsx]Data'!B2",
    'D8': 'IF(\'O\'\'Brien 2026\'!B2>0,"Data!A1 ""quoted""","\'Data\'!B2")',
    'D9': 'RenameTable[Data!A1]',
    'D10': "'O''Brien 2026'!LocalRange",
    'D11': "SUM('O''Brien 2026'!$A:$B)",
    'D12': "SUM('O''Brien 2026'!1:3)",
    'D13': 'INDIRECT("Data!B2")',
    'D14': "'O''Brien 2026'!b2+Summary!B2",
}
NAMES = {
    ('NativeRange', None): "'O''Brien 2026'!$A$1:$B$3",
    ('Computed', None): "SUM('O''Brien 2026'!$B$2,Summary!$B$2)",
    ('LocalRange', '0'): "'O''Brien 2026'!$B$2",
    ('LocalRange', '1'): 'Summary!$B$2',
    ('ThreeD', None): "SUM('O''Brien 2026:Summary'!$B$2)",
    ('Literal', None): '"Data!A1"',
    ('_xlnm.Print_Area', '0'): "'O''Brien 2026'!$A$1:$C$5",
    ('_xlnm.Print_Titles', '0'): "'O''Brien 2026'!$1:$1",
}
EXPECTED_CACHES = {
    'D1': (None, '2'),
    'D2': (None, '5'),
    'D8': ('str', 'Data!A1 "quoted"'),
    'D13': ('e', '#REF!'),
    'D14': (None, '4'),
}


def build(source, destination):
    with ZipFile(source) as archive:
        entries = archive.infolist()
        assert len(entries) == len(set(archive.namelist()))
        parts = {entry.filename: archive.read(entry) for entry in entries}
    original = dict(parts)
    E.register_namespace('', X[1:-1])
    E.register_namespace('r', 'http://schemas.openxmlformats.org/officeDocument/2006/relationships')
    E.register_namespace('c', C[1:-1])
    E.register_namespace('a', 'http://schemas.openxmlformats.org/drawingml/2006/main')

    workbook = E.fromstring(parts['xl/workbook.xml'])
    sheets = workbook.find(X + 'sheets')
    assert [sheet.get('name') for sheet in sheets] == ['Data', 'Summary']
    sheets[0].set('name', NAME)
    names = workbook.find(X + 'definedNames')
    assert {(node.get('name'), node.get('localSheetId')) for node in names} == set(NAMES)
    for node in names:
        node.text = NAMES[(node.get('name'), node.get('localSheetId'))]
    parts['xl/workbook.xml'] = E.tostring(workbook)

    worksheet = E.fromstring(parts['xl/worksheets/sheet2.xml'])
    cache_changes = []
    for address, formula in FORMULAS.items():
        cell = worksheet.find(f'.//{X}c[@r="{address}"]')
        cell.find(X + 'f').text = formula
        assert cell.find(X + 'v').text == '42'
        if address in EXPECTED_CACHES:
            typ, value = EXPECTED_CACHES[address]
            if typ is None:
                cell.attrib.pop('t', None)
            else:
                cell.set('t', typ)
            cell.find(X + 'v').text = value
            cache_changes.append({'cell': address, 'source_value': '42',
                                  'expected_type': typ, 'expected_value': value})
    validation = worksheet.find(X + 'dataValidations')[0]
    validation.find(X + 'formula1').text = "'O''Brien 2026'!$B$2"
    validation.find(X + 'formula2').text = "'O''Brien 2026'!$B$3"
    conditional = worksheet.find(X + 'conditionalFormatting')
    formulas = conditional.findall(X + 'cfRule/' + X + 'formula')
    assert len(formulas) == 2
    formulas[0].text = "'O''Brien 2026'!B2>0"
    formulas[1].text = "SUM('O''Brien 2026:Summary'!B2)>1"
    worksheet.find(X + 'hyperlinks/' + X + 'hyperlink').set('location', "'O''Brien 2026'!A1")
    worksheet.find(X + 'dataConsolidate/' + X + 'dataRefs/' + X + 'dataRef').set('sheet', NAME)
    parts['xl/worksheets/sheet2.xml'] = E.tostring(worksheet)

    cache = E.fromstring(parts['xl/pivotCache/pivotCacheDefinition1.xml'])
    cache.find(X + 'cacheSource/' + X + 'worksheetSource').set('sheet', NAME)
    parts['xl/pivotCache/pivotCacheDefinition1.xml'] = E.tostring(cache)
    chart = E.fromstring(parts['xl/charts/chart1.xml'])
    refs = list(chart.iter(C + 'f'))
    assert len(refs) == 3
    for node, formula in zip(refs, ["'O''Brien 2026'!B1", "'O''Brien 2026'!$A$2:$A$3", "'O''Brien 2026'!$B$2:$B$3"]):
        node.text = formula
    parts['xl/charts/chart1.xml'] = E.tostring(chart)

    changed = sorted(name for name in original if original[name] != parts[name])
    assert changed == ['xl/charts/chart1.xml', 'xl/pivotCache/pivotCacheDefinition1.xml',
                       'xl/workbook.xml', 'xl/worksheets/sheet2.xml']
    destination.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(destination, 'w') as archive:
        for entry in entries:
            archive.writestr(entry, parts[entry.filename])
    report = {'source': str(source), 'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
              'reference': str(destination), 'reference_sha256': hashlib.sha256(destination.read_bytes()).hexdigest(),
              'changed_parts': changed, 'explicit_cache_changes': cache_changes,
              'all_other_parts_byte_identical': True,
              'author_script_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
    destination.with_suffix('.json').write_text(json.dumps(report, indent=2) + '\n')
    return report


if __name__ == '__main__':
    print(json.dumps(build(Path(sys.argv[1]), Path(sys.argv[2])), indent=2))
