import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FortuneTableCheckboxController extends ChangeNotifier {
  final Map<String, Set<int>> _checkedRowsByColumn = <String, Set<int>>{};

  bool isChecked(String columnId, int rowIndex) {
    return _checkedRowsByColumn[columnId]?.contains(rowIndex) ?? false;
  }

  Set<int> checkedRows(String columnId) {
    return Set<int>.unmodifiable(
      _checkedRowsByColumn[columnId] ?? const <int>{},
    );
  }

  void setChecked(String columnId, int rowIndex, bool checked) {
    final rows = _checkedRowsByColumn.putIfAbsent(columnId, () => <int>{});
    final changed = checked ? rows.add(rowIndex) : rows.remove(rowIndex);
    if (!changed) return;
    if (rows.isEmpty) {
      _checkedRowsByColumn.remove(columnId);
    }
    notifyListeners();
  }

  void toggleChecked(String columnId, int rowIndex) {
    setChecked(columnId, rowIndex, !isChecked(columnId, rowIndex));
  }

  void setCheckedRows(String columnId, Iterable<int> rowIndexes) {
    final nextRows = rowIndexes.toSet();
    final currentRows = _checkedRowsByColumn[columnId] ?? const <int>{};
    if (currentRows.length == nextRows.length &&
        currentRows.every(nextRows.contains)) {
      return;
    }
    if (nextRows.isEmpty) {
      _checkedRowsByColumn.remove(columnId);
    } else {
      _checkedRowsByColumn[columnId] = nextRows;
    }
    notifyListeners();
  }

  void clearColumn(String columnId) {
    if (_checkedRowsByColumn.remove(columnId) == null) return;
    notifyListeners();
  }

  void clear() {
    if (_checkedRowsByColumn.isEmpty) return;
    _checkedRowsByColumn.clear();
    notifyListeners();
  }
}

class FortuneTableSelectionController extends ChangeNotifier {
  final Set<int> _selectedRows = <int>{};

  bool get hasSelection => _selectedRows.isNotEmpty;

  Set<int> get selectedRows => Set<int>.unmodifiable(_selectedRows);

  bool isSelected(int rowIndex) => _selectedRows.contains(rowIndex);

  void setSelected(int rowIndex, bool selected) {
    final changed = selected
        ? _selectedRows.add(rowIndex)
        : _selectedRows.remove(rowIndex);
    if (!changed) return;
    notifyListeners();
  }

  void toggleSelected(int rowIndex) {
    setSelected(rowIndex, !isSelected(rowIndex));
  }

  void setSelectedRows(Iterable<int> rowIndexes) {
    final nextRows = rowIndexes.toSet();
    if (_selectedRows.length == nextRows.length &&
        _selectedRows.every(nextRows.contains)) {
      return;
    }
    _selectedRows
      ..clear()
      ..addAll(nextRows);
    notifyListeners();
  }

  void selectRange(int startRowIndex, int endRowIndex) {
    final start = math.min(startRowIndex, endRowIndex);
    final end = math.max(startRowIndex, endRowIndex);
    setSelectedRows([for (var index = start; index <= end; index += 1) index]);
  }

  void selectAll(int rowCount) {
    setSelectedRows([for (var index = 0; index < rowCount; index += 1) index]);
  }

  void clear() {
    if (_selectedRows.isEmpty) return;
    _selectedRows.clear();
    notifyListeners();
  }
}

class FortuneTableFocusController extends ChangeNotifier {
  int? _rowIndex;
  String? _columnId;

  int? get rowIndex => _rowIndex;
  String? get columnId => _columnId;

  void focusCell(int rowIndex, String columnId) {
    if (rowIndex < 0 || columnId.isEmpty) return;
    _rowIndex = rowIndex;
    _columnId = columnId;
    notifyListeners();
  }
}

class FortuneTableEditingController {
  Object? _owner;
  Future<void> Function()? _commitEditing;
  bool Function()? _hasActiveEditing;

  bool get hasActiveEditing => _hasActiveEditing?.call() ?? false;

  Future<void> commitEditing() async {
    await _commitEditing?.call();
  }

  void _attach({
    required Object owner,
    required Future<void> Function() commitEditing,
    required bool Function() hasActiveEditing,
  }) {
    _owner = owner;
    _commitEditing = commitEditing;
    _hasActiveEditing = hasActiveEditing;
  }

  void _detach(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _commitEditing = null;
    _hasActiveEditing = null;
  }
}

class FortuneTableColumn<T> {
  const FortuneTableColumn({
    required this.id,
    required this.header,
    required this.text,
    this.initialWidth = 120,
    this.minWidth = 60,
    this.checkboxValue,
    this.checkboxValueAt,
    this.checkboxController,
    this.onCheckboxChanged,
    this.onCheckboxChangedAt,
    this.isTextEditable,
    this.onTextCommitted,
    this.onDoubleTap,
    this.fillRemaining = false,
  });

  final String id;
  final String header;
  final String Function(T row) text;
  final double initialWidth;
  final double minWidth;
  final bool Function(T row)? checkboxValue;
  final bool Function(T row, int rowIndex)? checkboxValueAt;
  final FortuneTableCheckboxController? checkboxController;
  final void Function(T row, bool value)? onCheckboxChanged;
  final void Function(T row, int rowIndex, bool value)? onCheckboxChangedAt;
  final bool Function(T row, int rowIndex)? isTextEditable;
  final FutureOr<void> Function(T row, int rowIndex, String value)?
  onTextCommitted;
  final FutureOr<void> Function(T row, int rowIndex)? onDoubleTap;
  final bool fillRemaining;

  bool get isCheckbox =>
      checkboxValue != null ||
      checkboxValueAt != null ||
      checkboxController != null ||
      onCheckboxChanged != null ||
      onCheckboxChangedAt != null;
}

class FortuneTable<T> extends StatefulWidget {
  const FortuneTable({
    super.key,
    required this.rows,
    required this.columns,
    this.selectedIndex,
    this.selectionController,
    this.focusController,
    this.editingController,
    this.onRowSelected,
    this.onCellActivated,
    this.onRowSecondaryTapDown,
    this.onRectChanged,
    this.rowColorBuilder,
    this.rowNumberWidth = 40,
    this.headerHeight = 36,
    this.rowHeight = 28,
    this.autoFitColumns = true,
    this.fillLastColumn = false,
    this.dragScrollEnabled = true,
    this.multiSelectionEnabled = false,
    this.keyboardSelectionShortcutsEnabled = true,
  });

  final List<T> rows;
  final List<FortuneTableColumn<T>> columns;
  final int? selectedIndex;
  final FortuneTableSelectionController? selectionController;
  final FortuneTableFocusController? focusController;
  final FortuneTableEditingController? editingController;
  final void Function(T row, int index)? onRowSelected;
  final void Function(T row, int rowIndex, String columnId)? onCellActivated;
  final void Function(T row, int index, TapDownDetails details)?
  onRowSecondaryTapDown;
  final ValueChanged<Rect>? onRectChanged;
  final Color? Function(T row, int rowIndex, bool selected)? rowColorBuilder;
  final double rowNumberWidth;
  final double headerHeight;
  final double rowHeight;
  final bool autoFitColumns;
  final bool fillLastColumn;
  final bool dragScrollEnabled;
  final bool multiSelectionEnabled;
  final bool keyboardSelectionShortcutsEnabled;

  @override
  State<FortuneTable<T>> createState() => _FortuneTableState<T>();
}

class _FortuneTableScrollBehavior extends MaterialScrollBehavior {
  const _FortuneTableScrollBehavior({required this.dragScrollEnabled});

  final bool dragScrollEnabled;

  @override
  Set<PointerDeviceKind> get dragDevices {
    if (!dragScrollEnabled) {
      return super.dragDevices;
    }
    return {
      ...super.dragDevices,
      PointerDeviceKind.mouse,
      PointerDeviceKind.touch,
    };
  }
}

class _FortuneTableState<T> extends State<FortuneTable<T>> {
  static const Color _headerColor = Color(0xFF0E2F66);
  static const Color _headerSeparatorColor = Color(0xFFBDBDBD);
  static const Color _bodySeparatorColor = Color(0xFFE6E8EB);
  static const Color _selectedRowColor = Color(0xFFE3F2FD);
  static const Color _alternateRowColor = Color(0xFFF2F4F7);
  static const Color _checkboxBorderColor = Color(0xffb7b7b7);
  static const Color _checkboxCheckColor = Color(0xff0188fb);
  static const Color _textEditorBorderColor = Color(0xFF0188FB);
  static const double _checkboxSize = 13.0;

  final ScrollController _hScrollHeader = ScrollController();
  final ScrollController _hScrollBody = ScrollController();
  final ScrollController _vScrollBody = ScrollController();
  final ScrollController _vScrollIndex = ScrollController();
  final FocusNode _focusNode = FocusNode(debugLabel: 'FortuneTable');
  bool _syncingHorizontal = false;
  bool _syncingVertical = false;
  late List<double> _widths;
  List<double> _effectiveColumnWidths = const [];
  Set<FortuneTableCheckboxController> _checkboxControllers =
      <FortuneTableCheckboxController>{};
  int? _selectedIndex;
  int? _selectionAnchorIndex;
  int? _dragSelectionStartIndex;
  Rect? _lastReportedRect;
  String? _tableSignature;
  int? _focusedColumnIndex;
  int? _editingRowIndex;
  int? _editingColumnIndex;
  String? _textEditorInitialValue;
  TextEditingController? _textEditorController;
  FocusNode? _textEditorFocusNode;
  Future<void>? _pendingTextCommit;

  @override
  void initState() {
    super.initState();
    _widths = _initialWidths();
    _selectedIndex = widget.selectedIndex;
    widget.selectionController?.addListener(_handleSelectionControllerChanged);
    widget.focusController?.addListener(_handleFocusControllerChanged);
    widget.editingController?._attach(
      owner: this,
      commitEditing: _commitAndWaitForTextEditing,
      hasActiveEditing: () =>
          _editingRowIndex != null || _pendingTextCommit != null,
    );
    _syncCheckboxControllerListeners(<FortuneTableColumn<T>>[]);
    _hScrollBody.addListener(_syncHorizontalFromBody);
    _hScrollHeader.addListener(_syncHorizontalFromHeader);
    _vScrollBody.addListener(_syncVerticalFromBody);
    _vScrollIndex.addListener(_syncVerticalFromIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAutoWidthsIfNeeded();
  }

  @override
  void didUpdateWidget(covariant FortuneTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.columns.length != widget.columns.length ||
        _initialWidthsChanged(oldWidget.columns, widget.columns)) {
      _widths = _initialWidths();
      _tableSignature = null;
    }
    if (oldWidget.selectedIndex != widget.selectedIndex &&
        widget.selectedIndex != _selectedIndex) {
      _selectedIndex = widget.selectedIndex;
    }
    if ((_selectedIndex ?? -1) >= widget.rows.length) {
      _selectedIndex = null;
    }
    if ((_editingRowIndex ?? -1) >= widget.rows.length ||
        (_editingColumnIndex ?? -1) >= widget.columns.length) {
      _clearTextEditingState();
    }
    if (oldWidget.selectionController != widget.selectionController) {
      oldWidget.selectionController?.removeListener(
        _handleSelectionControllerChanged,
      );
      widget.selectionController?.addListener(
        _handleSelectionControllerChanged,
      );
    }
    if (oldWidget.focusController != widget.focusController) {
      oldWidget.focusController?.removeListener(_handleFocusControllerChanged);
      widget.focusController?.addListener(_handleFocusControllerChanged);
    }
    if (oldWidget.editingController != widget.editingController) {
      oldWidget.editingController?._detach(this);
      widget.editingController?._attach(
        owner: this,
        commitEditing: _commitAndWaitForTextEditing,
        hasActiveEditing: () =>
            _editingRowIndex != null || _pendingTextCommit != null,
      );
    }
    widget.selectionController?.setSelectedRows(
      widget.selectionController!.selectedRows.where(
        (index) => index < widget.rows.length,
      ),
    );
    _syncCheckboxControllerListeners(oldWidget.columns);
    _syncAutoWidthsIfNeeded();
  }

  @override
  void dispose() {
    widget.editingController?._detach(this);
    _disposeTextEditor();
    for (final controller in _checkboxControllers) {
      controller.removeListener(_handleCheckboxControllerChanged);
    }
    widget.selectionController?.removeListener(
      _handleSelectionControllerChanged,
    );
    widget.focusController?.removeListener(_handleFocusControllerChanged);
    _focusNode.dispose();
    _hScrollHeader.dispose();
    _hScrollBody.dispose();
    _vScrollBody.dispose();
    _vScrollIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleRectReport();
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final widths = _effectiveWidths(constraints.maxWidth);
          _effectiveColumnWidths = widths;
          final bodyWidth = widths.fold<double>(0, (sum, width) => sum + width);
          final horizontalViewportWidth =
              (constraints.maxWidth - widget.rowNumberWidth)
                  .clamp(0, double.infinity)
                  .toDouble();
          final bodyViewportHeight =
              (constraints.maxHeight - widget.headerHeight)
                  .clamp(0, double.infinity)
                  .toDouble();
          final hasHorizontalOverflow =
              bodyWidth > horizontalViewportWidth + 0.5;
          final hasVerticalOverflow =
              widget.rows.length * widget.rowHeight > bodyViewportHeight + 0.5;
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerSignal: _handlePointerSignal,
            onPointerPanZoomUpdate: _handlePointerPanZoomUpdate,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      _rowHeaderCell('', _headerColor, widget.headerHeight),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _hScrollHeader,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: bodyWidth,
                            height: widget.headerHeight,
                            child: _buildHeader(widths),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: widget.rowNumberWidth,
                          child: ScrollConfiguration(
                            behavior: const _FortuneTableScrollBehavior(
                              dragScrollEnabled: false,
                            ),
                            child: ListView.builder(
                              controller: _vScrollIndex,
                              itemExtent: widget.rowHeight,
                              itemCount: widget.rows.length,
                              itemBuilder: (context, index) =>
                                  _scrollSignalBoundary(
                                    _rowHeaderCell(
                                      '${index + 1}',
                                      _headerColor,
                                      widget.rowHeight,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ScrollConfiguration(
                            behavior: _FortuneTableScrollBehavior(
                              dragScrollEnabled: widget.dragScrollEnabled,
                            ),
                            child: RawScrollbar(
                              controller: _vScrollBody,
                              thumbVisibility: hasVerticalOverflow,
                              thickness: 8,
                              radius: Radius.zero,
                              notificationPredicate: (notification) =>
                                  notification.metrics.axis == Axis.vertical,
                              child: RawScrollbar(
                                controller: _hScrollBody,
                                thumbVisibility: hasHorizontalOverflow,
                                thickness: 8,
                                radius: Radius.zero,
                                notificationPredicate: (notification) =>
                                    notification.metrics.axis ==
                                    Axis.horizontal,
                                child: SingleChildScrollView(
                                  controller: _hScrollBody,
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: bodyWidth,
                                    child: ListView.builder(
                                      controller: _vScrollBody,
                                      itemExtent: widget.rowHeight,
                                      itemCount: widget.rows.length,
                                      itemBuilder: (context, rowIndex) =>
                                          _scrollSignalBoundary(
                                            _buildRow(
                                              widget.rows[rowIndex],
                                              rowIndex,
                                              widths,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _scrollSignalBoundary(Widget child) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerSignal: _handlePointerSignal,
      onPointerPanZoomUpdate: _handlePointerPanZoomUpdate,
      child: child,
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      if (event is PointerScrollEvent) {
        _handlePointerScroll(event.scrollDelta);
      }
    });
  }

  void _handlePointerPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    _handlePointerScroll(event.panDelta);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.f2)) {
      final rowIndex = _selectedIndex;
      final columnIndex = _focusedColumnIndex;
      if (rowIndex != null &&
          columnIndex != null &&
          rowIndex < widget.rows.length &&
          columnIndex < widget.columns.length) {
        final row = widget.rows[rowIndex];
        final column = widget.columns[columnIndex];
        if (_isTextEditable(column, row, rowIndex)) {
          _startTextEditing(row, rowIndex, columnIndex, column);
          return KeyEventResult.handled;
        }
      }
    }
    final editingCharacter = _printableEditingCharacter(event);
    if (editingCharacter != null) {
      final rowIndex = _selectedIndex;
      final columnIndex = _focusedColumnIndex;
      if (rowIndex != null &&
          columnIndex != null &&
          rowIndex < widget.rows.length &&
          columnIndex < widget.columns.length) {
        final row = widget.rows[rowIndex];
        final column = widget.columns[columnIndex];
        if (_isTextEditable(column, row, rowIndex)) {
          _startTextEditing(
            row,
            rowIndex,
            columnIndex,
            column,
            initialText: editingCharacter,
          );
          return KeyEventResult.handled;
        }
      }
    }
    if (!widget.multiSelectionEnabled ||
      !widget.keyboardSelectionShortcutsEnabled) {
      return KeyEventResult.ignored;
    }
    final controller = widget.selectionController;
    if (controller == null) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      controller.clear();
      _selectionAnchorIndex = null;
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyA &&
        HardwareKeyboard.instance.isControlPressed) {
      controller.selectAll(widget.rows.length);
      if (widget.rows.isNotEmpty) {
        _selectionAnchorIndex = 0;
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String? _printableEditingCharacter(KeyEvent event) {
    if (HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isAltPressed) {
      return null;
    }
    final character = event.character;
    if (character != null && character.length == 1) {
      final codeUnit = character.codeUnitAt(0);
      if (codeUnit >= 0x20 || character == ' ') return character;
    }
    final keyId = event.logicalKey.keyId;
    final keyA = LogicalKeyboardKey.keyA.keyId;
    final keyZ = LogicalKeyboardKey.keyZ.keyId;
    if (keyId >= keyA && keyId <= keyZ) {
      final letter = String.fromCharCode('a'.codeUnitAt(0) + keyId - keyA);
      return HardwareKeyboard.instance.isShiftPressed
          ? letter.toUpperCase()
          : letter;
    }
    final digit0 = LogicalKeyboardKey.digit0.keyId;
    final digit9 = LogicalKeyboardKey.digit9.keyId;
    if (keyId >= digit0 && keyId <= digit9) {
      return String.fromCharCode('0'.codeUnitAt(0) + keyId - digit0);
    }
    return null;
  }

  void _handlePointerScroll(Offset delta) {
    if (delta.dx.abs() > delta.dy.abs()) {
      _jumpBy(_hScrollBody, delta.dx);
      return;
    }
    _jumpBy(_vScrollBody, delta.dy);
  }

  void _jumpBy(ScrollController controller, double delta) {
    if (!controller.hasClients || delta == 0) return;
    final position = controller.position;
    controller.jumpTo(
      (position.pixels + delta).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
  }

  List<double> _initialWidths() {
    return [
      for (final column in widget.columns)
        math.max(column.initialWidth, column.minWidth),
    ];
  }

  bool _initialWidthsChanged(
    List<FortuneTableColumn<T>> oldColumns,
    List<FortuneTableColumn<T>> newColumns,
  ) {
    for (var index = 0; index < oldColumns.length; index += 1) {
      if (oldColumns[index].initialWidth != newColumns[index].initialWidth ||
          oldColumns[index].minWidth != newColumns[index].minWidth ||
          oldColumns[index].fillRemaining != newColumns[index].fillRemaining) {
        return true;
      }
    }
    return false;
  }

  void _syncAutoWidthsIfNeeded() {
    if (!widget.autoFitColumns || widget.columns.isEmpty) return;
    final signature = _autoFitSignature();
    if (_tableSignature == signature) return;
    _tableSignature = signature;
    _widths = _autoFitWidths();
  }

  String _autoFitSignature() {
    return [
      for (final column in widget.columns) column.header,
      for (final row in widget.rows)
        for (final column in widget.columns) column.text(row),
    ].join('\u001f');
  }

  List<double> _autoFitWidths() {
    final scaler = MediaQuery.of(context).textScaler;
    const style = TextStyle(fontSize: 14);
    return List<double>.generate(widget.columns.length, (index) {
      final column = widget.columns[index];
      var maxWidth = _measureText(column.header, style, scaler) + 24;
      for (final row in widget.rows) {
        final width = _measureText(column.text(row), style, scaler) + 24;
        if (width > maxWidth) maxWidth = width;
      }
      return maxWidth < column.minWidth ? column.minWidth : maxWidth;
    });
  }

  double _measureText(String text, TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    return painter.size.width;
  }

  List<double> _effectiveWidths(double viewportWidth) {
    final widths = List<double>.from(_widths);
    if (widths.isEmpty) return widths;
    final fillIndex = widget.columns.lastIndexWhere(
      (column) => column.fillRemaining,
    );
    final targetIndex = fillIndex >= 0
        ? fillIndex
        : (widget.fillLastColumn ? widths.length - 1 : -1);
    if (targetIndex < 0) return widths;
    final reserved =
        widget.rowNumberWidth +
        widths.asMap().entries.fold<double>(
          0,
          (sum, entry) => entry.key == targetIndex ? sum : sum + entry.value,
        );
    final remaining = viewportWidth - reserved;
    if (remaining > widths[targetIndex]) widths[targetIndex] = remaining;
    return widths;
  }

  Widget _buildHeader(List<double> widths) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(widths.length, (index) {
        return Container(
          width: widths[index],
          decoration: const BoxDecoration(
            color: _headerColor,
            border: Border(
              right: BorderSide(color: _headerSeparatorColor),
              bottom: BorderSide(color: _headerSeparatorColor),
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            widget.columns[index].header,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRow(T row, int rowIndex, List<double> widths) {
    final selected = _isRowSelected(rowIndex);
    final color =
        widget.rowColorBuilder?.call(row, rowIndex, selected) ??
        _rowColor(rowIndex, selected);
    return Listener(
      onPointerDown: widget.multiSelectionEnabled
          ? (event) => _handleRowPointerDown(rowIndex, event)
          : null,
      onPointerMove: widget.multiSelectionEnabled
          ? (event) => _handleRowPointerMove(rowIndex, event)
          : null,
      onPointerUp: widget.multiSelectionEnabled
          ? (_) => _endDragSelection()
          : null,
      onPointerCancel: widget.multiSelectionEnabled
          ? (_) => _endDragSelection()
          : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: (details) =>
            widget.onRowSecondaryTapDown?.call(row, rowIndex, details),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(widths.length, (columnIndex) {
            return _buildCell(
              row,
              rowIndex,
              columnIndex,
              widths[columnIndex],
              color,
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCell(
    T row,
    int rowIndex,
    int columnIndex,
    double width,
    Color color,
  ) {
    final column = widget.columns[columnIndex];
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        if (event.buttons == kPrimaryMouseButton) {
          _selectRow(row, rowIndex);
          widget.onCellActivated?.call(row, rowIndex, column.id);
        }
      },
      onPointerUp: (_) {
        if (_editingRowIndex != null &&
            (_editingRowIndex != rowIndex ||
                _editingColumnIndex != columnIndex)) {
          unawaited(_queueTextEditingCommit());
        }
      },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: color,
          border: const Border(
            right: BorderSide(color: _bodySeparatorColor),
            bottom: BorderSide(color: _bodySeparatorColor),
          ),
        ),
        alignment: column.isCheckbox ? Alignment.center : Alignment.centerLeft,
        padding: column.isCheckbox
            ? EdgeInsets.zero
            : _editingRowIndex == rowIndex &&
                  _editingColumnIndex == columnIndex
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 8),
        child: column.isCheckbox
            ? _FortuneTableCheckbox(
              key: ValueKey('fortune_table_checkbox_${column.id}_$rowIndex'),
              value:
                  column.checkboxController?.isChecked(column.id, rowIndex) ??
                  column.checkboxValueAt?.call(row, rowIndex) ??
                  column.checkboxValue?.call(row) ??
                  false,
              onChanged: (value) {
                column.checkboxController?.setChecked(
                  column.id,
                  rowIndex,
                  value,
                );
                final onCheckboxChangedAt = column.onCheckboxChangedAt;
                if (onCheckboxChangedAt != null) {
                  onCheckboxChangedAt(row, rowIndex, value);
                } else {
                  column.onCheckboxChanged?.call(row, value);
                }
              },
              )
            : _buildTextCell(row, rowIndex, columnIndex, column, color),
      ),
    );
  }

  Widget _buildTextCell(
    T row,
    int rowIndex,
    int columnIndex,
    FortuneTableColumn<T> column,
    Color cellColor,
  ) {
    if (_editingRowIndex == rowIndex && _editingColumnIndex == columnIndex) {
      return Focus(
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            _cancelTextEditing();
            return KeyEventResult.handled;
          }
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter) {
            _queueTextEditingCommit();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: SizedBox.expand(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cellColor,
              border: Border.all(color: _textEditorBorderColor, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: EditableText(
                controller: _textEditorController!,
                focusNode: _textEditorFocusNode!,
                autofocus: true,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF202124),
                ),
                cursorColor: Colors.black,
                backgroundCursorColor: const Color(0x330188FB),
                selectionColor: const Color(0x550188FB),
                selectionControls: desktopTextSelectionControls,
                mouseCursor: SystemMouseCursors.text,
                enableInteractiveSelection: true,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _queueTextEditingCommit(),
                onTapOutside: (_) => _queueTextEditingCommit(),
              ),
            ),
          ),
        ),
      );
    }
    return Listener(
      onPointerDown: (event) {
        if (event.buttons == kPrimaryMouseButton) {
          _focusedColumnIndex = columnIndex;
          _selectedIndex = rowIndex;
        }
      },
      onPointerUp: (_) => FocusScope.of(context).requestFocus(_focusNode),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTap: column.onDoubleTap != null
            ? () => column.onDoubleTap!(row, rowIndex)
            : _isTextEditable(column, row, rowIndex)
            ? () => _startTextEditing(row, rowIndex, columnIndex, column)
            : null,
        child: SizedBox.expand(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              column.text(row),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Color(0xFF202124)),
            ),
          ),
        ),
      ),
    );
  }

  bool _isTextEditable(FortuneTableColumn<T> column, T row, int rowIndex) {
    return column.onTextCommitted != null &&
        (column.isTextEditable?.call(row, rowIndex) ?? true);
  }

  void _startTextEditing(
    T row,
    int rowIndex,
    int columnIndex,
    FortuneTableColumn<T> column,
    {String? initialText}
  ) {
    if (!_isTextEditable(column, row, rowIndex)) return;
    _disposeTextEditor();
    _textEditorInitialValue = column.text(row);
    _textEditorController = TextEditingController(
      text: initialText ?? _textEditorInitialValue,
    );
    _textEditorController!.selection = TextSelection.collapsed(
      offset: _textEditorController!.text.length,
    );
    _textEditorFocusNode = FocusNode(debugLabel: 'FortuneTableTextEditor');
    setState(() {
      _selectedIndex = rowIndex;
      _focusedColumnIndex = columnIndex;
      _editingRowIndex = rowIndex;
      _editingColumnIndex = columnIndex;
    });
    _selectRowIndex(rowIndex);
    widget.onRowSelected?.call(row, rowIndex);
  }

  Future<void> _commitTextEditing() async {
    final rowIndex = _editingRowIndex;
    final columnIndex = _editingColumnIndex;
    final value = _textEditorController?.text;
    if (rowIndex == null ||
        columnIndex == null ||
        value == null ||
        rowIndex >= widget.rows.length ||
        columnIndex >= widget.columns.length) {
      _cancelTextEditing();
      return;
    }
    final row = widget.rows[rowIndex];
    final column = widget.columns[columnIndex];
    final changed = value != _textEditorInitialValue;
    setState(_clearTextEditingState);
    _restoreTableFocus();
    if (changed) {
      await column.onTextCommitted?.call(row, rowIndex, value);
    }
  }

  Future<void> _queueTextEditingCommit() {
    final pending = _pendingTextCommit;
    if (pending != null) return pending;
    late final Future<void> operation;
    operation = _commitTextEditing().whenComplete(() {
      if (identical(_pendingTextCommit, operation)) {
        _pendingTextCommit = null;
      }
    });
    _pendingTextCommit = operation;
    return operation;
  }

  Future<void> _commitAndWaitForTextEditing() async {
    if (_editingRowIndex != null) {
      await _queueTextEditingCommit();
      return;
    }
    await _pendingTextCommit;
  }

  void _cancelTextEditing() {
    if (_editingRowIndex == null) return;
    setState(_clearTextEditingState);
    _restoreTableFocus();
  }

  void _restoreTableFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  void _clearTextEditingState() {
    _editingRowIndex = null;
    _editingColumnIndex = null;
    _textEditorInitialValue = null;
    _disposeTextEditor();
  }

  void _disposeTextEditor() {
    _textEditorController?.dispose();
    _textEditorController = null;
    _textEditorFocusNode?.dispose();
    _textEditorFocusNode = null;
  }

  Widget _rowHeaderCell(String text, Color color, double height) {
    return Container(
      width: widget.rowNumberWidth,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: const Border(
          right: BorderSide(color: _headerSeparatorColor),
          bottom: BorderSide(color: _bodySeparatorColor),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  Color _rowColor(int rowIndex, bool selected) {
    if (selected) return _selectedRowColor;
    return rowIndex.isEven ? Colors.white : _alternateRowColor;
  }

  bool _isRowSelected(int rowIndex) {
    if (widget.multiSelectionEnabled) {
      return widget.selectionController?.isSelected(rowIndex) ?? false;
    }
    return _selectedIndex == rowIndex;
  }

  void _selectRow(T row, int rowIndex) {
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editingRowIndex == null) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
    if (_selectedIndex != rowIndex) {
      setState(() => _selectedIndex = rowIndex);
    }
    _selectRowIndex(rowIndex);
    widget.onRowSelected?.call(row, rowIndex);
  }

  void _selectRowIndex(int rowIndex) {
    if (!widget.multiSelectionEnabled) return;
    final controller = widget.selectionController;
    if (controller == null) return;
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isShiftPressed && _selectionAnchorIndex != null) {
      controller.selectRange(_selectionAnchorIndex!, rowIndex);
      return;
    }
    if (keyboard.isControlPressed) {
      controller.toggleSelected(rowIndex);
      _selectionAnchorIndex = rowIndex;
      return;
    }
    controller.setSelectedRows(<int>{rowIndex});
    _selectionAnchorIndex = rowIndex;
  }

  void _handleRowPointerDown(int rowIndex, PointerDownEvent event) {
    if (event.buttons != kPrimaryMouseButton) return;
    _focusNode.requestFocus();
    _dragSelectionStartIndex = rowIndex;
  }

  void _handleRowPointerMove(int rowIndex, PointerMoveEvent event) {
    if (event.buttons != kPrimaryMouseButton) return;
    final dragStartIndex = _dragSelectionStartIndex;
    final controller = widget.selectionController;
    if (dragStartIndex == null || controller == null) return;
    final deltaRows = (event.localPosition.dy / widget.rowHeight).floor();
    final targetIndex = (rowIndex + deltaRows).clamp(0, widget.rows.length - 1);
    controller.selectRange(dragStartIndex, targetIndex);
  }

  void _endDragSelection() {
    _dragSelectionStartIndex = null;
  }

  void _syncCheckboxControllerListeners(
    List<FortuneTableColumn<T>> oldColumns,
  ) {
    final nextControllers = widget.columns
        .map((column) => column.checkboxController)
        .whereType<FortuneTableCheckboxController>()
        .toSet();
    final oldControllers = oldColumns
        .map((column) => column.checkboxController)
        .whereType<FortuneTableCheckboxController>()
        .toSet();

    for (final controller in oldControllers.difference(nextControllers)) {
      controller.removeListener(_handleCheckboxControllerChanged);
    }
    for (final controller in nextControllers.difference(_checkboxControllers)) {
      controller.addListener(_handleCheckboxControllerChanged);
    }
    _checkboxControllers = nextControllers;
  }

  void _handleCheckboxControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleSelectionControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleFocusControllerChanged() {
    final controller = widget.focusController;
    final rowIndex = controller?.rowIndex;
    final columnId = controller?.columnId;
    if (rowIndex == null ||
        columnId == null ||
        rowIndex >= widget.rows.length) {
      return;
    }
    final columnIndex = widget.columns.indexWhere(
      (column) => column.id == columnId,
    );
    if (columnIndex < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusedColumnIndex = columnIndex;
      _selectedIndex = rowIndex;
      _selectionAnchorIndex = rowIndex;
      widget.selectionController?.setSelectedRows([rowIndex]);
      _focusNode.requestFocus();
      _revealCell(rowIndex, columnIndex);
      setState(() {});
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _revealCell(int rowIndex, int columnIndex) {
    if (_vScrollBody.hasClients) {
      _revealRange(
        _vScrollBody,
        rowIndex * widget.rowHeight,
        (rowIndex + 1) * widget.rowHeight,
      );
    }
    if (_hScrollBody.hasClients &&
        columnIndex < _effectiveColumnWidths.length) {
      final start = _effectiveColumnWidths
          .take(columnIndex)
          .fold<double>(0, (sum, width) => sum + width);
      _revealRange(
        _hScrollBody,
        start,
        start + _effectiveColumnWidths[columnIndex],
      );
    }
  }

  void _revealRange(ScrollController controller, double start, double end) {
    final position = controller.position;
    var target = position.pixels;
    if (start < target) {
      target = start;
    } else if (end > target + position.viewportDimension) {
      target = end - position.viewportDimension;
    }
    controller.jumpTo(target.clamp(0, position.maxScrollExtent).toDouble());
  }

  void _syncHorizontalFromBody() {
    if (_syncingHorizontal) return;
    if (!_hScrollBody.hasClients || !_hScrollHeader.hasClients) return;
    _syncingHorizontal = true;
    _hScrollHeader.jumpTo(
      _hScrollBody.offset.clamp(
        _hScrollHeader.position.minScrollExtent,
        _hScrollHeader.position.maxScrollExtent,
      ),
    );
    _syncingHorizontal = false;
  }

  void _syncHorizontalFromHeader() {
    if (_syncingHorizontal) return;
    if (!_hScrollBody.hasClients || !_hScrollHeader.hasClients) return;
    _syncingHorizontal = true;
    _hScrollBody.jumpTo(
      _hScrollHeader.offset.clamp(
        _hScrollBody.position.minScrollExtent,
        _hScrollBody.position.maxScrollExtent,
      ),
    );
    _syncingHorizontal = false;
  }

  void _syncVerticalFromBody() {
    if (_syncingVertical) return;
    if (!_vScrollBody.hasClients || !_vScrollIndex.hasClients) return;
    _syncingVertical = true;
    _vScrollIndex.jumpTo(
      _vScrollBody.offset.clamp(
        _vScrollIndex.position.minScrollExtent,
        _vScrollIndex.position.maxScrollExtent,
      ),
    );
    _syncingVertical = false;
  }

  void _syncVerticalFromIndex() {
    if (_syncingVertical) return;
    if (!_vScrollBody.hasClients || !_vScrollIndex.hasClients) return;
    _syncingVertical = true;
    _vScrollBody.jumpTo(
      _vScrollIndex.offset.clamp(
        _vScrollBody.position.minScrollExtent,
        _vScrollBody.position.maxScrollExtent,
      ),
    );
    _syncingVertical = false;
  }

  void _scheduleRectReport() {
    if (widget.onRectChanged == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.onRectChanged == null) return;
      final renderObject = context.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;
      final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
      final last = _lastReportedRect;
      if (last != null && _sameRect(last, rect)) return;
      _lastReportedRect = rect;
      widget.onRectChanged?.call(rect);
    });
  }

  bool _sameRect(Rect left, Rect right) {
    return (left.left - right.left).abs() < 0.5 &&
        (left.top - right.top).abs() < 0.5 &&
        (left.width - right.width).abs() < 0.5 &&
        (left.height - right.height).abs() < 0.5;
  }
}

class _FortuneTableCheckbox extends StatelessWidget {
  const _FortuneTableCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: SizedBox.square(
        dimension: _FortuneTableState._checkboxSize + 10,
        child: Center(
          child: CustomPaint(
            size: const Size.square(_FortuneTableState._checkboxSize),
            painter: _FortuneTableCheckboxPainter(value),
          ),
        ),
      ),
    );
  }
}

class _FortuneTableCheckboxPainter extends CustomPainter {
  const _FortuneTableCheckboxPainter(this.checked);

  final bool checked;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = Colors.white);
    canvas.drawRect(
      rect.deflate(0.5),
      Paint()
        ..color = _FortuneTableState._checkboxBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    if (!checked) return;
    final path = Path()
      ..moveTo(rect.left + 3, rect.center.dy)
      ..lineTo(rect.left + 5.5, rect.bottom - 3)
      ..lineTo(rect.right - 3, rect.top + 3);
    canvas.drawPath(
      path,
      Paint()
        ..color = _FortuneTableState._checkboxCheckColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _FortuneTableCheckboxPainter oldDelegate) {
    return oldDelegate.checked != checked;
  }
}
