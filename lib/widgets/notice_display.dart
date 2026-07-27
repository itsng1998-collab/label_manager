import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:label_manager/core/app.dart';
import 'package:url_launcher/url_launcher.dart';

class NoticeDisplayPanel extends StatelessWidget {
  const NoticeDisplayPanel({
    super.key,
    required this.version,
    required this.content,
    this.editable = false,
    this.onVersionChanged,
    this.onContentChanged,
  });

  final String version;
  final String content;
  final bool editable;
  final ValueChanged<String>? onVersionChanged;
  final ValueChanged<String>? onContentChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 240,
          child: TextFormField(
            initialValue: version,
            readOnly: !editable,
            decoration: const InputDecoration(labelText: '업데이트 버전'),
            onChanged: editable ? onVersionChanged : null,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: content,
                  readOnly: !editable,
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
                  onChanged: editable ? onContentChanged : null,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: NoticeAdBanner()),
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
