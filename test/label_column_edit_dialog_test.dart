import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/models/barcode.dart';
import 'package:label_manager/models/column.dart';
import 'package:label_manager/models/column_type.dart';
import 'package:label_manager/models/label_column_candidates.dart';
import 'package:label_manager/models/label_column_edit.dart';
import 'package:label_manager/features/label_column/presentation/label_column_edit_dialog.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/swipe_action_table.dart';

const baseType = TColumnType(code: TColumnType.TYPE_BASE, name: '기본', order: 1);
const barcodeColumnType = TColumnType(
  code: TColumnType.TYPE_BARCODE,
  name: '바코드',
  order: 2,
);
const qrColumnType = TColumnType(
  code: TColumnType.TYPE_QR_CODE,
  name: 'QR 코드',
  order: 3,
);

Future<TestGesture> _startRowDrag(
  WidgetTester tester,
  Finder source,
) async {
  final gesture = await tester.startGesture(tester.getCenter(source));
  await tester.pump(swipeActionTableDragStartDelay);
  return gesture;
}

Future<void> _dragRowTo(
  WidgetTester tester,
  Finder source,
  Finder target,
) async {
  final gesture = await _startRowDrag(tester, source);
  await gesture.moveTo(tester.getCenter(target));
  await gesture.up();
}

TColumn _column(int id, String keyword, {int order = 1}) {
  return TColumn(
    columnType: baseType,
    keyword: keyword,
    columnName: keyword,
    useMissingKeywordCheck: false,
    useMinColumnCheck: false,
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
}

Future<void> _pumpDialog(
  WidgetTester tester, {
  List<TColumn>? columns,
  Future<void> Function(LabelColumnSaveCommand command)? onSave,
  Future<void> Function(CustomerColumnSaveCommand command)? saveCustomer,
  Future<void> Function(LabelColumnDialogSaveCommand command)? onDialogSave,
  Future<List<FixedColumnType>> Function()? loadFixedTypes,
  Future<List<FixedColumnCandidate>> Function(int typeId)? loadFixed,
  Future<List<CustomerColumnCandidate>> Function(int customerId)? loadCustomer,
  VoidCallback? onClose,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LabelColumnEditDialog(
          labelSizeId: 10,
          customerId: 7,
          initialColumns: columns ?? [_column(1, 'BASE_A')],
          canSave: () async => true,
          onSave: (command) async {
            if (onDialogSave != null) {
              await onDialogSave(command);
              return;
            }
            final labelCommand = command.labelColumns;
            if (labelCommand != null) await onSave?.call(labelCommand);
            final customerCommand = command.customerColumns;
            if (customerCommand != null) {
              await saveCustomer?.call(customerCommand);
            }
          },
          onClose: onClose ?? () {},
          loadFixedTypes: loadFixedTypes ??
              () async => const [FixedColumnType(id: 1, name: '공통')],
          loadFixedCandidates: loadFixed ??
              (_) async => const [
                    FixedColumnCandidate(
                      id: 1,
                      typeId: 1,
                      columnType: baseType,
                      keyword: 'FIXED_A',
                      columnName: '고정 A',
                    ),
                    FixedColumnCandidate(
                      id: 2,
                      typeId: 1,
                      columnType: barcodeColumnType,
                      keyword: 'BARCODE_A',
                      columnName: '바코드 A',
                    ),
                  ],
          loadCustomerCandidates: loadCustomer ??
              (_) async => const [
                    CustomerColumnCandidate(
                      id: 11,
                      customerId: 7,
                      columnType: baseType,
                      keyword: 'CUSTOM_A',
                      columnName: '사용자 A',
                    ),
                  ],
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

class _OverlayHost extends StatefulWidget {
  const _OverlayHost({required this.child});

  final Widget child;

  @override
  State<_OverlayHost> createState() => _OverlayHostState();
}

class _OverlayHostState extends State<_OverlayHost> {
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final entry = OverlayEntry(
        builder: (_) => BlockingModelessDialog(child: widget.child),
      );
      _entry = entry;
      Overlay.of(context).insert(entry);
    });
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}

void main() {
  setUp(() {
    TColumnType.datas = [baseType, barcodeColumnType];
  });

  tearDown(() {
    TColumnType.datas = null;
  });

  testWidgets('opens three-area layout and switches fixed/customer candidates', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDialog(tester);

    expect(find.text('라벨 항목 편집'), findsOneWidget);
    expect(find.text('속성'), findsOneWidget);
    expect(find.text('사용 항목'), findsOneWidget);
    expect(find.text('고정 A'), findsOneWidget);
    final appFontSize = Theme.of(
      tester.element(find.byType(Scaffold)),
    ).textTheme.bodyMedium!.fontSize!;
    final dialogFontSize = Theme.of(
      tester.element(find.byKey(const Key('label-column-edit-dialog'))),
    ).textTheme.bodyMedium!.fontSize!;
    expect(dialogFontSize, appFontSize - 1);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.runtimeType.toString().startsWith('SwipeActionTable<'),
      ),
      findsNWidgets(2),
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('label-column-candidate-list')),
        matching: find.text('키워드'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('label-column-candidate-list')),
        matching: find.text('상태'),
      ),
      findsNothing,
    );
    final usedTable = tester.widget(
      find.byKey(const Key('label-column-used-table')),
    ) as dynamic;
    expect(usedTable.rowNumberWidth, 34);
    expect(usedTable.autoFitColumns, isFalse);
    expect(usedTable.fillLastColumn, isTrue);
    expect(
      [for (final column in usedTable.columns) column.initialWidth],
      [44, 78, 75, 71, 58, 44],
    );
    expect(
      usedTable.columns
          .firstWhere((dynamic column) => column.header == '종류')
          .fillRemaining,
      isTrue,
    );
    expect(
      usedTable.columns
          .firstWhere((dynamic column) => column.header == '표시')
          .fillRemaining,
      isFalse,
    );
    final visibleCheckbox = find.descendant(
      of: find.byKey(const Key('label-column-used-table')),
      matching: find.byType(Checkbox),
    );
    expect(visibleCheckbox, findsOneWidget);
    expect(
      tester.widget<Checkbox>(visibleCheckbox).materialTapTargetSize,
      MaterialTapTargetSize.shrinkWrap,
    );
    final candidateTable = tester.widget(
      find.byKey(const Key('label-column-candidate-list')),
    ) as dynamic;
    expect(candidateTable.rowNumberWidth, 34);
    expect(candidateTable.autoFitColumns, isFalse);
    expect(candidateTable.fillLastColumn, isTrue);
    expect(
      candidateTable.columns
          .firstWhere((dynamic column) => column.header == '항목명')
          .initialWidth,
      111,
    );
    for (final key in const [
      Key('label-column-reorder'),
      Key('label-column-remove'),
      Key('label-column-add'),
    ]) {
      final button = tester.widget<IconButton>(find.byKey(key));
      expect(button.iconSize, 22);
      expect(button.constraints, const BoxConstraints.tightFor(width: 38, height: 38));
    }

    final typeDropdown = find.byKey(const Key('label-column-type'));
    expect(tester.getSize(typeDropdown).height, 36);
    expect(
      tester.getSize(find.byKey(const Key('label-column-fixed-type'))).height,
      36,
    );
    final fixedTypeDropdown = find.descendant(
      of: find.byKey(const Key('label-column-fixed-type')),
      matching: find.byType(DropdownMenu<int>),
    );
    expect(fixedTypeDropdown, findsOneWidget);
    final fixedTypeArrow = find.descendant(
      of: fixedTypeDropdown,
      matching: find.byIcon(Icons.arrow_drop_down),
    );
    expect(fixedTypeArrow, findsNWidgets(2));
    final fixedTypeCenteredTrailingIcon = find.descendant(
      of: fixedTypeDropdown,
      matching: find.byKey(
        const Key('dialog-dropdown-centered-trailing-icon'),
      ),
    );
    expect(fixedTypeCenteredTrailingIcon, findsNWidgets(2));
    for (var index = 0; index < 2; index++) {
      expect(
        tester.getSize(fixedTypeCenteredTrailingIcon.at(index)),
        const Size(32, 36),
      );
      expect(
        tester.getCenter(fixedTypeArrow.at(index)),
        offsetMoreOrLessEquals(
          tester.getCenter(fixedTypeCenteredTrailingIcon.at(index)),
          epsilon: 0.01,
        ),
      );
    }
    final dropdownArrow = find.descendant(
      of: typeDropdown,
      matching: find.byIcon(Icons.arrow_drop_down),
    );
    expect(dropdownArrow, findsNWidgets(2));
    final propertyTypeCenteredTrailingIcon = find.descendant(
      of: typeDropdown,
      matching: find.byKey(
        const Key('dialog-dropdown-centered-trailing-icon'),
      ),
    );
    expect(propertyTypeCenteredTrailingIcon, findsNWidgets(2));
    for (var index = 0; index < 2; index++) {
      expect(
        tester.getSize(propertyTypeCenteredTrailingIcon.at(index)),
        const Size(32, 36),
      );
      expect(
        tester.getCenter(dropdownArrow.at(index)),
        offsetMoreOrLessEquals(
          tester.getCenter(propertyTypeCenteredTrailingIcon.at(index)),
          epsilon: 0.01,
        ),
      );
    }
    final keywordField = find.byKey(const Key('label-column-keyword'));
    final nameField = find.byKey(const Key('label-column-name'));
    final titleField = find.widgetWithText(TextFormField, '제목');
    for (final field in [keywordField, nameField, titleField]) {
      expect(tester.getSize(field).height, 40);
    }
    expect(
      tester
          .widget<InputDecorator>(
            find.descendant(
              of: keywordField,
              matching: find.byType(InputDecorator),
            ),
          )
          .decoration
          .contentPadding,
      const EdgeInsets.fromLTRB(10, 12, 10, 4),
    );
    expect(
      tester.getTopLeft(nameField).dy - tester.getBottomLeft(keywordField).dy,
      4,
    );
    expect(
      tester.getTopLeft(typeDropdown).dy - tester.getBottomLeft(nameField).dy,
      4,
    );
    expect(
      tester.getTopLeft(titleField).dy - tester.getBottomLeft(typeDropdown).dy,
      4,
    );
    final keywordEditor = find.descendant(
      of: find.byKey(const Key('label-column-keyword')),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(keywordEditor).style.fontSize, 13);
    final dropdownEditor = find.descendant(
      of: typeDropdown,
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(dropdownEditor).style.fontSize, 13);
    await _tapVisible(tester, typeDropdown);
    await tester.pumpAndSettle();
    final barcodeMenuItem = find.widgetWithText(MenuItemButton, '바코드');
    expect(barcodeMenuItem, findsAtLeastNWidgets(1));
    expect(tester.getSize(barcodeMenuItem.last).height, 28);
    await _tapVisible(tester, barcodeMenuItem.last);
    await tester.pumpAndSettle();
    final barcodeTypeDropdown = find.byType(DropdownMenu<BarcodeType>);
    expect(barcodeTypeDropdown, findsOneWidget);
    expect(
      tester
          .widget<DropdownMenu<BarcodeType>>(barcodeTypeDropdown)
          .inputDecorationTheme
          ?.fillColor,
      Colors.white,
    );
    expect(
      find.descendant(
        of: barcodeTypeDropdown,
        matching: find.byKey(
          const Key('dialog-dropdown-centered-trailing-icon'),
        ),
      ),
      findsNWidgets(2),
    );
    await _tapVisible(
      tester,
      find.byKey(const Key('label-column-property-apply')),
    );

    await _tapVisible(tester, find.text('사용자 항목'));
    await tester.pumpAndSettle();
    expect(find.text('사용자 A'), findsOneWidget);
    final userEdit = tester.widget<IconButton>(
      find.byKey(const Key('label-column-user-edit')),
    );
    expect(userEdit.iconSize, 22);
    expect(
      userEdit.constraints,
      const BoxConstraints.tightFor(width: 38, height: 38),
    );
  });

  testWidgets('dropdown popup is selectable above the modeless overlay', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: _OverlayHost(
          child: LabelColumnEditDialog(
            labelSizeId: 10,
            customerId: 7,
            initialColumns: [_column(1, 'BASE_A')],
            canSave: () async => true,
            onSave: (_) async {},
            onClose: () {},
            loadFixedTypes: () async => const [
              FixedColumnType(id: 1, name: '공통'),
            ],
            loadFixedCandidates: (_) async => const [],
            loadCustomerCandidates: (_) async => const [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.byKey(const Key('label-column-type')));
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.widgetWithText(MenuItemButton, '바코드').last,
    );
    await tester.pumpAndSettle();

    final editor = find.descendant(
      of: find.byKey(const Key('label-column-type')),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(editor).controller.text, '바코드');
  });

  testWidgets('all QR property dropdown arrows are centered', (tester) async {
    TColumnType.datas = [baseType, barcodeColumnType, qrColumnType];
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDialog(
      tester,
      columns: [
        _column(1, 'QR_A').copyWith(columnType: qrColumnType),
      ],
    );

    final propertyDropdowns = <Finder>[
      find.byType(DropdownMenu<TColumnType>),
      find.byType(DropdownMenu<BarcodeType>),
      find.byType(DropdownMenu<QRCodeCreateType>),
      find.byType(DropdownMenu<QRTextAlignment>),
    ];
    for (final dropdown in propertyDropdowns) {
      expect(dropdown, findsOneWidget);
      final arrows = find.descendant(
        of: dropdown,
        matching: find.byIcon(Icons.arrow_drop_down),
      );
      final centeredTrailingIcons = find.descendant(
        of: dropdown,
        matching: find.byKey(
          const Key('dialog-dropdown-centered-trailing-icon'),
        ),
      );
      expect(arrows, findsNWidgets(2));
      expect(centeredTrailingIcons, findsNWidgets(2));
      for (var index = 0; index < 2; index++) {
        expect(
          tester.getSize(centeredTrailingIcons.at(index)),
          const Size(32, 36),
        );
        expect(
          tester.getCenter(arrows.at(index)),
          offsetMoreOrLessEquals(
            tester.getCenter(centeredTrailingIcons.at(index)),
            epsilon: 0.01,
          ),
        );
      }
    }
  });

  testWidgets('adds and removes candidates through shared commands', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDialog(tester);

    await _tapVisible(tester, find.text('고정 A'));
    await _tapVisible(tester, find.byKey(const Key('label-column-add')));
    await tester.pump();
    final usedFixed = find.descendant(
      of: find.byKey(const Key('label-column-used-table')),
      matching: find.text('FIXED_A'),
    );
    expect(usedFixed, findsOneWidget);

    await _tapVisible(tester, usedFixed);
    await _tapVisible(tester, find.byKey(const Key('label-column-remove')));
    await tester.pump();
    expect(usedFixed, findsNothing);
  });

  testWidgets('used row drop animates before removing the row', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDialog(tester);

    final usedRowTexts = find.descendant(
      of: find.byKey(const Key('label-column-used-table')),
      matching: find.text('BASE_A'),
    );
    final usedRow = usedRowTexts.first;
    final remove = find.byKey(const Key('label-column-remove'));
    await _dragRowTo(tester, usedRow, remove);
    await tester.pump();

    expect(usedRowTexts, findsWidgets);
    expect(
      tester
          .widget<AnimatedScale>(
            find.byKey(const Key('label-column-remove-drop-animation')),
          )
          .scale,
      0.72,
    );

    await tester.pump(const Duration(milliseconds: 160));
    await tester.pumpAndSettle();
    expect(usedRowTexts, findsNothing);
  });

  testWidgets('candidate focus and drag disable command buttons', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDialog(tester);

    final remove = find.byKey(const Key('label-column-remove'));
    final add = find.byKey(const Key('label-column-add'));
    expect(tester.widget<IconButton>(remove).onPressed, isNotNull);

    await _tapVisible(tester, find.text('고정 A'));
    expect(tester.widget<IconButton>(remove).onPressed, isNull);
    expect(tester.widget<IconButton>(add).onPressed, isNotNull);

    await _tapVisible(tester, find.text('BASE_A').last);
    expect(tester.widget<IconButton>(remove).onPressed, isNotNull);

    final source = find.text('고정 A');
    final gesture = await _startRowDrag(tester, source);
    await gesture.moveBy(const Offset(-24, 0));
    await tester.pump();
    expect(tester.widget<IconButton>(remove).onPressed, isNull);
    expect(tester.widget<IconButton>(add).onPressed, isNull);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(add).onPressed, isNotNull);
  });

  testWidgets('pending property disables other regions without confirmation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDialog(tester);

    await _tapVisible(tester, find.text('바코드 A'));
    await _tapVisible(tester, find.byKey(const Key('label-column-add')));
    await tester.pump();
    expect(
      tester
          .widget<IgnorePointer>(
            find.byKey(const Key('label-column-used-region')),
          )
          .ignoring,
      isTrue,
    );
    expect(
      tester
          .widget<IgnorePointer>(
            find.byKey(const Key('label-column-candidate-region')),
          )
          .ignoring,
      isTrue,
    );
    expect(
      tester
          .widget<IgnorePointer>(
            find.byKey(const Key('label-column-command-region')),
          )
          .ignoring,
      isTrue,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('label-column-main-cancel')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('label-column-main-save')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('BASE_A').last);
    await tester.pump();
    expect(find.text('미적용 속성'), findsNothing);

    tester
        .widget<TextButton>(
          find.byKey(const Key('label-column-property-cancel')),
        )
        .onPressed!();
    await tester.pump();
    expect(
      tester
          .widget<IgnorePointer>(
            find.byKey(const Key('label-column-used-region')),
          )
          .ignoring,
      isFalse,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('label-column-used-table')),
        matching: find.text('BARCODE_A'),
      ),
      findsNothing,
    );
  });

  testWidgets('property cancel restores baseline and apply reaches save command', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    LabelColumnSaveCommand? saved;
    await _pumpDialog(tester, onSave: (command) async => saved = command);

    await tester.enterText(find.byKey(const Key('label-column-name')), '취소할 이름');
    tester
        .widget<TextButton>(
          find.byKey(const Key('label-column-property-cancel')),
        )
        .onPressed!();
    await tester.pump();
    final nameEditor = find.descendant(
      of: find.byKey(const Key('label-column-name')),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(nameEditor).controller.text, 'BASE_A');

    await tester.enterText(find.byKey(const Key('label-column-name')), '적용한 이름');
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const Key('label-column-property-apply')),
        )
        .onPressed!();
    await tester.pump();
    await tester.tap(find.byKey(const Key('label-column-main-save')));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '확인').last);
    await tester.pump();
    await tester.pump();

    expect(saved?.updatedColumns.single.column.columnName, '적용한 이름');
  });

  testWidgets('reorder cancel restores and apply persists stable-key order', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    LabelColumnSaveCommand? saved;
    await _pumpDialog(
      tester,
      columns: [_column(1, 'A'), _column(2, 'B', order: 2)],
      onSave: (command) async => saved = command,
    );

    await _tapVisible(tester, find.byKey(const Key('label-column-reorder')));
    await _tapVisible(tester, find.byKey(const Key('label-column-move-down')));
    await _tapVisible(tester, find.byKey(const Key('label-column-reorder-cancel')));
    await tester.pump();
    final mainSave = tester.widget<FilledButton>(
      find.byKey(const Key('label-column-main-save')),
    );
    expect(mainSave.onPressed, isNull);

    await _tapVisible(tester, find.byKey(const Key('label-column-reorder')));
    await _tapVisible(tester, find.byKey(const Key('label-column-move-down')));
    await _tapVisible(tester, find.byKey(const Key('label-column-reorder-apply')));
    await tester.tap(find.byKey(const Key('label-column-main-save')));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '확인').last);
    await tester.pump();
    await tester.pump();

    expect(saved?.orderedKeys, ['column:2', 'column:1']);
  });

  testWidgets('user edit applies in memory and saves from the main footer', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var loadCount = 0;
    LabelColumnSaveCommand? savedLabel;
    CustomerColumnSaveCommand? saved;
    await _pumpDialog(
      tester,
      onSave: (command) async => savedLabel = command,
      saveCustomer: (command) async => saved = command,
      loadCustomer: (_) async {
        loadCount += 1;
        return const [];
      },
    );

    await _tapVisible(tester, find.text('사용자 항목'));
    await _tapVisible(tester, find.byKey(const Key('label-column-user-edit')));
    await tester.pump();
    expect(
      tester.widget<IconButton>(find.byKey(const Key('label-column-reorder'))).onPressed,
      isNull,
    );

    await _tapVisible(tester, find.byKey(const Key('label-column-user-add')));
    await tester.pump();
    expect(
      tester
          .widget(find.byKey(const Key('label-column-user-editor')))
          .runtimeType
          .toString()
          .startsWith('SwipeActionTable<'),
      isTrue,
    );
    await tester.enterText(find.byKey(const ValueKey('customer-keyword:customer-draft:1')), 'new1');
    await tester.enterText(find.byKey(const ValueKey('customer-name:customer-draft:1')), '새 항목');
    await tester.tap(find.byKey(const Key('label-column-user-apply')));
    await tester.pumpAndSettle();

    expect(saved, isNull);
    expect(loadCount, 1);
    expect(find.text('새 항목'), findsOneWidget);
    expect(find.byKey(const Key('label-column-user-editor')), findsNothing);

    await _tapVisible(tester, find.text('새 항목'));
    await _tapVisible(tester, find.byKey(const Key('label-column-add')));
    expect(
      find.descendant(
        of: find.byKey(const Key('label-column-used-table')),
        matching: find.text('NEW1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('label-column-main-save')));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '확인').last);
    await tester.pump();
    await tester.pump();

    expect(saved?.newColumns.single.keyword, 'NEW1');
  expect(savedLabel?.newColumns.single.column.keyword, 'NEW1');
  });

  testWidgets('user rows select, edit on double tap, and delete from the rail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDialog(tester);

    await _tapVisible(tester, find.text('사용자 항목'));
    await _tapVisible(tester, find.byKey(const Key('label-column-user-edit')));
    await tester.pump();

    final userTable = tester.widget(
      find.byKey(const Key('label-column-user-editor')),
    ) as dynamic;
    expect(userTable.rowHeight, 28);
    expect(userTable.columns.length, 3);
    expect(userTable.scrollToIndex, isNull);
    expect(
      tester.widget<IconButton>(find.byKey(const Key('label-column-remove'))).onPressed,
      isNull,
    );
    expect(
      tester.widget<IconButton>(find.byKey(const Key('label-column-user-add'))).iconSize,
      22,
    );
    expect(
      find.ancestor(
        of: find.byKey(const Key('label-column-used-table')),
        matching: find.byWidgetPredicate(
          (widget) => widget is IgnorePointer && widget.ignoring,
        ),
      ),
      findsOneWidget,
    );

    await _tapVisible(tester, find.text('CUSTOM_A'));
    expect(
      tester.widget<IconButton>(find.byKey(const Key('label-column-remove'))).onPressed,
      isNotNull,
    );
    expect(
      find.byKey(const ValueKey('customer-keyword:customer-column:11')),
      findsNothing,
    );

    await _tapVisible(tester, find.byKey(const Key('label-column-remove')));
    expect(find.text('CUSTOM_A'), findsNothing);

    await _tapVisible(tester, find.byKey(const Key('label-column-user-cancel')));
    await _tapVisible(tester, find.byKey(const Key('label-column-user-edit')));
    await tester.pump();

    await tester.tap(find.text('CUSTOM_A'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('CUSTOM_A'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('customer-keyword:customer-column:11')),
      findsOneWidget,
    );
    final editingTable = tester.widget(
      find.byKey(const Key('label-column-user-editor')),
    ) as dynamic;
    expect(editingTable.scrollToIndex, isNull);

    await _tapVisible(tester, find.byKey(const Key('label-column-user-cancel')));
    await _tapVisible(tester, find.byKey(const Key('label-column-user-edit')));
    await tester.pump();
    final source = find.text('CUSTOM_A');
    final target = find.byKey(const Key('label-column-remove'));
    await _dragRowTo(tester, source, target);
    await tester.pumpAndSettle();
    expect(find.text('CUSTOM_A'), findsNothing);
  });

  testWidgets('customer keyword and name drag delete use row feedback', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDialog(tester);

    await _tapVisible(tester, find.text('사용자 항목'));
    await _tapVisible(tester, find.byKey(const Key('label-column-user-edit')));
    await tester.pump();

    final remove = find.byKey(const Key('label-column-remove'));
    expect(tester.widget<IconButton>(remove).tooltip, '사용자 항목 삭제');

    final keyword = find.byKey(
      const ValueKey('customer-keyword-drag:customer-column:11'),
    );
    final keywordDrag = await _startRowDrag(tester, keyword);
    await keywordDrag.moveBy(const Offset(20, 0));
    await tester.pump();

    final feedback = find.byWidgetPredicate(
      (widget) => widget is Material && widget.elevation == 4,
    );
    expect(feedback, findsOneWidget);
    expect(
      find.descendant(of: feedback, matching: find.text('CUSTOM_A')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: feedback, matching: find.text('사용자 A')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: feedback, matching: find.text('기본')),
      findsWidgets,
    );

    await keywordDrag.moveTo(tester.getCenter(remove));
    await keywordDrag.up();
    await tester.pumpAndSettle();
    expect(keyword, findsNothing);

    await _tapVisible(tester, find.byKey(const Key('label-column-user-cancel')));
    await _tapVisible(tester, find.byKey(const Key('label-column-user-edit')));
    await tester.pump();

    final name = find.byKey(
      const ValueKey('customer-name-drag:customer-column:11'),
    );
    await _dragRowTo(tester, name, remove);
    await tester.pumpAndSettle();
    expect(name, findsNothing);
  });

  testWidgets('adding a user row scrolls to its inline editor', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1300, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDialog(
      tester,
      loadCustomer: (_) async => [
        for (var index = 0; index < 20; index++)
          CustomerColumnCandidate(
            id: index + 1,
            customerId: 7,
            columnType: baseType,
            keyword: 'CUSTOM_$index',
            columnName: '사용자 $index',
          ),
      ],
    );

    await _tapVisible(tester, find.text('사용자 항목'));
    await _tapVisible(tester, find.byKey(const Key('label-column-user-edit')));
    await _tapVisible(tester, find.byKey(const Key('label-column-user-add')));
    await tester.pumpAndSettle();

    final tableFinder = find.byKey(const Key('label-column-user-editor'));
    final table = tester.widget(tableFinder) as dynamic;
    expect(table.scrollToIndex, 20);
    final verticalLists = tester.widgetList<ListView>(
      find.descendant(of: tableFinder, matching: find.byType(ListView)),
    );
    expect(
      verticalLists.any(
        (list) => list.controller?.hasClients == true &&
            list.controller!.position.pixels > 0,
      ),
      isTrue,
    );
  });

  testWidgets('customer type dropdown stays available and saves changes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    CustomerColumnSaveCommand? saved;
    await _pumpDialog(
      tester,
      saveCustomer: (command) async => saved = command,
      loadCustomer: (_) async => const [
        CustomerColumnCandidate(
          id: 11,
          customerId: 7,
          columnType: baseType,
          keyword: 'CUSTOMA',
          columnName: '사용자 A',
        ),
      ],
    );

    await _tapVisible(tester, find.text('사용자 항목'));
    await _tapVisible(tester, find.byKey(const Key('label-column-user-edit')));
    await tester.pump();

    final typeDropdown = find.descendant(
      of: find.byKey(const Key('label-column-user-editor')),
      matching: find.byType(DropdownMenu<TColumnType>),
    );
    expect(typeDropdown, findsOneWidget);
    final compactArrow = find.descendant(
      of: typeDropdown,
      matching: find.byIcon(Icons.arrow_drop_down),
    );
    expect(compactArrow, findsNWidgets(2));
    final expectedCompactArrowCenter = Offset(
      tester.getTopRight(typeDropdown).dx - 16,
      tester.getCenter(typeDropdown).dy,
    );
    var visibleArrowIndex = 0;
    var nearestDistance = double.infinity;
    for (var index = 0; index < 2; index++) {
      final distance =
          (tester.getCenter(compactArrow.at(index)) -
                  expectedCompactArrowCenter)
              .distance;
      if (distance < nearestDistance) {
        visibleArrowIndex = index;
        nearestDistance = distance;
      }
    }
    final visibleCompactArrow = compactArrow.at(visibleArrowIndex);
    expect(
      tester.getCenter(visibleCompactArrow).dx,
      closeTo(expectedCompactArrowCenter.dx, 0.01),
    );
    expect(
      tester.getCenter(visibleCompactArrow).dy,
      closeTo(expectedCompactArrowCenter.dy, 0.01),
    );
    await _tapVisible(tester, typeDropdown);
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.widgetWithText(MenuItemButton, '바코드').last,
    );
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.byKey(const Key('label-column-user-apply')));
    expect(saved, isNull);
    await _tapVisible(tester, find.byKey(const Key('label-column-main-save')));
    await tester.pump();
    await _tapVisible(tester, find.widgetWithText(FilledButton, '확인').last);
    await tester.pump();
    await tester.pump();

    expect(saved?.updatedColumns.single.columnType, barcodeColumnType);
  });

  testWidgets('main cancel confirms applied customer changes before closing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var closed = false;
    var saveCount = 0;
    await _pumpDialog(
      tester,
      onClose: () => closed = true,
      saveCustomer: (_) async => saveCount += 1,
      loadCustomer: (_) async => const [],
    );

    await _tapVisible(tester, find.text('사용자 항목'));
    await _tapVisible(tester, find.byKey(const Key('label-column-user-edit')));
    await _tapVisible(tester, find.byKey(const Key('label-column-user-add')));
    await tester.enterText(
      find.byKey(const ValueKey('customer-keyword:customer-draft:1')),
      'new1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('customer-name:customer-draft:1')),
      '새 항목',
    );
    await _tapVisible(tester, find.byKey(const Key('label-column-user-apply')));
    await _tapVisible(tester, find.byKey(const Key('label-column-main-cancel')));
    await tester.pump();

    expect(find.text('변경 내용 취소'), findsOneWidget);
    expect(closed, isFalse);
    expect(saveCount, 0);

    await tester.tap(find.widgetWithText(FilledButton, '버리기').last);
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(saveCount, 0);
  });

  testWidgets('user edit stays disabled until customer candidates load', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final customerRows = Completer<List<CustomerColumnCandidate>>();
    await _pumpDialog(
      tester,
      loadCustomer: (_) => customerRows.future,
      settle: false,
    );

    await _tapVisible(tester, find.text('사용자 항목'));
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('label-column-user-edit')),
          )
          .onPressed,
      isNull,
    );

    customerRows.complete(const [
      CustomerColumnCandidate(
        id: 11,
        customerId: 7,
        columnType: baseType,
        keyword: 'CUSTOM_A',
        columnName: '사용자 A',
      ),
    ]);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('label-column-user-edit')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('fixed candidate failure does not block customer editing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDialog(
      tester,
      loadFixed: (_) async => throw StateError('fixed load failed'),
    );

    expect(find.text('고정 항목 조회 실패'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '확인').last);
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text('사용자 항목'));

    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('label-column-user-edit')),
          )
          .onPressed,
      isNotNull,
    );
    expect(find.text('사용자 A'), findsOneWidget);
  });

  testWidgets('initial candidate failures are shown sequentially', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1300, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpDialog(
      tester,
      loadFixed: (_) async => throw StateError('fixed load failed'),
      loadCustomer: (_) async => throw StateError('customer load failed'),
    );

    expect(find.text('고정 항목 조회 실패'), findsOneWidget);
    expect(find.text('사용자 항목 조회 실패'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, '확인').last);
    await tester.pumpAndSettle();
    expect(find.text('사용자 항목 조회 실패'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '확인').last);
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('사용자 항목'));
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('label-column-user-edit')),
          )
          .onPressed,
      isNull,
    );
  });

  for (final saveFailure in [
    (
      title: '저장 완료',
      error: const LabelColumnSaveCommittedException('화면 갱신 실패'),
    ),
    (
      title: '저장 결과 확인 필요',
      error: const LabelColumnSaveCommittedException(
        '커밋 결과 불명확',
        outcomeUnknown: true,
      ),
    ),
  ]) {
    testWidgets('${saveFailure.title} 안내 후 재저장 없이 닫는다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var saveCount = 0;
      var closed = false;
      await _pumpDialog(
        tester,
        onDialogSave: (_) async {
          saveCount += 1;
          throw saveFailure.error;
        },
        onClose: () => closed = true,
      );

      await tester.enterText(find.byKey(const Key('label-column-name')), '변경');
    await tester.pump();
      tester
          .widget<FilledButton>(
            find.byKey(const Key('label-column-property-apply')),
          )
          .onPressed!();
      await tester.pump();
      await _tapVisible(tester, find.byKey(const Key('label-column-main-save')));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, '확인').last);
      await tester.pump();
      await tester.pump();

      expect(find.text(saveFailure.title), findsOneWidget);
      expect(saveCount, 1);
      expect(closed, isFalse);

      await tester.tap(find.widgetWithText(FilledButton, '확인').last);
      await tester.pump();
      await tester.pump();
      expect(saveCount, 1);
      expect(closed, isTrue);
    });
  }

  testWidgets('busy disables commands and 900x600 has no overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final saveCompleter = Completer<void>();
    var closed = false;
    await _pumpDialog(
      tester,
      onSave: (_) => saveCompleter.future,
      onClose: () => closed = true,
    );
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byKey(const Key('label-column-name')), '변경');
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.byKey(const Key('label-column-property-apply')),
        )
        .onPressed!();
    await tester.pump();
    await tester.tap(find.byKey(const Key('label-column-main-save')));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '확인').last);
    await tester.pump();

    expect(
      tester.widget<IconButton>(find.byKey(const Key('label-column-reorder'))).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byKey(const Key('label-column-main-cancel'))).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);

    saveCompleter.complete();
    await tester.pump();
    await tester.pump();
    expect(closed, isTrue);
  });
}
