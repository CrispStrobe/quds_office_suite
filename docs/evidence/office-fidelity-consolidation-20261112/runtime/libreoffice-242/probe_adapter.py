"""Exercise normal imports, a qualified native refusal, and export failure."""
from pathlib import Path
import hashlib
import importlib.util
import json
import os
import subprocess
import tempfile
import time

runtime = Path(__file__).resolve().parent
base = runtime.parent.parent
repo = base / 'quds_office_suite'
os.chdir(repo)
root = repo / 'build/office-evidence'
output = Path(tempfile.mkdtemp(prefix='renderer-adapter-probe-', dir=repo / 'build'))
spec = importlib.util.spec_from_file_location('office_render', repo / 'tool/office-validation/render.py')
render = importlib.util.module_from_spec(spec)
spec.loader.exec_module(render)
cases = {
    'docx': 'quds_office_engine/fidelity/unchanged-1.docx',
    'xlsx': 'quds_office_engine/fidelity/sheet-edited-1.xlsx',
    'pptx': 'quds_office_engine/fidelity/slide-imported-1.pptx',
    'native_aux': 'quds_office_engine/fidelity-aux-controls/source.docx',
}
report = {
    'status': 'running',
    'renderer': subprocess.check_output(['libreoffice', '--version'], text=True).strip(),
    'results': [],
}


def record(entry):
    report['results'].append(entry)
    (output / 'probe-report.json').write_text(json.dumps(report, indent=2) + '\n')


for case, name in cases.items():
    directory = output / case
    directory.mkdir()
    source = root / name
    started = time.monotonic()
    command = ['libreoffice', f'-env:UserInstallation={(directory / "profile").as_uri()}',
               '--headless', '--convert-to', 'pdf', '--outdir', str(directory), str(source)]
    result = subprocess.run(command, capture_output=True, text=True, timeout=15)
    pdf = directory / (source.stem + '.pdf')
    entry = {
        'case': case, 'input': name,
        'input_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
        'returncode': result.returncode, 'elapsed_seconds': time.monotonic() - started,
        'stdout': result.stdout, 'stderr': result.stderr, 'pdf_exists': pdf.exists(),
    }
    if case == 'native_aux':
        error = subprocess.CalledProcessError(result.returncode, command,
                                              output=result.stdout, stderr=result.stderr)
        entry['qualified_native_import_refusal'] = render.known_native_import_rejection(error)
        paths = list(source.parent.glob('*.docx'))
        render.validate_native_aux_corpus(paths)
        entry['schema_receipts_matched'] = len(render.matching_schema_receipts(
            paths, repo / 'build/external/schema-report.json'))
        record(entry)
        assert result.returncode == 1 and entry['qualified_native_import_refusal'] and not pdf.exists()
    else:
        if pdf.exists():
            entry['pdfinfo'] = subprocess.check_output(['pdfinfo', str(pdf)], text=True)
            entry['text'] = subprocess.check_output(['pdftotext', str(pdf), '-'], text=True)
        record(entry)
        assert result.returncode == 0 and pdf.stat().st_size > 0 and entry['text'].strip()

directory = output / 'export_failure'
directory.mkdir()
(directory / 'not-a-directory').write_text('Deliberately block PDF output for this negative control.\n')
command = [str(runtime / 'lok_convert'), str(runtime / 'root/opt/libreoffice24.2/program'),
           (directory / 'profile').as_uri(), str(root / cases['docx']),
           str(directory / 'not-a-directory/output.pdf')]
result = subprocess.run(command, capture_output=True, text=True, timeout=15)
error = subprocess.CalledProcessError(result.returncode, command,
                                      output=result.stdout, stderr=result.stderr)
entry = {'case': 'export_failure', 'returncode': result.returncode,
         'stdout': result.stdout, 'stderr': result.stderr,
         'qualified_native_import_refusal': render.known_native_import_rejection(error)}
record(entry)
assert result.returncode == 74 and not entry['qualified_native_import_refusal']
report['status'] = 'passed'
(output / 'probe-report.json').write_text(json.dumps(report, indent=2) + '\n')
print(output / 'probe-report.json')
print(json.dumps({key: report[key] for key in ('status', 'renderer')}))
for entry in report['results']:
    print(json.dumps({key: value for key, value in entry.items() if key in (
        'case', 'returncode', 'elapsed_seconds', 'qualified_native_import_refusal', 'schema_receipts_matched')}))
