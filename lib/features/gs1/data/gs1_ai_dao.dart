import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/features/gs1/domain/gs1_ai_definition.dart';
import 'package:label_manager/models/dao.dart';

Gs1AiDefinition gs1AiDefinitionFromRow(Map<String, dynamic> row) {
  int number(String key) {
    final value = row[key];
    return value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  }

  return Gs1AiDefinition(
    code: '${row['GS1_AI_CODE'] ?? ''}',
    name: '${row['GS1_AI_NAME'] ?? ''}',
    content: '${row['GS1_AI_CONTENT'] ?? ''}',
    dataFormat: '${row['GS1_DATA_FORMAT'] ?? ''}',
    dataFormatType: number('GS1_DATA_FORMAT_TYPE'),
    needsFnc1: number('GS1_NEED_FNC1') != 0,
  );
}

class Gs1AiDAO {
  const Gs1AiDAO._();

  static const selectSql = '''
SELECT
  GS1_AI_CODE,
  GS1_AI_NAME,
  GS1_AI_CONTENT,
  GS1_DATA_FORMAT,
  GS1_DATA_FORMAT_TYPE,
  GS1_NEED_FNC1
FROM BM_GS1_AI
''';

  static Future<List<Gs1AiDefinition>> selectAll() async {
    final result = await DbClient.instance.getData(selectSql);
    return DAO.mapRows(result, gs1AiDefinitionFromRow);
  }
}
