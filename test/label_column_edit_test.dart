import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/barcode.dart';
import 'package:label_manager/features/label_column/domain/column.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/features/label_column/domain/label_column_edit.dart';

const baseType = TColumnType(code: TColumnType.TYPE_BASE, name: '기본', order: 1);
const barcodeType = TColumnType(
  code: TColumnType.TYPE_BARCODE,
  name: '바코드',
  order: 2,
);

TColumn column(int id, String keyword, {int order = 1}) {
  return TColumn(
    columnType: baseType,
    keyword: keyword,
    columnName: keyword,
    useMissingKeywordCheck: false,
    useMinColumnCheck: false,
    columnId: id,
    labelSizeId: 10,
    order: order,
    width: 0,
    height: 0,
    barcodeType: BarcodeType.Code128,
    useBarcodeCheckDigit: true,
    showBarcodeNum: true,
    showQRCodeText: false,
    qrTextAlignment: QRTextAlignment.ALIGN_LEFT,
    useUserDefineQRData: false,
    userDefineQRData: '',
    userDefineQRText: '',
    pixelSize: 0,
    title: '',
    visible: false,
    qrCodeCreateType: QRCodeCreateType.QRCODE_TYPE_PLAIN_TEXT,
    natriumJoinString: '',
    qrTextFontSize: 10,
    qrTextFontName: '',
    qrCodeScalePercent: 100,
    timeBarcodeType: 0,
    autoInc: false,
    autoIncSize: 0,
    autoIncSave: false,
    autoIncRange: 0,
    autoIncZeroDel: false,
    autoIncUpdate: false,
    searchPrint: false,
    userDefineBarcodeText: '',
    lineCheck: 0,
    lineSize: 0,
    gs1ai: '01',
    formatOption: -1,
    useGS1Code: false,
    containColumns: '',
    showGS1Code: false,
    rotate: 0,
    useDateRange: false,
    dateRange: '',
  );
}

void main() {
  group('LabelColumnEditSession', () {
    test('applies and cancels property edits without mutating original', () {
      var session = LabelColumnEditSession.fromColumns(
        labelSizeId: 10,
        columns: [column(1, 'PRICE')],
      ).beginPropertyEdit();
      final changed = session.propertyDraft!.copyWith(
        column: session.propertyDraft!.column.copyWith(columnName: '판매가'),
      );

      session = session.updatePropertyDraft(changed);
      expect(session.propertyDirty, isTrue);
      expect(session.originalColumns.single.column.columnName, 'PRICE');

      session = session.applyProperty();
      expect(session.workingColumns.single.column.columnName, '판매가');
      expect(session.workingDirty, isTrue);
      final command = session.toSaveCommand();
      expect(command.updatedColumns.single.key, 'column:1');
      expect(command.changedKeysByColumnId[1], {'name'});
    });

    test('requires initial apply and cancel removes a new special row', () {
      var session = LabelColumnEditSession.fromColumns(
        labelSizeId: 10,
        columns: [column(1, 'PRICE')],
      );
      final draft = LabelColumnDraft.fromCandidate(
        draftKey: 'draft:1',
        labelSizeId: 10,
        order: 2,
        columnType: barcodeType,
        keyword: 'barcode',
        columnName: '바코드',
      );

      session = session.add(draft);
      expect(session.pendingInitialApplyColumnKeys, {'draft:1'});
      expect(session.toSaveCommand, throwsA(isA<StateError>()));

      session = session.cancelProperty();
      expect(session.workingColumns.map((row) => row.key), ['column:1']);
      expect(session.pendingInitialApplyColumnKeys, isEmpty);
    });

    test('tracks existing deletion and keeps continuous stable-key order', () {
      var session = LabelColumnEditSession.fromColumns(
        labelSizeId: 10,
        columns: [column(1, 'A'), column(2, 'B', order: 2)],
      );

      session = session.remove('column:1').enterReorder();
      final added = LabelColumnDraft.fromCandidate(
        draftKey: 'draft:1',
        labelSizeId: 10,
        order: 2,
        columnType: baseType,
        keyword: 'C',
        columnName: 'C',
      );
      session = session.applyReorder().add(added).cancelProperty();

      expect(session.deletedColumnIds, {1});
      expect(session.workingColumns.map((row) => row.column.order), [1, 2]);
      final command = session.toSaveCommand();
      expect(command.deletedColumnIds, {1});
      expect(command.newColumns.single.key, 'draft:1');
    });

    test('reorders by stable key and restores snapshot on cancel', () {
      var session = LabelColumnEditSession.fromColumns(
        labelSizeId: 10,
        columns: [column(1, 'A'), column(2, 'B', order: 2)],
      ).enterReorder();

      session = session.reorder('column:2', 0);
      expect(session.workingColumns.map((row) => row.key), ['column:2', 'column:1']);
      expect(session.workingColumns.map((row) => row.column.order), [1, 2]);

      session = session.cancelReorder();
      expect(session.workingColumns.map((row) => row.key), ['column:1', 'column:2']);
    });

    test('rejects new duplicate and reserved keywords but preserves untouched rows', () {
      final session = LabelColumnEditSession.fromColumns(
        labelSizeId: 10,
        columns: [column(1, 'ITEMNAME'), column(2, 'DUP', order: 2)],
      );
      final duplicate = LabelColumnDraft.fromCandidate(
        draftKey: 'draft:duplicate',
        labelSizeId: 10,
        order: 3,
        columnType: baseType,
        keyword: 'dup',
        columnName: '중복',
      );
      final reserved = LabelColumnDraft.fromCandidate(
        draftKey: 'draft:reserved',
        labelSizeId: 10,
        order: 3,
        columnType: baseType,
        keyword: 'element',
        columnName: '주원료',
      );

      expect(() => session.add(duplicate), throwsA(isA<LabelColumnValidationException>()));
      expect(() => session.add(reserved), throwsA(isA<LabelColumnValidationException>()));
      expect(session.toSaveCommand, returnsNormally);
    });
  });
}