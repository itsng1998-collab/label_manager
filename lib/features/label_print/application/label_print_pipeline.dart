import 'package:flutter/foundation.dart';
import 'package:label_manager/features/label_column/domain/column.dart';
import 'package:label_manager/features/item/domain/column_content.dart';
import 'package:label_manager/features/label_print/domain/label_print.dart';
import 'package:label_manager/features/label_print/domain/label_print_auto_increment.dart';
import 'package:label_manager/printing/label_print_dispatcher.dart';
import 'package:label_manager/printing/label_sheet_print_job.dart';

@immutable
class LabelPhysicalPageSpec {
  const LabelPhysicalPageSpec({
    required this.widthMm,
    required this.heightMm,
    required this.sourceWidthMm,
    required this.sourceHeightMm,
    required this.dpi,
    required this.backend,
  });

  final int widthMm;
  final int heightMm;
  final double sourceWidthMm;
  final double sourceHeightMm;
  final double dpi;
  final LabelPrintBackend backend;

  @override
  bool operator ==(Object other) =>
      other is LabelPhysicalPageSpec &&
      widthMm == other.widthMm &&
      heightMm == other.heightMm &&
      sourceWidthMm == other.sourceWidthMm &&
      sourceHeightMm == other.sourceHeightMm &&
      dpi == other.dpi &&
      backend == other.backend;

  @override
  int get hashCode => Object.hash(
    widthMm,
    heightMm,
    sourceWidthMm,
    sourceHeightMm,
    dpi,
    backend,
  );
}

@immutable
class LabelPrintJobGroup {
  const LabelPrintJobGroup({required this.pageSpec, required this.units});

  final LabelPhysicalPageSpec pageSpec;
  final List<LabelPrintUnit> units;
}

List<LabelPrintUnit> expandLabelPrintUnits(
  List<LabelPrintRowDraft> rows, {
  required DateTime referenceAt,
  List<TColumn> columns = const <TColumn>[],
  Map<ColumnItemKey, TColumnContent> columnContents =
      const <ColumnItemKey, TColumnContent>{},
}) => [
  for (var rowIndex = 0; rowIndex < rows.length; rowIndex += 1)
    for (var copyIndex = 0;
        copyIndex < rows[rowIndex].copies;
        copyIndex += 1)
      LabelPrintUnit(
        row: rows[rowIndex],
        rowIndex: rowIndex,
        copyIndex: copyIndex,
        projectedColumnValues: projectLabelPrintColumnValues(
          itemId: rows[rowIndex].item.item.itemId,
          copyIndex: copyIndex,
          columns: columns,
          columnContents: columnContents,
          referenceAt: referenceAt,
        ),
      ),
];

String? validateLabelPrintRows({
  required List<LabelPrintRowDraft> rows,
  required LabelPrintSettingsSnapshot settings,
  required double sourceWidthMm,
  required double sourceHeightMm,
  required double dpi,
}) {
  if (settings.printerName?.trim().isEmpty ?? true) {
    return '발행할 프린터를 선택하세요.';
  }
  if (!settings.extraAreaMm.isFinite || settings.extraAreaMm < 0) {
    return '추가 영역 값이 올바르지 않습니다.';
  }
  if (rows.fold<int>(0, (sum, row) => sum + row.copies) < 1) {
    return '전체 발행매수는 1 이상이어야 합니다.';
  }
  for (final row in rows) {
    if (row.copies == 0) continue;
    if (row.copies < 0 || row.widthMm <= 0 || row.heightMm <= 0) {
      return '${row.item.item.itemName}의 출력 크기 또는 발행매수를 확인해 주세요.';
    }
    final metrics = LabelSheetPrintPageMetrics(
      labelWidthMm: row.widthMm,
      labelHeightMm: row.heightMm,
      sourceWidthMm: sourceWidthMm,
      sourceHeightMm: sourceHeightMm,
      dpi: dpi,
    );
    final options = LabelSheetPrintOptions(
      copies: row.copies,
      leftMarginMm: row.leftMarginMm,
      rightMarginMm: row.rightMarginMm,
      topMarginMm: row.topMarginMm,
      leftPushMm: row.leftPushMm,
      topPushMm: row.topPushMm,
      extraAreaMm: settings.extraAreaMm,
      autoSpacingPercent: row.lineSpacingPercent,
      orientation: settings.orientation == LabelPrintOrientation.vertical
          ? LabelSheetPrintOrientation.vertical
          : LabelSheetPrintOrientation.horizontal,
    );
    if (!LabelSheetPrintLayout.resolve(
      metrics: metrics,
      options: options,
    ).hasContentIntersection) {
      return '${row.item.item.itemName}의 출력 영역과 라벨 영역이 겹치지 않습니다.';
    }
  }
  return null;
}

List<LabelPrintJobGroup> groupAdjacentLabelPrintUnits(
  List<LabelPrintUnit> units,
  LabelPhysicalPageSpec Function(LabelPrintUnit unit) specFor,
) {
  final groups = <LabelPrintJobGroup>[];
  for (final unit in units) {
    final spec = specFor(unit);
    if (groups.isNotEmpty && groups.last.pageSpec == spec) {
      final previous = groups.removeLast();
      groups.add(
        LabelPrintJobGroup(
          pageSpec: spec,
          units: List.unmodifiable([...previous.units, unit]),
        ),
      );
    } else {
      groups.add(
        LabelPrintJobGroup(pageSpec: spec, units: List.unmodifiable([unit])),
      );
    }
  }
  return List.unmodifiable(groups);
}