import 'package:flutter/material.dart';
import 'package:label_manager/page_label_sheet/label_sheet_native_open_xml.dart';
import 'package:label_manager/page_label_sheet/label_sheet_rtf_import.dart';
import 'package:label_manager/utils/log_context.dart';

class LabelSheetRtfPreview extends StatefulWidget {
  const LabelSheetRtfPreview({
    super.key,
    required this.rtf,
    this.width,
    this.height,
    this.widthMm = 100,
    this.heightMm = 100,
    this.padding = defaultPadding,
    this.onImageSizeResolved,
  });

  final String rtf;
  final int? width;
  final int? height;
  final int widthMm;
  final int heightMm;
  final EdgeInsets padding;
  final ValueChanged<Size>? onImageSizeResolved;

  static const EdgeInsets defaultPadding = EdgeInsets.fromLTRB(4, 17, 4, 4);
  static const double _richEditEffectiveDpi = 144;
  static const double _minPreviewCaptureScale = 2.0;
  static const double _maxPreviewCaptureScale = 4.0;
  static const double _referencePreviewDevicePixelRatio = 2.0;
  static const double _captureOverflowWidthFactor = 2.5;
  static const double _captureOverflowHeightFactor = 1.5;

  static int pixelsForMm(int mm) {
    return (mm / 25.4 * _richEditEffectiveDpi).round().clamp(1, 4096);
  }

  @override
  State<LabelSheetRtfPreview> createState() => _LabelSheetRtfPreviewState();
}

class _LabelSheetRtfPreviewState extends State<LabelSheetRtfPreview> {
  late Future<LabelSheetNativeRtfPngImage?> _imageFuture;
  Size? _lastNotifiedImageSize;

  @override
  void initState() {
    super.initState();
    _imageFuture = _capture();
  }

  @override
  void didUpdateWidget(covariant LabelSheetRtfPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rtf != widget.rtf ||
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height ||
        oldWidget.widthMm != widget.widthMm ||
        oldWidget.heightMm != widget.heightMm ||
        oldWidget.padding != widget.padding) {
      _imageFuture = _capture();
    }
  }

  Future<LabelSheetNativeRtfPngImage?> _capture() async {
    if (!labelSheetLooksLikeRichEditRtf(widget.rtf)) {
      return null;
    }
    final logicalWidth =
        widget.width ?? LabelSheetRtfPreview.pixelsForMm(widget.widthMm);
    final logicalHeight =
        widget.height ?? LabelSheetRtfPreview.pixelsForMm(widget.heightMm);
    final captureScale = _captureScaleFor(logicalWidth, logicalHeight);
    final captureLogicalWidth =
        (logicalWidth * LabelSheetRtfPreview._captureOverflowWidthFactor)
            .round();
    final captureLogicalHeight =
        (logicalHeight * LabelSheetRtfPreview._captureOverflowHeightFactor)
            .round();
    final captureWidth = (captureLogicalWidth * captureScale).round();
    final captureHeight = (captureLogicalHeight * captureScale).round();
    debugLog(
      'capture logical=${logicalWidth}x$logicalHeight '
      'canvas=${captureLogicalWidth}x$captureLogicalHeight '
      'px=${captureWidth}x$captureHeight scale=${captureScale.toStringAsFixed(2)}',
    );
    final captured = await labelSheetCaptureRtfNativePngImage(
      widget.rtf,
      width: captureWidth,
      height: captureHeight,
      widthMm: widget.widthMm,
      heightMm: widget.heightMm,
      renderScale: captureScale,
    );
    Size? imageSize;
    if (captured != null) {
      final displayScale = _displayScaleFor(captured);
      imageSize = Size(
        captured.width / displayScale,
        captured.height / displayScale,
      );
    }
    if (mounted && imageSize != null && imageSize != _lastNotifiedImageSize) {
      final resolvedImageSize = imageSize;
      _lastNotifiedImageSize = resolvedImageSize;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onImageSizeResolved?.call(resolvedImageSize);
        }
      });
    }
    return captured;
  }

  double _displayScaleFor(LabelSheetNativeRtfPngImage captured) {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    final devicePixelRatio = views.isNotEmpty
        ? views.first.devicePixelRatio
        : LabelSheetRtfPreview._referencePreviewDevicePixelRatio;
    final displayScale =
        captured.scale *
        devicePixelRatio /
        LabelSheetRtfPreview._referencePreviewDevicePixelRatio;
    return displayScale.clamp(
      0.75,
      LabelSheetRtfPreview._maxPreviewCaptureScale,
    );
  }

  double _captureScaleFor(int logicalWidth, int logicalHeight) {
    final baseWidth = LabelSheetRtfPreview.pixelsForMm(widget.widthMm);
    final baseHeight = LabelSheetRtfPreview.pixelsForMm(widget.heightMm);
    final resizeScale = [
      logicalWidth / baseWidth,
      logicalHeight / baseHeight,
      1.0,
    ].reduce((a, b) => a > b ? a : b);
    return (resizeScale * LabelSheetRtfPreview._minPreviewCaptureScale).clamp(
      LabelSheetRtfPreview._minPreviewCaptureScale,
      LabelSheetRtfPreview._maxPreviewCaptureScale,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: FutureBuilder<LabelSheetNativeRtfPngImage?>(
        future: _imageFuture,
        builder: (context, snapshot) {
          final captured = snapshot.data;
          if (captured != null && captured.bytes.isNotEmpty) {
            final displayScale = _displayScaleFor(captured);
            return Padding(
              padding: widget.padding,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: captured.width / displayScale,
                      height: captured.height / displayScale,
                      child: Image.memory(
                        captured.bytes,
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  );
                },
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return const SizedBox.expand();
        },
      ),
    );
  }
}
