import 'dart:convert';

import 'package:quds_office_engine/quds_office_engine.dart';
import 'baseline_word_table.dart' as old;
import 'word_steps.dart' as before;
import '../../quds_office_suite/packages/quds_office_engine/tool/fidelity/word_steps.dart' as after;

WmlDocument source() => WmlDocument(sections: [WmlSection(blocks: [WmlTable(
  grid: [60, 60],
  rows: [
    WmlTableRow(cells: [
      WmlTableCell(vMerge: WmlVMerge.restart, blocks: [WmlParagraph(inlines: [WmlRun(text: 'Top')])]),
      WmlTableCell(blocks: [WmlParagraph(inlines: [WmlRun(text: 'Right')])]),
    ]),
    WmlTableRow(cells: [
      WmlTableCell(vMerge: WmlVMerge.cont, blocks: [WmlParagraph()]),
      WmlTableCell(blocks: [WmlParagraph(inlines: [WmlRun(text: 'Bottom')])]),
    ]),
  ],
)])]);

void main() {
  final table = source().sections.single.blocks.single as WmlTable;
  final results = <String, Object?>{
    'baseline_commit': '54f0f8de01416640560519aa9d732f668f603709',
    'partial_vertical_merge': {
      'expected': false,
      'before': old.WordTable.canMerge(table, 0, 0, 0, 1),
      'after': WordTable.canMerge(table, 0, 0, 0, 1),
    },
  };
  for (final mode in ['bookmark', 'revision']) {
    final rejected = <String, bool>{};
    for (final version in ['before', 'after']) {
      final doc = source();
      final t = doc.sections.single.blocks.single as WmlTable;
      final first = t.rows[0].cells[0].blocks.single as WmlParagraph;
      final other = t.rows[0].cells[1].blocks.single as WmlParagraph;
      if (mode == 'bookmark') {
        first.inlines.insert(0, WmlBookmarkBoundary(id: '1', isStart: true, name: 'Cross'));
        other.inlines.add(WmlBookmarkBoundary(id: '1', isStart: false));
      } else {
        doc.revisions.add(WmlRevision(id: 1, kind: WmlRevisionKind.insert,
          paragraphIndex: 0, start: 0, end: 3, text: 'Top'));
      }
      try {
        (version == 'before' ? before.applyStep : after.applyStep)(doc, {
          'op': 'tableCellText', 'table': 0, 'row': 0, 'column': 0, 'text': 'Changed',
        });
        rejected[version] = false;
      } on ArgumentError {
        rejected[version] = true;
      }
    }
    results['${mode}_owner_removal_rejected'] = {'expected': true, ...rejected};
  }
  print(const JsonEncoder.withIndent('  ').convert(results));
  final merge = results['partial_vertical_merge'] as Map<String, Object?>;
  if (merge['before'] != true || merge['after'] != false) throw StateError('Merge control failed');
  for (final mode in ['bookmark', 'revision']) {
    final values = results['${mode}_owner_removal_rejected'] as Map<String, Object?>;
    if (values['before'] != false || values['after'] != true) throw StateError('$mode control failed');
  }
}
