import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/core/barcode.dart';
import 'package:label_manager/features/item/domain/additional_item.dart';
import 'package:label_manager/features/item/domain/column_content.dart';
import 'package:label_manager/features/item/domain/item.dart';
import 'package:label_manager/features/item/domain/item_of_market.dart';
import 'package:label_manager/features/label_column/domain/column.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/features/label_print/domain/label_print.dart';
import 'package:label_manager/features/label_print/data/label_print_persistence.dart';
import 'package:label_manager/features/label_size/domain/label_size.dart';
import 'package:label_manager/printing/label_print_dispatcher.dart';
import 'package:label_manager/features/label_print/application/label_print_pipeline.dart';

void main() {
  test('units exclude zero copies and preserve row and copy order', () {
    final rows = [
      _row(10, 2),
      _row(20, 0),
      _row(30, 2),
    ];
    final units = expandLabelPrintUnits(rows, referenceAt: _referenceAt);
    expect(
      units.map((unit) => (unit.row.itemId, unit.rowIndex, unit.copyIndex)),
      [(10, 0, 0), (10, 0, 1), (30, 2, 0), (30, 2, 1)],
    );
  });

  test('grouping combines only adjacent equal physical specs', () {
    final units = expandLabelPrintUnits(
      [_row(10, 1), _row(20, 1), _row(30, 1)],
      referenceAt: _referenceAt,
    );
    const first = LabelPhysicalPageSpec(
      widthMm: 60,
      heightMm: 40,
      sourceWidthMm: 50,
      sourceHeightMm: 30,
      dpi: 203,
      backend: LabelPrintBackend.pdf,
    );
    const second = LabelPhysicalPageSpec(
      widthMm: 80,
      heightMm: 40,
      sourceWidthMm: 50,
      sourceHeightMm: 30,
      dpi: 203,
      backend: LabelPrintBackend.pdf,
    );
    final groups = groupAdjacentLabelPrintUnits(
      units,
      (unit) => unit.row.itemId == 20 ? second : first,
    );
    expect(groups.map((group) => group.units.length), [1, 1, 1]);
  });

  test('PDF single file combines all units into one ordered group', () {
    final units = expandLabelPrintUnits(
      [_row(10, 1), _row(20, 1), _row(30, 1)],
      referenceAt: _referenceAt,
    );
    const first = LabelPhysicalPageSpec(
      widthMm: 60,
      heightMm: 40,
      sourceWidthMm: 50,
      sourceHeightMm: 30,
      dpi: 203,
      backend: LabelPrintBackend.pdf,
    );
    const second = LabelPhysicalPageSpec(
      widthMm: 80,
      heightMm: 40,
      sourceWidthMm: 50,
      sourceHeightMm: 30,
      dpi: 203,
      backend: LabelPrintBackend.pdf,
    );
    LabelPhysicalPageSpec specFor(LabelPrintUnit unit) =>
        unit.row.itemId == 20 ? second : first;

    final combined = groupLabelPrintUnitsForDispatch(
      units,
      specFor,
      pdfSingleFile: true,
    );
    final separate = groupLabelPrintUnitsForDispatch(
      units,
      specFor,
      pdfSingleFile: false,
    );

    expect(combined, hasLength(1));
    expect(combined.single.units.map((unit) => unit.row.itemId), [10, 20, 30]);
    expect(separate.map((group) => group.units.length), [1, 1, 1]);
  });

  test('single file option does not combine Windows driver groups', () {
    final units = expandLabelPrintUnits(
      [_row(10, 1), _row(20, 1)],
      referenceAt: _referenceAt,
    );
    final groups = groupLabelPrintUnitsForDispatch(
      units,
      (unit) => LabelPhysicalPageSpec(
        widthMm: unit.row.itemId == 10 ? 60 : 80,
        heightMm: 40,
        sourceWidthMm: 50,
        sourceHeightMm: 30,
        dpi: 203.2,
        backend: LabelPrintBackend.windowsDriver,
      ),
      pdfSingleFile: true,
    );

    expect(groups.map((group) => group.units.length), [1, 1]);
  });

  test('auto increment separates draft and immediate persistence values', () {
    final row = _row(10, 2);
    final columns = [
      _column(1, autoIncSave: true, autoIncUpdate: false),
      _column(2, autoIncSave: false, autoIncUpdate: true),
      _column(3, autoIncSave: false, autoIncUpdate: false),
      _column(4, autoIncSave: true, autoIncUpdate: true),
    ];
    final contents = <ColumnItemKey, TColumnContent>{
      const ColumnItemKey(columnId: 1, itemId: 10): _content(1, '001'),
      const ColumnItemKey(columnId: 2, itemId: 10): _content(2, '010'),
      const ColumnItemKey(columnId: 3, itemId: 10): _content(3, '100'),
      const ColumnItemKey(columnId: 4, itemId: 10): _content(4, '020'),
    };
    final units = expandLabelPrintUnits(
      [row],
      referenceAt: _referenceAt,
      columns: columns,
      columnContents: contents,
    );

    final plan = buildAcceptedAutoIncrementValuePlan(
      acceptedUnits: units,
      columns: columns,
      columnContents: contents,
      referenceAt: _referenceAt,
    );

    expect(plan.draftValues, {
      const ColumnItemKey(columnId: 1, itemId: 10): '003',
      const ColumnItemKey(columnId: 4, itemId: 10): '022',
    });
    expect(plan.persistenceValues, {
      const ColumnItemKey(columnId: 2, itemId: 10): '011',
      const ColumnItemKey(columnId: 4, itemId: 10): '022',
    });
  });
}

TColumn _column(
  int id, {
  required bool autoIncSave,
  required bool autoIncUpdate,
}) => TColumn(
  columnType: const TColumnType(code: TColumnType.TYPE_BASE, name: '기본', order: 1),
  keyword: 'COL$id', columnName: '항목$id', useMissingKeywordCheck: false,
  useMinColumnCheck: false, columnId: id, labelSizeId: 1, order: id,
  width: 0, height: 0, barcodeType: BarcodeType.Code128,
  useBarcodeCheckDigit: false, showBarcodeNum: true, showQRCodeText: false,
  qrTextAlignment: QRTextAlignment.ALIGN_LEFT, useUserDefineQRData: false,
  userDefineQRData: '', userDefineQRText: '', pixelSize: 0, title: '',
  visible: true, qrCodeCreateType: QRCodeCreateType.QRCODE_TYPE_PLAIN_TEXT,
  natriumJoinString: '', qrTextFontSize: 10, qrTextFontName: '',
  qrCodeScalePercent: 100, timeBarcodeType: 0, autoInc: true,
  autoIncSize: 1, autoIncSave: autoIncSave, autoIncRange: 3,
  autoIncZeroDel: false, autoIncUpdate: autoIncUpdate, searchPrint: false,
  userDefineBarcodeText: '', lineCheck: 0, lineSize: 0, gs1ai: '01',
  formatOption: -1, useGS1Code: false, containColumns: '', showGS1Code: false,
  rotate: 0, useDateRange: false, dateRange: '',
);

TColumnContent _content(int columnId, String value) => TColumnContent(
  colContentId: columnId,
  columnId: columnId,
  itemId: 10,
  editable: true,
  dataString: value,
);

LabelPrintRowDraft _row(int itemId, int copies) {
  final source = ItemOfMarket(
    marketId: 1,
    item: Item(
      itemId: itemId,
      labelSizeId: 1,
      itemName: '품목 $itemId',
      labelSizeName: '중형',
      element: '',
      elementRTF: '',
      price: 0,
      order: itemId,
    ),
    additionalItem: AdditionalItem(
      AdditionalItemId: 0,
      itemId: itemId,
      element: '',
      elementRTF: '',
      price: 0,
    ),
    gdsNo: 0,
    dateSaleStart: DateTime(2026),
    dateSaleEnd: DateTime(2026),
    discountPercent: 0,
    discountAmount: 0,
    dateStartDiscount: DateTime(2026),
    dateEndDiscount: DateTime(2026),
    useDefineElement: false,
    rtfText: '',
    useLinefeed: false,
    linefeed: 0,
    useScaleBarcode: false,
    printCount: copies,
    useLabelSize: false,
    labelSizeWidth: 0,
    labelSizeHeight: 0,
    useMargin: false,
    leftMargin: 0,
    rightMargin: 0,
    topMargin: 0,
    leftPush: 0,
    topPush: 0,
  );
  return LabelPrintRowDraft.fromBaseline(
    item: source,
    labelSize: const LabelSize(
      labelSizeId: 1,
      brandId: 1,
      labelSizeName: '중형',
      labelSizeCommon: LabelSizeCommon(width: 60, height: 40, rtf: ''),
    ),
    copies: copies,
    settings: const LabelPrintSettingsSnapshot.empty(),
  );
}

final _referenceAt = DateTime(2026, 7, 16, 12, 34, 56);