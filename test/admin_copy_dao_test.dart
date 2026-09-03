import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/admin_copy/data/admin_copy_dao.dart';
import 'package:label_manager/features/admin_copy/domain/admin_copy.dart';

void main() {
  test('normal copy keeps exact legacy delete and copy scope', () {
    final sql = AdminCopyDAO.copyLabelSizeSql;
    expect(sql, contains('DELETE FROM BM_GS1_COLUMN_INFO'));
    expect(sql, contains('DELETE FROM BM_RICH_COLUMN'));
    expect(sql, contains('DELETE FROM BM_RICH_COL_MIN'));
    expect(sql, contains('DELETE FROM BM_RICH_CHECK_COLUMNS'));
    expect(sql, contains('RICH_ID_CHANGE_DELETE_DATE=GETDATE()'));
    expect(sql, contains('DELETE FROM BM_RICH_ITEM'));
    expect(sql, isNot(contains('BM_GS1_CONTAIN_COLUMN')));
    expect(sql, isNot(contains('BM_RICH_STATUS_DATA')));
    expect(sql, contains("COALESCE(NULLIF(S.RICH_FORM_SHEET, ''), S.RICH_FORM_DATA)"));
  });

  test('column copy excludes related min check and GS1 tables', () {
    final sql = AdminCopyDAO.copyLabelSizeSql;
    expect(sql, contains('INSERT INTO BM_RICH_COLUMN'));
    expect(sql, isNot(contains('INSERT INTO BM_RICH_COL_MIN')));
    expect(sql, isNot(contains('INSERT INTO BM_RICH_CHECK_COLUMNS')));
    expect(sql, isNot(contains('INSERT INTO BM_GS1_COLUMN_INFO')));
  });

  test('item copy keeps verified legacy order without legacy database dependency', () {
    for (final sql in [AdminCopyDAO.copyLabelSizeSql, AdminCopyDAO.copyBrandSql]) {
      final item = sql.indexOf('EXEC proc_copy_item ');
      final content = sql.indexOf('EXEC proc_copy_item_content');
      final market = sql.indexOf('INSERT INTO BM_ITEM_OF_MARKET');
      expect(item, greaterThanOrEqualTo(0));
      expect(content, greaterThan(item));
      expect(market, greaterThan(content));
      expect(sql, isNot(contains('EXEC proc_copy_item_of_market')));
      expect(sql, isNot(contains('[labelmanager_combine]')));
      expect(sql, contains('INNER JOIN BM_ITEM_OF_MARKET M'));
    }
  });

  test('brand copy uses output mappings without last-row fallback', () {
    final sql = AdminCopyDAO.copyBrandSql;
    expect(sql, contains('OUTPUT INSERTED.RICH_BRAND_ID'));
    expect(sql, contains('OUTPUT INSERTED.RICH_LABELSIZE_ID'));
    expect(sql, contains('DECLARE @SizeMap TABLE'));
    expect(sql, contains('ORDER BY RICH_LABELSIZE_ORDER ASC'));
    expect(sql, isNot(contains('MAX(RICH_BRAND_ID)')));
    expect(sql, isNot(contains('MAX(RICH_LABELSIZE_ID)')));
    expect(sql, isNot(contains('BEGIN TRANSACTION')));
    expect(sql, isNot(contains('COMMIT TRANSACTION')));
  });

  test('item copy requires preflight target market', () async {
    await expectLater(
      AdminCopyDAO.copyLabelSize(
        const AdminLabelSizeCopyCommand(
          sourceLabelSizeId: 1,
          targetLabelSizeId: 2,
          overwriteExisting: false,
          copyItems: true,
        ),
      ),
      throwsStateError,
    );
  });
}