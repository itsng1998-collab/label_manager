import 'package:flutter/material.dart';
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:label_manager/database/db_scale_connect_info.dart';
import 'package:label_manager/models/scale_output.dart';
import 'package:label_manager/page_home/table_search.dart';
import 'package:label_manager/page_label_sheet/label_sheet_workbench.dart';
import 'package:label_manager/widgets/vertical_pane_splitter.dart';

Future<ScaleConnectInfo?> showScaleConnectSettingsDialog({
  required BuildContext context,
  required ScaleConnectInfo initial,
  required List<String> availablePorts,
}) async {
  final portItems = <String>{
    if (initial.portName.trim().isNotEmpty) initial.portName.trim(),
    ...availablePorts.where((port) => port.trim().isNotEmpty),
  }.toList(growable: false)
    ..sort();
  final baudRateController = TextEditingController(text: '${initial.baudRate}');
  final dataBitController = TextEditingController(text: '${initial.dataBit}');
  final stopBitController = TextEditingController(text: '${initial.stopBit}');
  var selectedPort = initial.portName;
  var parity = initial.parityBit;
  String? errorText;
  try {
    return await showDialog<ScaleConnectInfo>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('저울 연결 설정'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: portItems.contains(selectedPort) ? selectedPort : null,
                  items: [
                    for (final port in portItems)
                      DropdownMenuItem<String>(value: port, child: Text(port)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() {
                      selectedPort = value;
                      errorText = null;
                    });
                  },
                  decoration: const InputDecoration(labelText: '포트'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: baudRateController,
                  decoration: const InputDecoration(labelText: 'Baud Rate'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dataBitController,
                        decoration: const InputDecoration(labelText: 'Data Bit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: stopBitController,
                        decoration: const InputDecoration(labelText: 'Stop Bit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: parity,
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('None')),
                    DropdownMenuItem(value: 'odd', child: Text('Odd')),
                    DropdownMenuItem(value: 'even', child: Text('Even')),
                    DropdownMenuItem(value: 'mark', child: Text('Mark')),
                    DropdownMenuItem(value: 'space', child: Text('Space')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() {
                      parity = value;
                      errorText = null;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Parity'),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      errorText!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final baudRate = int.tryParse(baudRateController.text.trim());
                final dataBit = int.tryParse(dataBitController.text.trim());
                final stopBit = int.tryParse(stopBitController.text.trim());
                if (selectedPort.trim().isEmpty ||
                    baudRate == null ||
                    dataBit == null ||
                    stopBit == null ||
                    !scaleOutputIsSupportedBaudRate(baudRate) ||
                    !scaleOutputIsSupportedDataBit(dataBit) ||
                    !scaleOutputIsSupportedStopBit(stopBit)) {
                  setDialogState(() {
                    errorText = '지원하는 포트 설정값을 확인해 주세요.';
                  });
                  return;
                }
                Navigator.of(dialogContext).pop(
                  ScaleConnectInfo(
                    portName: selectedPort.trim(),
                    baudRate: baudRate,
                    dataBit: dataBit,
                    stopBit: stopBit,
                    parityBit: parity,
                    autoPrint: initial.autoPrint,
                  ),
                );
              },
              child: const Text('적용'),
            ),
          ],
        ),
      ),
    );
  } finally {
    baudRateController.dispose();
    dataBitController.dispose();
    stopBitController.dispose();
  }
}

class ScaleOutputProgressDialog extends StatelessWidget {
  const ScaleOutputProgressDialog({
    super.key,
    required this.controller,
    required this.onCancel,
  });

  final ScaleOutputSessionController controller;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('저울 라벨 발행'),
      content: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Text(
          '${controller.issueUnitNumber}/${controller.issueTotalUnits}번째를 발행중입니다...',
        ),
      ),
      actions: [
        TextButton(onPressed: onCancel, child: const Text('취소')),
      ],
    );
  }
}

class ScaleOutputPage extends StatefulWidget {
  const ScaleOutputPage({
    super.key,
    required this.controller,
    required this.previewBuilder,
    required this.onPrinterSettings,
    required this.onScaleSettings,
    required this.onReloadAll,
    required this.onReloadSelected,
    required this.onIssue,
    required this.onCancelIssue,
    required this.onConnect,
    required this.onDisconnect,
    this.pageController,
    this.useScale = false,
    this.busy = false,
  });

  final ScaleOutputSessionController controller;
  final Widget Function(
    ScaleOutputRowDraft row,
    LabelSheetZoomController zoomController,
  )
  previewBuilder;
  final VoidCallback onPrinterSettings;
  final VoidCallback onScaleSettings;
  final VoidCallback onReloadAll;
  final VoidCallback onReloadSelected;
  final VoidCallback onIssue;
  final VoidCallback onCancelIssue;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final ScaleOutputPageController? pageController;
  final bool useScale;
  final bool busy;

  @override
  State<ScaleOutputPage> createState() => _ScaleOutputPageState();
}

class _ScaleOutputPageState extends State<ScaleOutputPage> {
  static const double _splitterWidth = 7;
  static const double _minimumPaneWidth = 300;
  static const int _defaultPreviewZoomPercent = 150;
  static const EdgeInsets _menuItemPadding = EdgeInsets.symmetric(horizontal: 12);
  static const String _menuReloadAll = 'reloadAll';
  static const String _menuReloadSelected = 'reloadSelected';

  final FortuneTableEditingController _editingController =
      FortuneTableEditingController();
    final FortuneTableSelectionController _selectionController =
      FortuneTableSelectionController();
    final FortuneTableFocusController _focusController =
      FortuneTableFocusController();
  final FortuneTableScrollController _tableScrollController =
      FortuneTableScrollController();
  final LabelSheetZoomController _zoomController = LabelSheetZoomController(
    initialPercent: _defaultPreviewZoomPercent,
  );
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final FocusNode _weightFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();
  double _tableFraction = 0.55;
  int? _lastSelectedItemId;
  String _activeSearchColumnId = 'itemName';
  int _searchStartIndex = 0;
  bool _syncingTextControllers = false;
  bool _contextMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _lastSelectedItemId = widget.controller.selectedItemId;
    widget.controller.addListener(_handleChanged);
    _attachController();
    _syncTextControllers(force: true);
  }

  @override
  void didUpdateWidget(covariant ScaleOutputPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleChanged);
      widget.controller.addListener(_handleChanged);
      _lastSelectedItemId = widget.controller.selectedItemId;
      _syncTextControllers(force: true);
    }
    if (oldWidget.pageController != widget.pageController) {
      oldWidget.pageController?.detach(this);
      _attachController();
    }
  }

  void _attachController() {
    widget.pageController?.attach(
      owner: this,
      search: _search,
      resetSearch: () => _searchStartIndex = 0,
      commitEditing: () async {
        _weightFocusNode.unfocus();
        _priceFocusNode.unfocus();
      },
      hasActiveEditing: () => _weightFocusNode.hasFocus || _priceFocusNode.hasFocus,
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChanged);
    widget.pageController?.detach(this);
    _selectionController.dispose();
    _focusController.dispose();
    _weightFocusNode.dispose();
    _priceFocusNode.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (!mounted) return;
    if (_lastSelectedItemId != widget.controller.selectedItemId) {
      _lastSelectedItemId = widget.controller.selectedItemId;
      _syncTextControllers(force: true);
    } else {
      _syncTextControllers();
    }
    setState(() {});
  }

  void _syncTextControllers({bool force = false}) {
    if (_syncingTextControllers) return;
    final row = widget.controller.selectedRow;
    final weight = row?.weightText ?? '';
    final price = row?.priceText ?? '';
    _syncingTextControllers = true;
    try {
      if (force || !_weightFocusNode.hasFocus) {
        if (_weightController.text != weight) {
          _weightController.text = weight;
          _weightController.selection = TextSelection.collapsed(
            offset: _weightController.text.length,
          );
        }
      }
      if (force || !_priceFocusNode.hasFocus) {
        if (_priceController.text != price) {
          _priceController.text = price;
          _priceController.selection = TextSelection.collapsed(
            offset: _priceController.text.length,
          );
        }
      }
    } finally {
      _syncingTextControllers = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.controller.rows;
    final selectedIndex = rows.indexWhere(
      (row) => row.itemId == widget.controller.selectedItemId,
    );
    final table = FortuneTable<ScaleOutputRowDraft>(
      rows: rows,
      columns: _columns,
      autoFitColumns: false,
      selectedIndex: selectedIndex < 0 ? null : selectedIndex,
      selectionController: _selectionController,
      focusController: _focusController,
      editingController: _editingController,
      scrollController: _tableScrollController,
      onCellActivated: (_, _, columnId) {
        if (_activeSearchColumnId != columnId) {
          _searchStartIndex = 0;
        }
        _activeSearchColumnId = columnId;
      },
      onRowSelected: (row, _) => widget.controller.selectItem(row.itemId),
      onRowSecondaryTapDown: (row, _, details) {
        widget.controller.selectItem(row.itemId);
        _showContextMenu(details);
      },
    );
    final selected = selectedIndex < 0 ? null : rows[selectedIndex];
    final preview = selected == null
        ? const Center(child: Text('발행할 품목을 선택하세요.'))
        : KeyedSubtree(
            key: ValueKey('scale-output-preview-slot:${selected.itemId}'),
            child: widget.previewBuilder(selected, _zoomController),
          );

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 1080) {
                return Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onSecondaryTapDown: _showContextMenu,
                        child: table,
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(child: _rightPane(preview)),
                  ],
                );
              }
              final availableWidth = constraints.maxWidth - _splitterWidth;
              final minimumFraction = _minimumPaneWidth / availableWidth;
              final maximumFraction = 1 - minimumFraction;
              final tableFraction = _tableFraction.clamp(
                minimumFraction,
                maximumFraction,
              );
              return Row(
                children: [
                  SizedBox(
                    width: availableWidth * tableFraction,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onSecondaryTapDown: _showContextMenu,
                      child: table,
                    ),
                  ),
                  VerticalPaneSplitter(
                    width: _splitterWidth,
                    onDrag: (delta) {
                      setState(() {
                        _tableFraction = (_tableFraction + delta / availableWidth)
                            .clamp(minimumFraction, maximumFraction);
                      });
                    },
                  ),
                  Expanded(child: _rightPane(preview)),
                ],
              );
            },
          ),
        ),
        const Divider(height: 1),
        _commandBar(),
      ],
    );
  }

  TableSearchResult _search(String query) {
    final rows = widget.controller.rows;
    final columns = _columns;
    final columnIndex = columns.indexWhere(
      (column) => column.id == _activeSearchColumnId,
    );
    if (rows.isEmpty || columnIndex < 0) {
      return TableSearchResult.unavailable;
    }
    final column = columns[columnIndex];
    for (var index = _searchStartIndex; index < rows.length; index += 1) {
      if (!column.text(rows[index]).contains(query)) continue;
      final row = rows[index];
      _searchStartIndex = index + 1;
      _selectionController.setSelectedRows([index]);
      widget.controller.selectItem(row.itemId);
      _focusController.focusCell(index, column.id);
      return TableSearchResult.found;
    }
    return TableSearchResult.reachedEnd;
  }

  Future<void> _showContextMenu(TapDownDetails details) async {
    if (_contextMenuOpen) return;
    _contextMenuOpen = true;
    try {
      final command = await showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          details.globalPosition.dx,
          details.globalPosition.dy,
          details.globalPosition.dx,
          details.globalPosition.dy,
        ),
        popUpAnimationStyle: AnimationStyle.noAnimation,
        items: const [
          PopupMenuItem<String>(
            value: _menuReloadAll,
            height: fortuneContextMenuRowHeight,
            padding: _menuItemPadding,
            child: Text('전체내용 다시가져오기'),
          ),
          PopupMenuItem<String>(
            value: _menuReloadSelected,
            enabled: false,
            height: fortuneContextMenuRowHeight,
            padding: _menuItemPadding,
            child: Text('선택내용 다시가져오기'),
          ),
        ],
      );
      if (!mounted || command == null) return;
      switch (command) {
        case _menuReloadAll:
          widget.onReloadAll();
          break;
        case _menuReloadSelected:
          widget.onReloadSelected();
          break;
      }
    } finally {
      _contextMenuOpen = false;
    }
  }

  Widget _rightPane(Widget preview) {
    final row = widget.controller.selectedRow;
    return Column(
      children: [
        Expanded(child: preview),
        const Divider(height: 1),
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      row?.item.item.itemName ?? '선택된 품목 없음',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  LabelSheetZoomToolbar(controller: _zoomController),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.useScale) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: widget.busy
                          ? null
                          : widget.controller.connectionState ==
                                    ScaleOutputConnectionState.connected
                              ? widget.onDisconnect
                              : widget.onConnect,
                      icon: Icon(
                        widget.controller.connectionState ==
                                ScaleOutputConnectionState.connected
                            ? Icons.link_off
                            : Icons.link,
                        size: 18,
                      ),
                      label: Text(
                        widget.controller.connectionState ==
                                ScaleOutputConnectionState.connected
                            ? '연결 해제'
                            : '연결',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.busy ||
                              widget.controller.connectionState ==
                                  ScaleOutputConnectionState.connected ||
                              widget.controller.connectionState ==
                                  ScaleOutputConnectionState.connecting
                          ? null
                          : widget.onScaleSettings,
                      icon: const Icon(Icons.settings_input_component, size: 18),
                      label: const Text('저울 설정'),
                    ),
                    Text('상태: ${widget.controller.connectionStatusText}'),
                    Text('포트: ${widget.controller.currentPortName.isEmpty ? '-' : widget.controller.currentPortName}'),
                    Text(
                      '수신: ${widget.controller.lastReceivedWeightRaw.isEmpty ? '-' : widget.controller.lastReceivedWeightRaw}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      focusNode: _weightFocusNode,
                      enabled: !widget.busy,
                      decoration: const InputDecoration(
                        labelText: '중량',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (_syncingTextControllers) return;
                        widget.controller.updateSelectedWeight(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      focusNode: _priceFocusNode,
                      enabled: !widget.busy,
                      decoration: const InputDecoration(
                        labelText: '가격',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (_syncingTextControllers) return;
                        widget.controller.updateSelectedPrice(value);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _commandBar() => SizedBox(
    height: 48,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: widget.busy ? null : widget.onPrinterSettings,
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('프린터 설정'),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Tooltip(
              message: widget.controller.settings.printerName ?? '선택된 프린터 없음',
              child: Text(
                widget.controller.settings.printerName ?? '선택된 프린터 없음',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: widget.busy
                ? widget.onCancelIssue
                : widget.controller.rows.isEmpty
                    ? null
                    : widget.onIssue,
            icon: Icon(widget.busy ? Icons.stop : Icons.print, size: 18),
            label: Text(widget.busy ? '발행 취소' : '발행'),
          ),
          const Spacer(),
        ],
      ),
    ),
  );

  List<FortuneTableColumn<ScaleOutputRowDraft>> get _columns => [
    FortuneTableColumn(
      id: 'copies',
      header: '발행매수',
      initialWidth: 80,
      text: (row) => '${row.copies}',
    ),
    FortuneTableColumn(
      id: 'labelSize',
      header: '라벨크기명',
      initialWidth: 110,
      text: (row) => row.item.item.labelSizeName,
    ),
    FortuneTableColumn(
      id: 'itemName',
      header: '품명',
      initialWidth: 180,
      text: (row) => row.item.item.itemName,
    ),
    FortuneTableColumn(
      id: 'weight',
      header: '중량',
      initialWidth: 110,
      text: (row) => row.weightText,
    ),
    FortuneTableColumn(
      id: 'price',
      header: '가격',
      initialWidth: 110,
      text: (row) => row.priceText,
    ),
  ];
}