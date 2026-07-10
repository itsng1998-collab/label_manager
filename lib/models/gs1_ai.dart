import 'package:flutter/foundation.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/models/dao.dart';

@immutable
class Gs1AiDefinition {
  const Gs1AiDefinition({
    required this.code,
    required this.name,
    required this.content,
    required this.dataFormat,
    required this.dataFormatType,
    required this.needsFnc1,
  });

  factory Gs1AiDefinition.fromMap(Map<String, dynamic> map) {
    int number(String key) {
      final value = map[key];
      return value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    }

    return Gs1AiDefinition(
      code: '${map['GS1_AI_CODE'] ?? ''}',
      name: '${map['GS1_AI_NAME'] ?? ''}',
      content: '${map['GS1_AI_CONTENT'] ?? ''}',
      dataFormat: '${map['GS1_DATA_FORMAT'] ?? ''}',
      dataFormatType: number('GS1_DATA_FORMAT_TYPE'),
      needsFnc1: number('GS1_NEED_FNC1') != 0,
    );
  }

  final String code;
  final String name;
  final String content;
  final String dataFormat;
  final int dataFormatType;
  final bool needsFnc1;
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
    return DAO.mapRows(result, Gs1AiDefinition.fromMap);
  }
}

class Gs1AiDefinitions {
  const Gs1AiDefinitions._();

  static Map<String, Gs1AiDefinition> values = const {};

  static void set(Iterable<Gs1AiDefinition> definitions) {
    values = Map.unmodifiable({
      for (final definition in definitions) definition.code: definition,
    });
  }
}