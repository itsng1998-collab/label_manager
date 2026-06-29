import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fortune_sheet/src/fortune_sheet_model.dart' hide Image, Rect;

void main() {
  test('cell style normalization follows FortuneSheet defaults', () {
    const cell = FortuneCell();

    expect(cell.normalizedHorizontalAlign, '1');
    expect(cell.normalizedVerticalAlign, '0');
    expect(cell.normalizedTextWrap, '0');
    expect(cell.normalizedTextRotationMode, '0');
    expect(cell.normalizedTextRotation, 0);
    expect(cell.isVerticalText, isFalse);
  });

  test('invalid alignment and rotation values are clamped or reset', () {
    const cell = FortuneCell(
      horizontalAlign: '9',
      verticalAlign: 'x',
      textWrap: '5',
      textRotation: '181',
      textRotationMode: '9',
    );

    expect(cell.normalizedHorizontalAlign, '1');
    expect(cell.normalizedVerticalAlign, '0');
    expect(cell.normalizedTextWrap, '0');
    expect(cell.normalizedTextRotationMode, '0');
    expect(cell.normalizedTextRotation, 0);
  });

  test('justify alignment is preserved for RTF qj rendering', () {
    const cell = FortuneCell(horizontalAlign: '3');

    expect(cell.normalizedHorizontalAlign, '3');
  });

  test('explicit rotation angle folds like FortuneSheet canvas text', () {
    expect(const FortuneCell(textRotation: '0').normalizedTextRotation, 0);
    expect(const FortuneCell(textRotation: '45').normalizedTextRotation, 45);
    expect(const FortuneCell(textRotation: '90').normalizedTextRotation, 90);
    expect(const FortuneCell(textRotation: '135').normalizedTextRotation, -45);
    expect(const FortuneCell(textRotation: '180').normalizedTextRotation, -90);
    expect(const FortuneCell(textRotation: '-1').normalizedTextRotation, 0);
    expect(const FortuneCell(textRotation: '181').normalizedTextRotation, 0);
  });

  test('font family follows FortuneSheet font array indices', () {
    expect(const FortuneCell().normalizedFontFamily, 'Arial');
    expect(
      const FortuneCell(fontFamily: '0').normalizedFontFamily,
      'Times New Roman',
    );
    expect(
      const FortuneCell(fontFamily: 'Verdana').normalizedFontFamily,
      'Verdana',
    );
    expect(
      const FortuneCell(fontFamily: '"Custom Font"').normalizedFontFamily,
      'Custom Font',
    );
  });

  test('rotation mode maps FortuneSheet tr values to render behavior', () {
    expect(const FortuneCell(textRotationMode: '1').normalizedTextRotation, 45);
    expect(
      const FortuneCell(textRotationMode: '2').normalizedTextRotation,
      -45,
    );
    expect(const FortuneCell(textRotationMode: '4').normalizedTextRotation, 90);
    expect(
      const FortuneCell(textRotationMode: '5').normalizedTextRotation,
      -90,
    );
    expect(const FortuneCell(textRotationMode: '3').isVerticalText, isTrue);
  });

  test('visual empty state follows rendered text and formula', () {
    expect(const FortuneCell().isVisuallyEmpty, isTrue);
    expect(const FortuneCell(value: 'x').isVisuallyEmpty, isFalse);
    expect(const FortuneCell(formula: '=A1').isVisuallyEmpty, isFalse);
  });

  test('inline rich text runs compose rendered text', () {
    const cell = FortuneCell(
      value: 'fallback',
      inlineRuns: [
        FortuneInlineTextRun(text: 'A', bold: true),
        FortuneInlineTextRun(text: '1', underline: true),
      ],
    );

    expect(cell.renderedText, 'A1');
    expect(cell.isVisuallyEmpty, isFalse);
  });

  test('rendered text uses raw display metadata before raw value', () {
    const cell = FortuneCell(
      value: '0.25',
      rawDisplayValue: '25%',
      hasRawDisplayValue: true,
    );
    const richCell = FortuneCell(
      value: 'fallback',
      rawDisplayValue: 'ignored display',
      hasRawDisplayValue: true,
      inlineRuns: [FortuneInlineTextRun(text: 'rich')],
    );

    expect(cell.renderedText, '25%');
    expect(richCell.renderedText, 'rich');
  });

  test('edited value keeps visual metadata and clears derived text state', () {
    const cell = FortuneCell(
      value: 'old',
      rawValue: 10,
      hasRawValue: true,
      displayValue: 'OLD',
      formula: '=A1',
      merge: FortuneCellMerge(row: 1, column: 2, rowSpan: 2, columnSpan: 3),
      cellType: FortuneCellType(
        type: 'inlineStr',
        style: [
          {'v': 'rich'},
        ],
      ),
      bold: true,
      inlineRuns: [FortuneInlineTextRun(text: 'rich')],
    );

    final edited = cell.withEditedValue('new');

    expect(edited.value, 'new');
    expect(edited.rawValue, 'new');
    expect(edited.hasRawValue, isTrue);
    expect(edited.displayValue, isNull);
    expect(edited.formula, isNull);
    expect(edited.renderedText, 'new');
    expect(edited.merge?.rowSpan, 2);
    expect(edited.merge?.columnSpan, 3);
    expect(edited.cellType, isNull);
    expect(edited.bold, isTrue);
    expect(edited.inlineRuns, isNull);
  });

  test('cleared content preserves metadata and visual style', () {
    const cell = FortuneCell(
      value: '=A1',
      rawValue: '=A1',
      hasRawValue: true,
      displayValue: '10',
      formula: '=A1',
      sparkline: {'type': 'line'},
      cellType: FortuneCellType(
        format: 'General',
        type: 'inlineStr',
        style: [
          {'v': 'rich'},
        ],
      ),
      comment: FortuneCellComment(value: 'note'),
      hyperlink: FortuneHyperlink(linkAddress: 'https://example.test'),
      background: Color(0xfffff2cc),
      bold: true,
      inlineRuns: [FortuneInlineTextRun(text: 'rich')],
    );

    final cleared = cell.withClearedContent();

    expect(cleared.renderedText, '');
    expect(cleared.rawValue, '');
    expect(cleared.hasRawValue, isTrue);
    expect(cleared.displayValue, isNull);
    expect(cleared.formula, isNull);
    expect(cleared.sparkline, isNull);
    expect(cleared.cellType?.format, 'General');
    expect(cleared.cellType?.type, isNull);
    expect(cleared.cellType?.style, isNull);
    expect(cleared.comment?.value, 'note');
    expect(cleared.hyperlink?.linkAddress, 'https://example.test');
    expect(cleared.background, const Color(0xfffff2cc));
    expect(cleared.bold, isTrue);
    expect(cleared.inlineRuns, isNull);
  });

  test('copyWith can explicitly clear nullable cell metadata', () {
    const cell = FortuneCell(
      value: 'old',
      rawValue: 10,
      hasRawValue: true,
      displayValue: 'OLD',
      formula: '=A1',
      merge: FortuneCellMerge(row: 0, column: 0, rowSpan: 2, columnSpan: 2),
      cellType: FortuneCellType(format: 'General', type: 'n'),
      sparkline: {'type': 'line'},
      locked: true,
      comment: FortuneCellComment(value: 'note'),
      hyperlink: FortuneHyperlink(linkAddress: 'https://example.test'),
      background: Color(0xfffff2cc),
      fontSize: 14,
      fontFamily: 'Arial',
      horizontalAlign: '2',
      verticalAlign: '1',
      textWrap: '2',
      textRotation: '45',
      textRotationMode: '1',
      inlineRuns: [FortuneInlineTextRun(text: 'rich')],
      extraFields: {'custom': 'preserved'},
    );

    final copied = cell.copyWith(
      displayValue: null,
      rawValue: null,
      hasRawValue: false,
      formula: null,
      merge: null,
      cellType: null,
      sparkline: null,
      locked: null,
      comment: null,
      hyperlink: null,
      background: null,
      fontSize: null,
      fontFamily: null,
      horizontalAlign: null,
      verticalAlign: null,
      textWrap: null,
      textRotation: null,
      textRotationMode: null,
      inlineRuns: null,
    );

    expect(copied.value, 'old');
    expect(copied.rawValue, isNull);
    expect(copied.hasRawValue, isFalse);
    expect(copied.displayValue, isNull);
    expect(copied.formula, isNull);
    expect(copied.merge, isNull);
    expect(copied.cellType, isNull);
    expect(copied.sparkline, isNull);
    expect(copied.locked, isNull);
    expect(copied.comment, isNull);
    expect(copied.hyperlink, isNull);
    expect(copied.background, isNull);
    expect(copied.fontSize, isNull);
    expect(copied.fontFamily, isNull);
    expect(copied.horizontalAlign, isNull);
    expect(copied.verticalAlign, isNull);
    expect(copied.textWrap, isNull);
    expect(copied.textRotation, isNull);
    expect(copied.textRotationMode, isNull);
    expect(copied.inlineRuns, isNull);
    expect(copied.extraFields['custom'], 'preserved');
  });

  test('copyWith value changes do not keep stale raw value metadata', () {
    const cell = FortuneCell(
      value: '10',
      rawValue: 10,
      hasRawValue: true,
      displayValue: '10',
      rawDisplayValue: 10,
      hasRawDisplayValue: true,
    );

    final changed = cell.copyWith(value: '11', displayValue: 'eleven');
    final changedBack = changed.copyWith(value: '10', displayValue: null);

    expect(changed.value, '11');
    expect(changed.rawValue, '11');
    expect(changed.hasRawValue, isTrue);
    expect(changed.displayValue, 'eleven');
    expect(changed.rawDisplayValue, 'eleven');
    expect(changed.hasRawDisplayValue, isTrue);
    expect(changedBack.value, '10');
    expect(changedBack.rawValue, '10');
    expect(changedBack.hasRawValue, isTrue);
    expect(changedBack.displayValue, isNull);
    expect(changedBack.rawDisplayValue, isNull);
    expect(changedBack.hasRawDisplayValue, isFalse);
  });

  test('copyWith accepts integer geometry values for metadata models', () {
    const image = FortuneImage(
      id: 'img1',
      src: 'data:image/png;base64,test',
      left: 1,
      top: 2,
      width: 3,
      height: 4,
    );
    const comment = FortuneCellComment(
      value: 'note',
      left: 1,
      top: 2,
      width: 3,
      height: 4,
    );

    final movedImage = image.copyWith(left: 10, top: 20, width: 30, height: 40);
    final movedComment = comment.copyWith(
      left: 10,
      top: 20,
      width: 30,
      height: 40,
      isShow: 'true',
    );

    expect(movedImage.left, 10);
    expect(movedImage.top, 20);
    expect(movedImage.width, 30);
    expect(movedImage.height, 40);
    expect(movedComment.left, 10);
    expect(movedComment.top, 20);
    expect(movedComment.width, 30);
    expect(movedComment.height, 40);
    expect(movedComment.isShow, isTrue);
  });

  test('copyWith accepts numeric and boolean metadata strings', () {
    const cell = FortuneCell(locked: false);
    const hyperlink = FortuneHyperlink(row: 0, column: 0);
    const frozen = FortuneFrozenPane(type: 'rangeBoth');
    const merge = FortuneCellMerge(row: 0, column: 0);
    const range = FortuneRange(
      rowStart: 0,
      rowEnd: 0,
      columnStart: 0,
      columnEnd: 0,
    );
    const run = FortuneInlineTextRun(text: 'old');
    const border = FortuneBorderInfo(
      rangeType: 'range',
      borderType: 'border-all',
      color: Color(0xff000000),
      style: 1,
      ranges: [
        FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 0, columnEnd: 0),
      ],
    );

    final lockedCell = cell.copyWith(locked: '1');
    final movedHyperlink = hyperlink.copyWith(row: '3', column: 4.0);
    final movedFrozen = frozen.copyWith(rowFocus: '2', columnFocus: 3.0);
    final movedMerge = merge.copyWith(
      row: '4',
      column: 5.0,
      rowSpan: '6',
      columnSpan: 7.0,
    );
    final movedRange = range.copyWith(
      rowStart: '1',
      rowEnd: 2.0,
      columnStart: '3',
      columnEnd: 4.0,
      rowFocus: '5',
      columnFocus: 6.0,
    );
    final changedRun = run.copyWith(
      bold: 'true',
      italic: 1,
      underline: '0',
      fontSize: '12.5',
      fontFamily: 2,
    );
    final changedBorder = border.copyWith(
      rangeType: 7,
      borderType: Uri.parse('border.test'),
      color: '0xff778899',
      style: '3',
    );

    expect(lockedCell.locked, isTrue);
    expect(movedHyperlink.row, 3);
    expect(movedHyperlink.column, 4);
    expect(movedFrozen.rowFocus, 2);
    expect(movedFrozen.columnFocus, 3);
    expect(movedMerge.row, 4);
    expect(movedMerge.column, 5);
    expect(movedMerge.rowSpan, 6);
    expect(movedMerge.columnSpan, 7);
    expect(movedRange.rowStart, 1);
    expect(movedRange.rowEnd, 2);
    expect(movedRange.columnStart, 3);
    expect(movedRange.columnEnd, 4);
    expect(movedRange.rowFocus, 5);
    expect(movedRange.columnFocus, 6);
    expect(changedRun.bold, isTrue);
    expect(changedRun.italic, isTrue);
    expect(changedRun.underline, isFalse);
    expect(changedRun.fontSize, 12.5);
    expect(changedRun.fontFamily, '2');
    expect(changedBorder.rangeType, '7');
    expect(changedBorder.borderType, 'border.test');
    expect(changedBorder.color, const Color(0xff778899));
    expect(changedBorder.style, 3);
  });

  test(
    'copyWith clears stale raw reference metadata after coordinate edits',
    () {
      const frozen = FortuneFrozenPane(
        type: 'rangeBoth',
        rowFocus: 1,
        rawRowFocus: '1',
        hasRawRowFocus: true,
        columnFocus: 2,
        rawColumnFocus: '2',
        hasRawColumnFocus: true,
      );
      const merge = FortuneCellMerge(
        row: 0,
        rawRow: '0',
        hasRawRow: true,
        column: 1,
        rawColumn: '1',
        hasRawColumn: true,
        rowSpan: 2,
        rawRowSpan: '2',
        hasRawRowSpan: true,
        columnSpan: 3,
        rawColumnSpan: '3',
        hasRawColumnSpan: true,
      );
      const range = FortuneRange(
        rowStart: 0,
        rowEnd: 1,
        rawRow: ['0', '1'],
        hasRawRow: true,
        columnStart: 2,
        columnEnd: 3,
        rawColumn: ['2', '3'],
        hasRawColumn: true,
        rowFocus: 0,
        rawRowFocus: '0',
        hasRawRowFocus: true,
        columnFocus: 2,
        rawColumnFocus: '2',
        hasRawColumnFocus: true,
      );

      final movedFrozen = frozen.copyWith(rowFocus: 2);
      final movedMerge = merge.copyWith(columnSpan: 4);
      final movedRange = range.copyWith(rowStart: 1, columnFocus: 3);

      expect(movedFrozen.rawRowFocus, isNull);
      expect(movedFrozen.hasRawRowFocus, isFalse);
      expect(movedFrozen.rawColumnFocus, '2');
      expect(movedFrozen.hasRawColumnFocus, isTrue);
      expect(movedMerge.rawColumnSpan, isNull);
      expect(movedMerge.hasRawColumnSpan, isFalse);
      expect(movedMerge.rawRowSpan, '2');
      expect(movedMerge.hasRawRowSpan, isTrue);
      expect(movedRange.rawRow, isNull);
      expect(movedRange.hasRawRow, isFalse);
      expect(movedRange.rawColumn, ['2', '3']);
      expect(movedRange.hasRawColumn, isTrue);
      expect(movedRange.rawColumnFocus, isNull);
      expect(movedRange.hasRawColumnFocus, isFalse);
    },
  );

  test('copyWith clears stale raw style metadata after value edits', () {
    const type = FortuneCellType(
      format: 'General',
      rawFormat: 1,
      hasRawFormat: true,
      type: 'inlineStr',
      rawType: 'inlineStr',
      hasRawType: true,
      style: ['old'],
      rawStyle: ['old'],
      hasRawStyle: true,
    );
    const run = FortuneInlineTextRun(
      text: 'old',
      rawText: 10,
      hasRawText: true,
      foreground: Color(0xff112233),
      rawForeground: '#112233',
      hasRawForeground: true,
      bold: true,
      rawBold: 1,
      hasRawBold: true,
      fontSize: 10,
      rawFontSize: '10',
      hasRawFontSize: true,
      fontFamily: '0',
      rawFontFamily: 0,
      hasRawFontFamily: true,
    );
    const border = FortuneBorderInfo(
      rangeType: 'range',
      borderType: 'border-all',
      color: Color(0xff112233),
      rawColor: '#112233',
      hasRawColor: true,
      style: 1,
      ranges: [
        FortuneRange(rowStart: 0, rowEnd: 0, columnStart: 0, columnEnd: 0),
      ],
    );

    final changedType = type.copyWith(format: '0.00', style: {'color': 'red'});
    final changedRun = run.copyWith(
      text: 'new',
      foreground: '#445566',
      bold: false,
      fontSize: 11,
    );
    final changedBorder = border.copyWith(color: '#445566');

    expect(changedType.rawFormat, isNull);
    expect(changedType.hasRawFormat, isFalse);
    expect(changedType.rawType, 'inlineStr');
    expect(changedType.hasRawType, isTrue);
    expect(changedType.rawStyle, isNull);
    expect(changedType.hasRawStyle, isFalse);
    expect(changedRun.rawText, isNull);
    expect(changedRun.hasRawText, isFalse);
    expect(changedRun.rawForeground, isNull);
    expect(changedRun.hasRawForeground, isFalse);
    expect(changedRun.rawBold, isNull);
    expect(changedRun.hasRawBold, isFalse);
    expect(changedRun.rawFontSize, isNull);
    expect(changedRun.hasRawFontSize, isFalse);
    expect(changedRun.rawFontFamily, 0);
    expect(changedRun.hasRawFontFamily, isTrue);
    expect(changedRun.foreground, const Color(0xff445566));
    expect(changedBorder.rawColor, isNull);
    expect(changedBorder.hasRawColor, isFalse);
    expect(changedBorder.color, const Color(0xff445566));
  });

  test('comment copyWith clears stale raw value and visibility metadata', () {
    const comment = FortuneCellComment(
      value: 'old',
      rawValue: 10,
      hasRawValue: true,
      isShow: false,
      rawIsShow: 0,
      hasRawIsShow: true,
    );

    final changed = comment.copyWith(value: 123, isShow: 'true');

    expect(changed.value, '123');
    expect(changed.rawValue, isNull);
    expect(changed.hasRawValue, isFalse);
    expect(changed.isShow, isTrue);
    expect(changed.rawIsShow, isNull);
    expect(changed.hasRawIsShow, isFalse);
  });

  test('copyWith string metadata accepts non-string values', () {
    const cell = FortuneCell();
    const image = FortuneImage(
      id: 'img1',
      src: 'data:image/png;base64,test',
      left: 0,
      top: 0,
      width: 1,
      height: 1,
    );
    const comment = FortuneCellComment(value: 'note');
    const hyperlink = FortuneHyperlink();
    const type = FortuneCellType();
    const run = FortuneInlineTextRun(text: '');

    final changedCell = cell.copyWith(
      displayValue: 123,
      formula: 456,
      background: '#112233',
      foreground: 0xff445566,
      fontFamily: 2,
      horizontalAlign: 0,
      verticalAlign: 1,
      textWrap: 2,
      textRotation: 45,
      textRotationMode: 3,
    );
    final changedHyperlink = hyperlink.copyWith(
      id: 123,
      linkType: 7,
      linkAddress: Uri.parse('https://example.test'),
    );
    final changedImage = image.copyWith(
      id: 456,
      src: Uri.parse('https://example.test/image.png'),
    );
    final changedComment = comment.copyWith(value: 789);
    final changedType = type.copyWith(format: 123, type: 456);
    final changedRun = run.copyWith(text: 123, fontFamily: 456);

    expect(changedCell.displayValue, '123');
    expect(changedCell.formula, '456');
    expect(changedCell.background, const Color(0xff112233));
    expect(changedCell.foreground, const Color(0xff445566));
    expect(changedCell.fontFamily, '2');
    expect(changedCell.horizontalAlign, '0');
    expect(changedCell.verticalAlign, '1');
    expect(changedCell.textWrap, '2');
    expect(changedCell.textRotation, '45');
    expect(changedCell.textRotationMode, '3');
    expect(changedHyperlink.id, '123');
    expect(changedHyperlink.linkType, '7');
    expect(changedHyperlink.linkAddress, 'https://example.test');
    expect(changedImage.id, '456');
    expect(changedImage.src, 'https://example.test/image.png');
    expect(changedComment.value, '789');
    expect(changedType.format, '123');
    expect(changedType.type, '456');
    expect(changedRun.text, '123');
    expect(changedRun.fontFamily, '456');
  });

  test(
    'border side copyWith normalizes style and cell borders can clear sides',
    () {
      const side = FortuneBorderSide(color: Color(0xff112233), style: 1);
      final changedSide = side.copyWith(color: '#445566', style: '3');
      final invalidStyleSide = changedSide.copyWith(style: 'invalid');
      final borders = FortuneCellBorders(top: side, left: changedSide);
      final changedBorders = borders.copyWith(
        top: changedSide,
        left: null,
        bottom: invalidStyleSide,
      );

      expect(changedSide.color, const Color(0xff445566));
      expect(changedSide.style, 3);
      expect(invalidStyleSide.style, 3);
      expect(changedBorders.top, same(changedSide));
      expect(changedBorders.left, isNull);
      expect(changedBorders.bottom, same(invalidStyleSide));
      expect(changedBorders.right, isNull);
      expect(changedBorders.slash, isNull);
      expect(changedBorders.isEmpty, isFalse);
      expect(const FortuneCellBorders().copyWith(top: null).isEmpty, isTrue);
    },
  );
}
