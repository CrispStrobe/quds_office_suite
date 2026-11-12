import 'dart:io';

import 'package:quds_office_engine/quds_office_engine.dart';
import 'package:test/test.dart';

const _problem = "'O''Brien Data'!Problem";
const _text = "'O''Brien Data'!Text";
const _unsupported = "'O''Brien Data'!Computed";

SmlWorkbook _read() => SheetDeserializer().readBytes(
  File(
    'test/fixtures/fidelity/sheet-qualified-names-native.xlsx',
  ).readAsBytesSync(),
);

Object? _eval(SmlWorkbook book, String formula) => evaluateFormula(
  formula,
  FormulaContext(
    workbook: book,
    sheet: book.sheets[2],
    origin: SmlCellRef.parse('Z30'),
  ),
);

void main() {
  for (final prefix in ['', '_xlfn.', '_xlfn._xlws.']) {
    test('qualified-name LET shadowing agrees with graph for $prefix', () {
      final book = _read();
      final formula = '${prefix}LET(Price,6,Price+1)';
      final cell = book.firstSheet.cellA1('B3')
        ..formula = formula
        ..value = 42;
      final graph = FormulaDepGraph(book)..recalculate();
      expect(_eval(book, formula), 7);
      expect(graph.circular, isEmpty);
      expect(cell.value, 7);
    });
  }

  const numeric = [
    'ABS(@)',
    'ROUND(@,0)',
    'ROUND(3,@)',
    'ROUNDUP(@,0)',
    'ROUNDDOWN(@,0)',
    'MOD(@,2)',
    'POWER(2,@)',
    'POW(@,2)',
    'SQRT(@)',
    'EXP(@)',
    'LN(@)',
    'LOG(2,@)',
    'LOG10(@)',
    'SIGN(@)',
    'INT(@)',
    'TRUNC(@)',
    'CEILING(@)',
    'FLOOR(@)',
    'EVEN(@)',
    'ODD(@)',
    'FACT(@)',
    'GCD(1,@)',
    'LCM(1,@)',
    'QUOTIENT(8,@)',
    'MROUND(8,@)',
    'MEDIAN(1,@)',
    'AVEDEV(1,@)',
    'STDEV(1,@)',
    'STDEVP(1,@)',
    'VAR(1,@)',
    'VARP(1,@)',
    'RANDBETWEEN(1,@)',
    'IRR(@)',
    'TIME(1,@,0)',
    'DAYS(2,@)',
    'VALUE(@)',
    'CHAR(@)',
    'CODE(@)',
    'UNICHAR(@)',
    'UNICODE(@)',
    'LEN(@)',
    'FIND(@,"text")',
    'SEARCH("t",@)',
    'N(@)',
    'ADDRESS(1,@)',
    'FIXED(@)',
    'DOLLAR(@)',
    'RMB(@)',
    'YEN(@)',
    'BAHTTEXT(@)',
    'DATE(2026,1,@)',
    'YEAR(@)',
    'MONTH(@)',
    'DAY(@)',
    'HOUR(@)',
    'MINUTE(@)',
    'SECOND(@)',
    'WEEKDAY(@)',
    'PV(0.1,1,@)',
    'FV(0.1,1,@)',
    'PMT(0.1,1,@)',
    'NPV(0.1,1,@)',
    'SIN(@)',
    'COS(@)',
    'TAN(@)',
    'EDATE(1,@)',
    'EOMONTH(1,@)',
    'NETWORKDAYS(1,@)',
    'SEQUENCE(1,1,@)',
  ];
  for (final pattern in numeric) {
    test('numeric consumer retains a genuine named error: $pattern', () {
      final book = _read();
      final formula = pattern.replaceAll('@', _problem);
      expect(_eval(book, formula), '#REF!');
      final cell = book.sheets[2].cellA1('Z30')
        ..formula = formula
        ..value = 42;
      FormulaDepGraph(book).recalculate();
      expect(cell.value, '#REF!');
      expect(cell.type, SmlCellType.error);
    });
  }

  test(
    'error handlers and type predicates consume genuine errors explicitly',
    () {
      final book = _read();
      expect(_eval(book, 'IFERROR(ABS($_problem),12)'), 12);
      expect(_eval(book, 'ISERROR(ROUND($_problem,0))'), isTrue);
      expect(_eval(book, 'ISERROR($_text)'), isFalse);
      expect(_eval(book, 'IFERROR($_text,12)'), '#REF!');
      expect(_eval(book, 'MEDIAN(1,$_text,3)'), 2);
      expect(_eval(book, 'N($_text)'), 0);
      expect(_eval(book, 'TYPE($_problem)'), 16);
      expect(_eval(book, 'TYPE($_text)'), 2);
    },
  );

  test(
    'IF evaluates only its selected branch and preserves predicate errors',
    () {
      final book = _read();
      expect(_eval(book, 'IF(FALSE,$_problem,7)'), 7);
      expect(_eval(book, 'IF(TRUE,7,$_problem)'), 7);
      expect(_eval(book, 'IF($_problem,7,9)'), '#REF!');
      expect(_eval(book, 'IF(FALSE,$_unsupported,7)'), 7);
      expect(_eval(book, 'IF(TRUE,7,$_unsupported)'), 7);
    },
  );

  test('IFERROR and IFNA evaluate fallback expressions only when selected', () {
    final book = _read();
    expect(_eval(book, 'IFERROR(7,$_unsupported)'), 7);
    expect(_eval(book, 'IFNA(7,$_unsupported)'), 7);
    expect(_eval(book, 'IFERROR($_problem,12)'), 12);
    expect(_eval(book, 'IFNA($_problem,12)'), '#REF!');
    expect(_eval(book, 'IFNA(NA(),12)'), 12);
  });
}
