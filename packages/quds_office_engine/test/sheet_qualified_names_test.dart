import 'dart:io';

import 'package:quds_office_engine/quds_office_engine.dart';
import 'package:test/test.dart';

const _fixture = 'test/fixtures/fidelity/sheet-qualified-names-native.xlsx';

SmlWorkbook _read() =>
    SheetDeserializer().readBytes(File(_fixture).readAsBytesSync());

Object? _eval(SmlWorkbook book, String formula, {int sheet = 2}) =>
    evaluateFormula(
      formula,
      FormulaContext(
        workbook: book,
        sheet: book.sheets[sheet],
        origin: SmlCellRef.parse('Z20'),
      ),
    );

void main() {
  test('localSheetId is the worksheet index and locals precede global names', () {
    final book = _read();
    expect(book.sheets.map((sheet) => sheet.sheetId), [41, 7, 99]);
    expect(_eval(book, 'Price', sheet: 0), 13);
    expect(_eval(book, 'Price', sheet: 1), 7);
    expect(_eval(book, 'Price'), 11);
  });

  test('qualified names select their scope independently of the target sheet', () {
    final book = _read();
    expect(_eval(book, 'aLpHa!pRiCe'), 13);
    expect(_eval(book, "'O''Brien Data'!pRiCe"), 7);
    expect(_eval(book, "SUM('O''Brien Data'!Points)"), 16);
    expect(_eval(book, "'O''Brien Data'!Foreign"), 17);
    expect(_eval(book, "'O''Brien Data'!_Local.Total"), 9);
    expect(_eval(book, "'O''Brien Data'!قيمة"), 7);
  });

  test('named scalar constants preserve boolean, text, error and numeric types', () {
    final book = _read();
    expect(_eval(book, "'O''Brien Data'!Flag"), isTrue);
    expect(_eval(book, "'O''Brien Data'!Text"), '#REF!');
    expect(_eval(book, "ISERROR('O''Brien Data'!Text)"), isFalse);
    expect(_eval(book, "ISERROR('O''Brien Data'!Problem)"), isTrue);
    expect(_eval(book, "'O''Brien Data'!Rate"), -2.5);
    expect(_eval(book, "SUM('O''Brien Data'!Errors)"), '#DIV/0!');
  });

  test('unsupported local definitions shadow globals and retain typed caches', () {
    final book = _read();
    FormulaDepGraph(book).recalculate();
    final sheet = book.sheets[2];
    expect(sheet.cellA1('D13').value, 42);
    expect(sheet.cellA1('D14').value, isTrue);
    expect(sheet.cellA1('D15').value, '#REF!');
    expect(sheet.cellA1('D15').type, SmlCellType.string);
    expect(sheet.cellA1('D16').value, '#N/A');
    expect(sheet.cellA1('D16').type, SmlCellType.error);
    expect(sheet.cellA1('D17').value, 81);
    expect(sheet.cellA1('D18').value, 73);
  });
}
