import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/login_history/data/login_log_dao.dart';
import 'package:label_manager/features/last_connect/data/last_connect_dao.dart';
import 'package:label_manager/models/dao.dart';
import 'package:label_manager/features/label_size/data/label_size_dao.dart';

void main() {
  group('DAO result helpers', () {
    final resultMap = <String, dynamic>{
      'columns': ['ID', 'NAME'],
      'rows': [
        {'ID': 1, 'NAME': 'Alpha'},
      ],
      'affected': 0,
    };

    test('read rows directly from structured isolate result maps', () {
      final rows = DAO.getRowsFromResult(resultMap);

      expect(rows, hasLength(1));
      expect(rows.single, {'ID': 1, 'NAME': 'Alpha'});
    });

    test(
      'map structured result rows without model-level fromPipeLines helpers',
      () {
        final names = DAO.mapRows(resultMap, (row) => row['NAME'] as String);
        final row = DAO.mapRow(resultMap, (row) => row['ID'] as int);
        final byId = DAO.mapRowsByKey(
          resultMap,
          (row) => row['NAME'] as String,
          (name) => name.length,
        );

        expect(names, ['Alpha']);
        expect(row, 1);
        expect(byId, {5: 'Alpha'});
      },
    );

    test('keep compatibility with JSON string driver results', () {
      final rows = DAO.getRowsFromResult(jsonEncode(resultMap));
      final row = DAO.getRowMapFromResult(jsonEncode(resultMap));

      expect(rows.single, {'ID': 1, 'NAME': 'Alpha'});
      expect(row, {'ID': 1, 'NAME': 'Alpha'});
    });

    test('return empty collections for empty list query results', () {
      final emptyResult = <String, dynamic>{
        'columns': ['ID', 'NAME'],
        'rows': <Map<String, dynamic>>[],
        'affected': 0,
      };

      final rows = DAO.getRowsFromResult(emptyResult);
      final names = DAO.mapRows(emptyResult, (row) => row['NAME'] as String);
      final byId = DAO.mapRowsByKey(
        emptyResult,
        (row) => row['NAME'] as String,
        (name) => name.length,
      );

      expect(rows, isEmpty);
      expect(names, isEmpty);
      expect(byId, isEmpty);
      expect(
        () => DAO.getRowMapFromResult(emptyResult),
        throwsA(isA<StateError>()),
      );
      expect(
        DAO.getRowMapFromResult(emptyResult, throwIfNoRows: false),
        isNull,
      );
    });
  });

  group('LabelSizeDAO sheet storage SQL', () {
    test('loads sheet data before falling back to RTF data', () {
      expect(
        LabelSizeDAO.SelectSql,
        contains(
          "COALESCE(NULLIF(RICH_FORM_SHEET, ''), RICH_FORM_DATA) AS FORM_DATA",
        ),
      );
    });

    test('saves edited label sheets to the sheet column', () {
      expect(
        LabelSizeDAO.UpdateFormDataSql,
        contains('RICH_FORM_SHEET=@formData'),
      );
      expect(
        LabelSizeDAO.UpdateFormDataSql,
        isNot(contains('RICH_FORM_DATA=@formData')),
      );
    });

    test('logs previous and altered sheet data', () {
      expect(LabelSizeDAO.UpdateFormDataLogSql, contains('RICH_FORM_SHEET'));
      expect(
        LabelSizeDAO.UpdateFormDataLogSql,
        contains('RICH_ALTER_FORM_SHEET'),
      );
      expect(
        LabelSizeDAO.UpdateFormDataLogSql,
        contains('RICH_FORM_SHEET, @width'),
      );
      expect(
        LabelSizeDAO.UpdateFormDataLogSql,
        contains('RICH_FORM_DATA, @formData'),
      );
    });

    test('decodes hex local IP before writing the save log', () {
      expect(
        LabelSizeDAO.UpdateFormDataLogSql,
        contains('CONVERT(VARBINARY(100), @loginIP, 1)'),
      );
      expect(
        LabelSizeDAO.UpdateFormDataLogSql,
        isNot(contains('RICH_BRAND_ID, @loginIP')),
      );
      expect(
        LabelSizeDAO.UpdateFormDataLogSql,
        contains('CONVERT(VARCHAR(100), CONVERT(VARBINARY(100), @loginIP, 1))'),
      );
      expect(
        LabelSizeDAO.UpdateFormDataLogSql,
        contains("CONVERT(VARCHAR(48), CONNECTIONPROPERTY('client_net_address'))"),
      );
      expect(LabelSizeDAO.UpdateFormDataLogSql, isNot(contains('char(15)')));
    });

    test('returns explicit affected rows from save transaction for ODBC', () {
      expect(LabelSizeDAO.UpdateFormDataTransactionSql, contains('SET NOCOUNT ON'));
      expect(
        LabelSizeDAO.UpdateFormDataTransactionSql,
        contains('SELECT @updateAffected AS AFFECTED'),
      );
      expect(
        LabelSizeDAO.UpdateFormDataTransactionSql,
        contains('SET @logAffected = @@ROWCOUNT'),
      );
      expect(
        LabelSizeDAO.UpdateFormDataTransactionSql,
        contains('SET @updateAffected = @@ROWCOUNT'),
      );
    });
  });

  group('LoginLogDAO SQL', () {
    test('does not truncate IP expressions before insert', () {
      expect(
        LoginLogDAO.insertSql,
        contains('CONVERT(VARCHAR(100), CONVERT(VARBINARY(100), @loginIP, 1))'),
      );
      expect(
        LoginLogDAO.insertSql,
        contains("CONVERT(VARCHAR(48), CONNECTIONPROPERTY('client_net_address'))"),
      );
      expect(LoginLogDAO.insertSql, isNot(contains('CONVERT(VARCHAR(32)')));
      expect(LoginLogDAO.insertSql, isNot(contains('CONVERT(VARCHAR(15)')));
    });
  });

  group('LastConnectDAO SQL and mapping', () {
    test('maps DB row values to last selected brand and label size', () {
      final lastConnect = lastConnectFromRow({
        'USER_ID': 'user01',
        'BRAND_ID': '12',
        'LABELSIZE_ID': '34',
      });

      expect(lastConnect.userId, 'user01');
      expect(lastConnect.brandId, 12);
      expect(lastConnect.labelSizeId, 34);
    });

    test('uses parameterized user, brand, and label size SQL', () {
      expect(LastConnectDAO.whereSqlUserId, contains('@userId'));
      expect(LastConnectDAO.deleteSqlByBrandId, contains('@brandId'));
      expect(
        LastConnectDAO.deleteSqlByLabelSizeId,
        contains('@labelSizeId'),
      );
    });
  });
}
