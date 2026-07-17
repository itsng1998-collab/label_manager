import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/models/label_column_candidates.dart';
import 'package:label_manager/models/label_column_edit.dart';
import 'package:label_manager/models/label_column_save.dart';
import 'package:label_manager/database/drivers/db_driver.dart';

const _baseType = TColumnType(
  code: TColumnType.TYPE_BASE,
  name: '기본',
  order: 1,
);

TColumn _column(int id, String keyword, {int order = 1}) => TColumn(
  columnType: _baseType,
  keyword: keyword,
  columnName: keyword,
  useMissingKeywordCheck: false,
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

LabelColumnSaveCommand _command() {
  final existing = LabelColumnDraft.fromColumn(
    _column(7, 'PRICE').copyWith(columnName: '판매가'),
  );
  final added = LabelColumnDraft.fromCandidate(
    draftKey: 'draft:new',
    labelSizeId: 10,
    order: 2,
    columnType: _baseType,
    keyword: 'LOT',
    columnName: '로트',
  );
  return LabelColumnSaveCommand(
    labelSizeId: 10,
    originalColumnsById: {
      7: LabelColumnDraft.fromColumn(_column(7, 'PRICE')),
      9: LabelColumnDraft.fromColumn(_column(9, 'OLD')),
    },
    newColumns: [added],
    updatedColumns: [existing],
    changedKeysByColumnId: const {
      7: {'name'},
    },
    deletedColumnIds: const {9},
    orderedKeys: const ['column:7', 'draft:new'],
  );
}

LabelColumnSaveCommand _copyCommand(
  LabelColumnSaveCommand command, {
  Map<int, LabelColumnDraft>? originalColumnsById,
  List<LabelColumnDraft>? updatedColumns,
  Map<int, Set<String>>? changedKeysByColumnId,
  Set<int>? deletedColumnIds,
  List<String>? orderedKeys,
}) {
  return LabelColumnSaveCommand(
    labelSizeId: command.labelSizeId,
    originalColumnsById:
        originalColumnsById ?? command.originalColumnsById,
    newColumns: command.newColumns,
    updatedColumns: updatedColumns ?? command.updatedColumns,
    changedKeysByColumnId:
        changedKeysByColumnId ?? command.changedKeysByColumnId,
    deletedColumnIds: deletedColumnIds ?? command.deletedColumnIds,
    orderedKeys: orderedKeys ?? command.orderedKeys,
  );
}

const _none = LabelColumnSchemaCapabilities(
  hasCoreSchema: true,
  hasMainMissingKeywordCheck: false,
  hasContentEditable: false,
  hasUpdateContent: false,
  hasStatusData: false,
);

void main() {
  group('LabelColumnSaveDao', () {
    test('capability query is read-only metadata only', () {
      final sql = LabelColumnSaveDao.capabilitySql.toUpperCase();

      expect(sql, contains('OBJECT_ID'));
      expect(sql, contains('COL_LENGTH'));
      expect(sql, isNot(contains('CREATE ')));
      expect(sql, isNot(contains('ALTER ')));
      expect(sql, isNot(contains('DROP ')));
    });

    test('builds one returnsRows XML transaction statement', () {
      final statement = LabelColumnSaveDao.buildSaveStatement(_command(), _none);

      expect(statement.returnsRows, isTrue);
      expect(statement.params.keys, ['commandXml']);
      final xml = statement.params['commandXml'] as String;
      expect(xml, startsWith('<command labelSizeId="10">'));
      expect(
        RegExp(r'<column section="originalColumns"').allMatches(xml),
        hasLength(2),
      );
      expect(xml, contains('<changedKeys><key value="name" /></changedKeys>'));
      expect(
        xml,
        contains('<entry order="2"><draftKey>draft:new</draftKey></entry>'),
      );
      expect(
        statement.sql,
        contains("@CommandDocument.nodes('/command/updatedColumns/column')"),
      );
      expect(statement.sql, contains('CHANGED_KEYS.exist('));
      expect(statement.sql, isNot(contains('OPENJSON')));
      expect(statement.sql, isNot(contains('JSON_VALUE')));
      expect(statement.sql, isNot(contains('TRY_CONVERT')));
      expect(statement.sql, isNot(contains('STRING_SPLIT')));
      expect(
        statement.sql,
        contains('Label columns changed after editing started.'),
      );
      expect(
        statement.sql,
        contains('BM_RICH_COLUMN C WITH (UPDLOCK, HOLDLOCK)'),
      );
      expect(
        statement.sql,
        contains('BM_RICH_CHECK_COLUMNS C WITH (UPDLOCK, HOLDLOCK)'),
      );
      expect(
        statement.sql,
        contains('@LockedColumnId=G.COLUMN_ID'),
      );
      expect(
        statement.sql,
        contains('@LockedColumnId=G.MAIN_COLUMN_ID'),
      );
      expect(
        statement.sql,
        contains('Label column auxiliary values changed after editing started.'),
      );
      final originalProjection = statement.sql.substring(
        statement.sql.indexOf('INSERT @OriginalColumns'),
        statement.sql.indexOf('DECLARE @FinalOrder'),
      );
      expect(
        RegExp(
          r"N\.value\('\(useUserQrData/text\(\)\)\[1\]', 'BIT'\)",
        ).allMatches(originalProjection),
        hasLength(1),
      );
      for (final field in [
        "N.value('(check/text())[1]', 'BIT')",
        "N.value('string((gs1ai/text())[1])', 'NVARCHAR(100)')",
        "N.value('(formatOption/text())[1]', 'INT')",
        "N.value('string((contains/text())[1])', 'NVARCHAR(MAX)')",
        "N.value('(showGs1/text())[1]', 'BIT')",
      ]) {
        expect(originalProjection, contains(field));
      }
      expect(
        statement.sql,
        contains('COALESCE(RICH_AUTO_INC, 0)'),
      );
      expect(
        statement.sql,
        contains("COALESCE(CONVERT(NVARCHAR(MAX), RICH_DATERANGE), N'')"),
      );
    });

    test('builds label and customer saves in one transaction statement list', () {
      final customerCommand = CustomerColumnEditSession.fromCandidates(
        customerId: 7,
        candidates: const [],
      ).add(
        CustomerColumnDraft.empty(
          key: 'customer-draft:1',
          customerId: 7,
          columnType: _baseType,
        ).copyWith(keyword: 'CUSTOM1', columnName: '사용자 항목'),
      ).toSaveCommand();
      final statements = LabelColumnSaveDao.buildDialogSaveStatements(
        LabelColumnDialogSaveCommand(
          labelSizeId: 10,
          customerId: 7,
          labelColumns: _command(),
          customerColumns: customerCommand,
        ),
        _none,
      );

      expect(statements, hasLength(2));
      expect(statements.first.returnsRows, isTrue);
      expect(statements.last.returnsRows, isFalse);
      expect(statements.first.params, contains('commandXml'));
      expect(statements.last.params, contains('newColumnsXml'));
      expect(statements.last.params, contains('originalColumnsXml'));
      expect(
        statements.last.sql,
        contains('Customer columns changed after editing started.'),
      );
      expect(
        statements.last.sql,
        contains('BM_RICH_CUST_COLUMN C WITH (UPDLOCK, HOLDLOCK)'),
      );
      expect(
        statements.last.sql,
        contains("COALESCE(CONVERT(NVARCHAR(MAX), RICH_KEYWORD), N'')"),
      );
    });

    test('rejects dialog command ownership mismatches', () {
      final customerCommand = CustomerColumnEditSession.fromCandidates(
        customerId: 7,
        candidates: const [],
      ).toSaveCommand();

      expect(
        () => LabelColumnSaveDao.buildDialogSaveStatements(
          LabelColumnDialogSaveCommand(
            labelSizeId: 11,
            customerId: 7,
            labelColumns: _command(),
            customerColumns: null,
          ),
          _none,
        ),
        throwsStateError,
      );
      expect(
        () => LabelColumnSaveDao.buildDialogSaveStatements(
          LabelColumnDialogSaveCommand(
            labelSizeId: 10,
            customerId: 8,
            labelColumns: null,
            customerColumns: customerCommand,
          ),
          null,
        ),
        throwsStateError,
      );
    });

    test('rejects a dialog command without changes', () {
      expect(
        () => LabelColumnSaveDao.buildDialogSaveStatements(
          const LabelColumnDialogSaveCommand(
            labelSizeId: 10,
            customerId: 7,
            labelColumns: null,
            customerColumns: null,
          ),
          null,
        ),
        throwsArgumentError,
      );
    });

    test('rejects malformed original and final order identity sets', () {
      final command = _command();
      final foreignOriginal = LabelColumnDraft.fromColumn(
        _column(7, 'PRICE').copyWith(labelSizeId: 11),
      );

      for (final invalid in [
        _copyCommand(command, originalColumnsById: {7: foreignOriginal}),
        _copyCommand(command, orderedKeys: const ['draft:new']),
        _copyCommand(
          command,
          orderedKeys: const ['column:7', 'column:8', 'draft:new'],
        ),
        _copyCommand(command, deletedColumnIds: const {8, 9}),
      ]) {
        expect(
          () => LabelColumnSaveDao.buildSaveStatement(invalid, _none),
          throwsStateError,
        );
      }
    });

    test('converts unknown commit outcome and skips reload', () async {
      var reloaded = false;
      final command = LabelColumnDialogSaveCommand(
        labelSizeId: 10,
        customerId: 7,
        labelColumns: _command(),
        customerColumns: null,
      );

      await expectLater(
        LabelColumnSaveDao.saveDialogAndReload(
          command,
          save: (_) async => throw const DbCommitOutcomeUnknown('unknown'),
          reload: () async {
            reloaded = true;
            return true;
          },
        ),
        throwsA(
          isA<LabelColumnSaveCommittedException>().having(
            (error) => error.outcomeUnknown,
            'outcomeUnknown',
            isTrue,
          ),
        ),
      );
      expect(reloaded, isFalse);
    });

    test('converts reload failure after a successful save', () async {
      var saved = false;
      final command = LabelColumnDialogSaveCommand(
        labelSizeId: 10,
        customerId: 7,
        labelColumns: _command(),
        customerColumns: null,
      );

      await expectLater(
        LabelColumnSaveDao.saveDialogAndReload(
          command,
          save: (_) async => saved = true,
          reload: () async => false,
        ),
        throwsA(
          isA<LabelColumnSaveCommittedException>().having(
            (error) => error.outcomeUnknown,
            'outcomeUnknown',
            isFalse,
          ),
        ),
      );
      expect(saved, isTrue);
    });

    test('uses OUTPUT mapping and never guesses the last inserted rows', () {
      final sql = LabelColumnSaveDao.buildSaveStatement(_command(), _none).sql;

      expect(
        sql,
        contains('OUTPUT INSERTED.RICH_COLUMN_ID INTO @OneInserted'),
      );
      expect(sql, contains('SELECT DRAFT_KEY, COLUMN_ID FROM @InsertedRows'));
      expect(sql, contains('Inserted column mapping count mismatch.'));
      expect(sql.toUpperCase(), isNot(contains('SELECTLASTNRECORD')));
      expect(sql.toUpperCase(), isNot(contains('TOP (@ROWCOUNT)')));
      expect(sql.toUpperCase(), isNot(contains('BEGIN TRANSACTION')));
      expect(sql.toUpperCase(), isNot(contains('COMMIT TRANSACTION')));
    });

    test('absent optional variant omits every optional identifier', () {
      final sql = LabelColumnSaveDao.buildSaveStatement(_command(), _none).sql;

      expect(sql, isNot(contains('RICH_USE_MISSING_KEYWORD_CHECK')));
      expect(sql, isNot(contains('RICH_EDITABLE')));
      expect(sql, isNot(contains('BM_UPDATE_ITEM')));
      expect(sql, isNot(contains('BM_UPDATE_COL_CONTENT')));
      expect(sql, isNot(contains('BM_RICH_STATUS_DATA')));
    });

    test('present optional variant includes supported optional operations', () {
      const all = LabelColumnSchemaCapabilities(
        hasCoreSchema: true,
        hasMainMissingKeywordCheck: true,
        hasContentEditable: true,
        hasUpdateContent: true,
        hasStatusData: true,
      );
      final sql = LabelColumnSaveDao.buildSaveStatement(_command(), all).sql;

      expect(sql, contains('RICH_USE_MISSING_KEYWORD_CHECK'));
      expect(
        sql,
        contains('Main missing-keyword value changed after editing started.'),
      );
      expect(sql, contains('RICH_EDITABLE'));
      expect(sql, contains('BM_UPDATE_ITEM'));
      expect(sql, contains('BM_UPDATE_COL_CONTENT'));
      expect(sql, contains('BM_RICH_STATUS_DATA'));
      expect(sql, contains('RICH_COLID_CHANGE_DELETE_DATE=GETDATE()'));
    });

    test('covers check min content GS1 delete order and affected validation', () {
      final sql = LabelColumnSaveDao.buildSaveStatement(_command(), _none).sql;

      expect(sql, contains('BM_RICH_CHECK_COLUMNS'));
      expect(sql, contains("'ELEMENT', N'주원료', 0, 0"));
      expect(sql, contains('BM_RICH_COL_MIN'));
      expect(sql, contains('BM_RICH_COL_CONTENT'));
      expect(sql, contains('BM_GS1_COLUMN_INFO'));
      expect(sql, contains('BM_GS1_CONTAIN_COLUMN'));
      expect(sql, contains('CONTAIN_COLUMN_ID'));
      expect(sql, contains('RICH_COLUMN_ORDER=O.RICH_COLUMN_ORDER'));
      expect(sql, contains('Column ownership validation failed.'));
      expect(sql, contains('IF @@ROWCOUNT <>'));
      expect(sql, contains('Deleted column count mismatch.'));
      expect(sql, contains('Final column order count mismatch.'));
    });

    test('decodes mapping and rejects missing or conflicting mapping', () {
      final result = LabelColumnSaveDao.decodeSaveResult(
        {
          'rows': [
            {'DRAFT_KEY': 'draft:new', 'COLUMN_ID': 31},
          ],
        },
        expectedMappingCount: 1,
      );
      expect(result.columnIdsByDraftKey, {'draft:new': 31});

      expect(
        () => LabelColumnSaveDao.decodeSaveResult(
          const {'rows': []},
          expectedMappingCount: 1,
        ),
        throwsStateError,
      );
      expect(
        () => LabelColumnSaveDao.decodeSaveResult(
          const {
            'rows': [
              {'DRAFT_KEY': 'draft:new', 'COLUMN_ID': 31},
              {'DRAFT_KEY': 'draft:new', 'COLUMN_ID': 32},
            ],
          },
          expectedMappingCount: 1,
        ),
        throwsStateError,
      );
    });

    test('rejects unsupported core schema before building save SQL', () {
      const unsupported = LabelColumnSchemaCapabilities(
        hasCoreSchema: false,
        hasMainMissingKeywordCheck: false,
        hasContentEditable: false,
        hasUpdateContent: false,
        hasStatusData: false,
      );

      expect(
        () => LabelColumnSaveDao.buildSaveStatement(_command(), unsupported),
        throwsStateError,
      );
    });
  });
}