import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as widgets;
import 'package:fortune_sheet/fortune_sheet.dart';
import 'package:image/image.dart' as imglib;
import 'package:label_manager/features/label_sheet/presentation/label_sheet_image_import_preview_layout.dart';

class LabelSheetImageImportPreview extends StatefulWidget {
  const LabelSheetImageImportPreview({
    required this.imageBytes,
    required this.physicalSize,
    super.key,
  });

  final Uint8List? imageBytes;
  final FortuneSheetGridClientPhysicalSize physicalSize;

  @override
  State<LabelSheetImageImportPreview> createState() =>
      _LabelSheetImageImportPreviewState();
}

class _LabelSheetImageImportPreviewState
    extends State<LabelSheetImageImportPreview> {
  late imglib.Image? _decodedImage = _decodeImage(widget.imageBytes);

  @override
  void didUpdateWidget(covariant LabelSheetImageImportPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.imageBytes, widget.imageBytes)) {
      _decodedImage = _decodeImage(widget.imageBytes);
    }
  }

  static imglib.Image? _decodeImage(Uint8List? bytes) {
    return bytes == null ? null : imglib.decodeImage(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: labelSheetImageImportPreviewHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.45,
          ),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(labelSheetImageImportPreviewPadding),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageBytes = widget.imageBytes;
              if (imageBytes == null) {
                return Center(
                  child: Text(
                    '이미지 파일을 선택하세요.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                );
              }
              final decodedImage = _decodedImage;
              if (decodedImage == null) {
                return Center(
                  child: widgets.Image.memory(
                    imageBytes,
                    fit: BoxFit.contain,
                  ),
                );
              }
              final layout = labelSheetImageImportPreviewLayout(
                imageWidth: decodedImage.width,
                imageHeight: decodedImage.height,
                viewportWidth: constraints.maxWidth,
                viewportHeight: constraints.maxHeight,
                physicalSize: widget.physicalSize,
              );
              return ClipRect(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: layout.width,
                          height: layout.height,
                          child: widgets.Image.memory(
                            imageBytes,
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
