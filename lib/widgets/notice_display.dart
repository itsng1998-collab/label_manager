import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, LogicalKeyboardKey;
import 'package:http/http.dart' as http;
import 'package:label_manager/core/app.dart';
import 'package:label_manager/utils/regression_debug_log.dart';
import 'package:url_launcher/url_launcher.dart';

class NoticeDisplayPanel extends StatefulWidget {
  const NoticeDisplayPanel({
    super.key,
    required this.version,
    required this.content,
    this.editable = false,
    this.onVersionChanged,
    this.onContentChanged,
    this.initialFocusNode,
    this.contentFocusNode,
    this.contentFlex = 2,
    this.adFlex = 1,
  });

  final String version;
  final String content;
  final bool editable;
  final ValueChanged<String>? onVersionChanged;
  final ValueChanged<String>? onContentChanged;
  final FocusNode? initialFocusNode;
  final FocusNode? contentFocusNode;
  final int contentFlex;
  final int adFlex;

  @override
  State<NoticeDisplayPanel> createState() => _NoticeDisplayPanelState();
}

class _NoticeDisplayPanelState extends State<NoticeDisplayPanel> {
  late final TextEditingController _versionController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _versionController = TextEditingController(text: widget.version);
    _contentController = TextEditingController(text: widget.content);
  }

  @override
  void didUpdateWidget(covariant NoticeDisplayPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_versionController.text != widget.version) {
      _versionController.text = widget.version;
    }
    if (_contentController.text != widget.content) {
      _contentController.text = widget.content;
      RegressionDebugLog.event(
        'updateNotice',
        'displayContentSynced',
        fields: {
          'messageLength': _contentController.text.length,
          'editable': widget.editable,
        },
      );
    }
  }

  @override
  void dispose() {
    _versionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _insertNewline() {
    final value = _contentController.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final text = value.text.replaceRange(selection.start, selection.end, '\n');
    _contentController.value = value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: selection.start + 1),
      composing: TextRange.empty,
    );
    widget.onContentChanged?.call(text);
    RegressionDebugLog.event(
      'updateNoticeKeyboard',
      'newlineInserted',
      fields: {
        'messageLength': text.length,
        'selectionStart': selection.start,
        'selectionEnd': selection.end,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 240,
          child: TextFormField(
            focusNode: widget.initialFocusNode,
            controller: _versionController,
            readOnly: !widget.editable,
            decoration: const InputDecoration(labelText: '업데이트 버전'),
            onChanged: widget.editable ? widget.onVersionChanged : null,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                key: const ValueKey('notice-content-area'),
                flex: widget.contentFlex,
                child: CallbackShortcuts(
                  bindings: widget.editable
                      ? {
                          const SingleActivator(LogicalKeyboardKey.enter):
                              _insertNewline,
                          const SingleActivator(
                            LogicalKeyboardKey.enter,
                            alt: true,
                          ): _insertNewline,
                        }
                      : const {},
                  child: TextFormField(
                  focusNode: widget.contentFocusNode,
                  controller: _contentController,
                  readOnly: !widget.editable,
                  textInputAction: TextInputAction.newline,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: Color(0xFF1F1F1F),
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(14),
                  ),
                  onChanged: widget.editable ? widget.onContentChanged : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                key: const ValueKey('notice-ad-area'),
                flex: widget.adFlex,
                child: const NoticeAdBanner(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class NoticeAdBanner extends StatefulWidget {
  const NoticeAdBanner({super.key});

  @override
  State<NoticeAdBanner> createState() => _NoticeAdBannerState();
}

class _NoticeAdBannerState extends State<NoticeAdBanner> {
  Uint8List? _bytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (isShowLogo) _loadAd();
  }

  Future<void> _loadAd() async {
    setState(() => _loading = true);
    const url = 'https://itsng.co.kr/LabelManager/LabelManager_ITSad.bmp';

    try {
      final bust = DateTime.now().millisecondsSinceEpoch.toString();
      final uri = Uri.parse(url).replace(queryParameters: {'_ts': bust});
      final response = await http
          .get(uri, headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception('HTTP ${response.statusCode}');
      }
      if (!mounted) return;
      setState(() => _bytes = response.bodyBytes);
    } catch (_) {
      try {
        final fallback = await rootBundle.load(
          'assets/images/LabelManager_ITSad.bmp',
        );
        if (!mounted) return;
        setState(() => _bytes = fallback.buffer.asUint8List());
      } catch (_) {
        // 기존 자산도 없으면 placeholder를 유지한다.
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _bytes == null
        ? Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFEF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0x11000000)),
            ),
            alignment: Alignment.center,
            child: Text(
              _loading ? '다운로드 중...' : '광고 배너 이미지',
              style: const TextStyle(color: Color(0xFF666666)),
            ),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(
              _bytes!,
              fit: BoxFit.fill,
              alignment: Alignment.center,
            ),
          );

    return InkWell(
      onTap: _loading
          ? null
          : () async {
              await launchUrl(
                Uri.parse('https://itsngshop.com/index.html'),
                mode: LaunchMode.externalApplication,
              );
            },
      borderRadius: BorderRadius.circular(6),
      child: content,
    );
  }
}
