// lib/core/presentation/services/shareable_image_exporter.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:emerge_app/core/presentation/widgets/shareable/shareable_card.dart';
import 'package:emerge_app/core/presentation/widgets/shareable/shareable_card_data.dart';

/// Renders a [ShareableCardData] offscreen to PNG bytes.
///
/// The card is inserted into the app's [Overlay] at opacity 0 (invisible,
/// never flashes), captured via [RenderRepaintBoundary.toImage] on the next
/// frame, then removed. Mirrors the `timeline_share_preview.dart` pattern.
class ShareableImageExporter {
  static Future<Uint8List?> renderPng(
    BuildContext context,
    ShareableCardData data, {
    double pixelRatio = 3.0,
  }) {
    final boundaryKey = GlobalKey();
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return Future.value(null);

    final completer = Completer<Uint8List?>();
    // Positioned far off-screen: painted (so toImage works) but never seen.
    // Opacity(0) would skip painting the child, making the capture fail.
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -10000,
        top: -10000,
        child: IgnorePointer(
          child: RepaintBoundary(
            key: boundaryKey,
            // 360x640 logical = 1080x1920 at pixelRatio 3.0 (9:16).
            child: SizedBox(
              width: 360,
              height: 640,
              child: ShareableCard(data: data),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final boundary =
            boundaryKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
        if (boundary == null) {
          completer.complete(null);
          return;
        }
        final image = await boundary.toImage(pixelRatio: pixelRatio);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        completer.complete(byteData?.buffer.asUint8List());
      } catch (e) {
        completer.complete(null);
      } finally {
        entry.remove();
      }
    });

    return completer.future;
  }
}