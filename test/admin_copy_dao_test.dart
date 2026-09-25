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

  test('item copy uses explicit item and column mappings', () {
    for (final sql in [AdminCopyDAO.copyLabelSizeSql, AdminCopyDAO.copyBrandSql]) {
      final item = sql.indexOf('OUTPUT INSERTED.RICH_ITEM_ID');
      final content = sql.indexOf('UPDATE TARGET_CONTENT SET');
      final market = sql.indexOf('INSERT INTO BM_ITEM_OF_MARKET');
      expect(item, greaterThanOrEqualTo(0));
      expect(content, greaterThan(item));
      expect(market, greaterThan(content));
      expect(sql, contains('DECLARE @ItemMap TABLE'));
      expect(sql, contains('DECLARE @ColumnMap TABLE'));
      expect(sql, contains('RICH_COL_CONTENT_DATA NVARCHAR(MAX) NOT NULL'));
      expect(sql, contains('ROW_NUMBER() OVER'));
      expect(sql, contains('OUTPUT INSERTED.RICH_ITEM_ID INTO @CapturedItem'));
      expect(sql, contains('PARTITION BY M.RICH_ITEM_ID'));
      expect(sql, contains('INNER JOIN @ItemMap'));
      expect(sql, contains('INNER JOIN @ColumnMap'));
      expect(sql, isNot(contains('S.RICH_ITEM_ORDER=T.RICH_ITEM_ORDER')));
      expect(sql, isNot(contains('EXEC proc_copy_item ')));
      expect(sql, isNot(contains('EXEC proc_copy_item_content')));
      expect(sql, isNot(contains('EXEC proc_copy_item_of_market')));
      expect(sql, isNot(contains('[labelmanager_combine]')));
      expect(sql, isNot(contains('STRING_AGG')));
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

  test('brand item copy resets mappings for every label size', () {
    final sql = AdminCopyDAO.copyBrandSql;
    final labelSizeLoop = sql.indexOf('WHILE @RowNo<=@RowCount');
    final clearSourceItems = sql.indexOf('DELETE FROM @SourceItems;');
    final loadSourceItems = sql.indexOf(
      'INSERT INTO @SourceItems (SOURCE_ITEM_ID)',
    );

    expect(clearSourceItems, greaterThan(labelSizeLoop));
    expect(clearSourceItems, greaterThanOrEqualTo(0));
    expect(clearSourceItems, lessThan(loadSourceItems));
    expect(sql, contains('DELETE FROM @ItemMap;'));
    expect(sql, contains('DELETE FROM @CapturedItem;'));
    expect(sql, contains('DELETE FROM @ColumnMap;'));
    expect(sql, contains('DELETE FROM @CopiedContent;'));
    expect(
      sql,
      contains(
        'DECLARE @ItemRowNo INT=(SELECT MIN(ROW_NO) FROM @SourceItems);',
      ),
    );
    expect(
      sql,
      contains(
        'DECLARE @ItemRowCount INT=(SELECT MAX(ROW_NO) FROM @SourceItems);',
      ),
    );
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