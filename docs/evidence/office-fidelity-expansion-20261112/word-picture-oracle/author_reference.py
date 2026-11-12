"""Independent native references for the host's empty Word picture insertion.

The input is authored here from literal host intentions/defaults, without
reading any Quds-exported package. Pillow independently encodes opaque black
80x40 images; no Quds serializer or image encoder participates.
"""
from io import BytesIO
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile
from PIL import Image

ROOT = Path(__file__).resolve().parent / 'references'
ROOT.mkdir(exist_ok=True)
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
R = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
A = 'http://schemas.openxmlformats.org/drawingml/2006/main'
WP = 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing'
PIC = 'http://schemas.openxmlformats.org/drawingml/2006/picture'
PR = 'http://schemas.openxmlformats.org/package/2006/relationships'
CT = 'http://schemas.openxmlformats.org/package/2006/content-types'

for fmt in ('gif', 'jpeg'):
    data = BytesIO()
    Image.new('RGB', (80, 40), (0, 0, 0)).save(data, format=fmt.upper())
    # A4 rounded to native twips, 72pt margins. The initial empty paragraph
    # uses Arial 11pt, 1.15 line spacing and 8pt after-space. Insertion appends
    # a separate inline picture paragraph with the native 60x30pt extent.
    document = f'''<w:document xmlns:w="{W}" xmlns:r="{R}" xmlns:wp="{WP}" xmlns:a="{A}" xmlns:pic="{PIC}"><w:body>
<w:p><w:pPr><w:spacing w:before="0" w:after="160" w:line="276" w:lineRule="auto"/><w:ind w:left="0" w:right="0"/><w:jc w:val="left"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/><w:sz w:val="22"/></w:rPr><w:t xml:space="preserve"></w:t></w:r></w:p>
<w:p><w:r><w:drawing><wp:inline distT="0" distB="0" distL="114300" distR="114300"><wp:extent cx="762000" cy="381000"/><wp:effectExtent l="0" t="0" r="0" b="0"/><wp:docPr id="1" name="black-picture"/><wp:cNvGraphicFramePr><a:graphicFrameLocks noChangeAspect="1"/></wp:cNvGraphicFramePr><a:graphic><a:graphicData uri="{PIC}"><pic:pic><pic:nvPicPr><pic:cNvPr id="0" name="black-picture"/><pic:cNvPicPr><a:picLocks noChangeAspect="1"/></pic:cNvPicPr></pic:nvPicPr><pic:blipFill><a:blip r:embed="image"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill><pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="762000" cy="381000"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>
<w:sectPr><w:type w:val="nextPage"/><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1440" w:bottom="1440" w:left="1440" w:right="1440" w:header="720" w:footer="720"/><w:cols w:num="1" w:space="720"/></w:sectPr></w:body></w:document>'''
    styles = f'''<w:styles xmlns:w="{W}"><w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/><w:sz w:val="22"/></w:rPr></w:rPrDefault></w:docDefaults><w:style w:type="paragraph" w:styleId="Normal"><w:name w:val="Normal"/><w:pPr><w:spacing w:before="0" w:after="160"/><w:jc w:val="left"/></w:pPr><w:rPr><w:rFonts w:ascii="Arial" w:hAnsi="Arial" w:cs="Arial"/><w:color w:val="000000"/><w:sz w:val="22"/></w:rPr></w:style></w:styles>'''
    with ZipFile(ROOT / f'expected-{fmt}.docx', 'w', compression=ZIP_DEFLATED) as package:
        package.writestr('[Content_Types].xml', f'<Types xmlns="{CT}"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Default Extension="{fmt}" ContentType="image/{fmt}"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/></Types>')
        package.writestr('_rels/.rels', f'<Relationships xmlns="{PR}"><Relationship Id="main" Type="{R}/officeDocument" Target="word/document.xml"/></Relationships>')
        package.writestr('word/document.xml', document)
        package.writestr('word/styles.xml', styles)
        package.writestr('word/_rels/document.xml.rels', f'<Relationships xmlns="{PR}"><Relationship Id="styles" Type="{R}/styles" Target="styles.xml"/><Relationship Id="image" Type="{R}/image" Target="media/reference.{fmt}"/></Relationships>')
        package.writestr(f'word/media/reference.{fmt}', data.getvalue())
