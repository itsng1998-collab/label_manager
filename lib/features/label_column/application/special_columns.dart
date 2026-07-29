import 'package:label_manager/features/label_column/data/special_column_dao.dart';
import 'package:label_manager/features/label_column/domain/column_base.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/features/label_column/domain/special_keyword.dart';

class TColumnSpecial {
  static List<TColumnBase>? datas;

  static Future<List<TColumnBase>?> selectByLabelSizeId(int labelSizeId) =>
      SpecialColumnDAO.selectByLabelSizeId(labelSizeId);

  static Future<void> updateElementMinColumnCheck({
    required int labelSizeId,
    required bool checked,
  }) async {
    await SpecialColumnDAO.updateElementMinColumnCheck(
      labelSizeId: labelSizeId,
      checked: checked,
    );
    final element = datas?.firstWhere(
      (column) => column.keyword == SpecalKeyword.INDEX_ELEMENT.keyword,
      orElse: () => TColumnBase(
        columnType: TColumnType.getFromCode(TColumnType.TYPE_FIX),
        keyword: SpecalKeyword.INDEX_ELEMENT.keyword,
        columnName: SpecalKeyword.INDEX_ELEMENT.columnName,
      ),
    );
    if (element != null) {
      element.useMinColumnCheck = checked;
    }
  }
}
