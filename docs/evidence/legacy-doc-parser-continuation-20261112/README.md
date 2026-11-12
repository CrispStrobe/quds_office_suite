# Legacy Word continuation integration

This workspace integrates standalone parser `ba5f5b0cdd540bd0c03f62aabc88faadd8660e0b`.
It adds bounded EMF/WMF arcs, independent object/reference revision provenance,
and the paragraph-mark/OLE serialization corrections exposed by the expanded
Open XML SDK gate. Original metafiles and object payloads retain their source
bytes; unsupported preview operations remain diagnosed.

The full mirrored parser suite passes **666 tests** under the suite's existing
XML 7 workspace resolution. The three focused engine legacy import, conversion
and note-marker suites pass **21 tests**. Logs and all 360 upstream-file hashes
are retained here. Before copying, every old mirrored file was checked against
its original immutable source. After copying, every new file was checked again;
only the documented workspace/dev-dependency pubspec patch differs.

These are parser and bridge integration checks. They do not qualify the full
editor, release configuration, universal pagination or arbitrary Office data.
The standalone parser's independent schema/native measurements retain their
own source and renderer provenance.
