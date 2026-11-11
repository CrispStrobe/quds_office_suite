#!/usr/bin/env python3
"""Render every exported Office document with LibreOffice and compare save cycles.
Requires libreoffice-writer/calc/impress and poppler-utils, independent of Quds.
"""
import hashlib
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

office = shutil.which('libreoffice') or shutil.which('soffice')
if not office: raise SystemExit('Install LibreOffice Writer, Calc and Impress')
root, out = map(Path, sys.argv[1:3]); out.mkdir(parents=True, exist_ok=True)
paths = sorted(p for p in root.rglob('*') if p.suffix in ('.docx','.xlsx','.pptx'))
if not paths: raise SystemExit('No Office documents to render')
reports = []; groups = {}; failures = []
for index, path in enumerate(paths):
    dest = out / f'{index:03d}'; dest.mkdir(exist_ok=True)
    try:
        subprocess.run([office, f'-env:UserInstallation={(dest / "profile").resolve().as_uri()}', '--headless', '--convert-to', 'pdf', '--outdir', str(dest), str(path.resolve())], check=True, timeout=60, capture_output=True)
        pdf = dest / (path.stem + '.pdf')
        if not pdf.exists(): raise AssertionError('LibreOffice did not produce a PDF')
        text = subprocess.check_output(['pdftotext','-layout',str(pdf),'-'],text=True,timeout=30)
        if not text.strip(): raise AssertionError('Rendered PDF has no extractable text')
        subprocess.run(['pdftoppm','-r','72',str(pdf),str(dest/'page')],check=True,timeout=60,capture_output=True)
        pixels = [hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(dest.glob('page-*.ppm'))]
        if not pixels: raise AssertionError('PDF contains no rendered pages')
        record = {'file':str(path.relative_to(root)), 'pages':len(pixels), 'text':text, 'pixel_sha256':pixels}
        reports.append(record)
        match = re.match(r'(.+)-(\d+)$',path.stem)
        if match:
            key = str(path.parent / (match[1]+path.suffix))
            previous = groups.get(key)
            if previous and (previous['text'] != text or previous['pixel_sha256'] != pixels):
                raise AssertionError(f'Render changed across save cycles: {previous["file"]}')
            groups[key] = record
        print(f'{path}: rendered {len(pixels)} pages',flush=True)
        # Keep the PDF and pixel hashes; discard large raw pixel buffers.
        for ppm in dest.glob('page-*.ppm'): ppm.unlink()
    except Exception as error:
        failures.append({'file':str(path),'error':str(error)})
        print(f'{path}: {error}',flush=True)
(out/'render-report.json').write_text(json.dumps({'renderer':subprocess.check_output([office,'--version'],text=True).strip(),'files':len(paths),'cycle_groups':len(groups),'failures':failures,'reports':reports},indent=2)+'\n')
if failures: raise SystemExit(1)
