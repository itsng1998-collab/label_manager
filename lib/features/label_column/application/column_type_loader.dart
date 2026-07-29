import 'package:label_manager/core/app.dart';
import 'package:label_manager/features/label_column/data/column_type_dao.dart';
import 'package:label_manager/features/label_column/domain/column_type.dart';
import 'package:label_manager/utils/log_context.dart';

Future<void> initializeColumnTypes() async {
  try {
    debugLog(START);
    if (TColumnType.datas != null) return;
    TColumnType.datas = await ColumnTypeDAO.selectAll();
  } catch (error) {
    throw Exception(error);
  } finally {
    debugLog(END);
  }
}
