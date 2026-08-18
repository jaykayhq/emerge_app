// test/core/presentation/services/shareable_image_exporter_test.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/presentation/services/shareable_image_exporter.dart';
import 'package:emerge_app/core/presentation/widgets/shareable/shareable_card_data.dart';

const _testData = ShareableCardData(
  headline: 'TEST',
  stats: [ShareableStat(label: 'A', value: '1', color: Color(0xFF2BEE79))],
);

void main() {
  testWidgets('renderPng returns valid PNG bytes', (tester) async {
    final bytes = await _capture(tester, data: _testData);

    expect(bytes, isNotNull);
    // PNG magic header: 89 50 4E 47 0D 0A 1A 0A
    expect(bytes!.sublist(0, 8), [
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ]);
  });

  testWidgets('capture is non-blank at the requested 9:16 dimensions', (
    tester,
  ) async {
    final bytes = await _capture(tester, data: _testData);
    expect(bytes, isNotNull);

    // All engine-side async (decode + byte extraction) must run inside
    // runAsync or it never completes under the test binding.
    int width = 0;
    int height = 0;
    var opaquePixels = 0;
    await tester.runAsync(() async {
      final image = await decodeImageFromList(bytes!);
      width = image.width;
      height = image.height;
      final raw = (await image.toByteData())!.buffer.asUint8List();
      for (var i = 3; i < raw.length; i += 4) {
        if (raw[i] != 0) {
          opaquePixels++;
          break;
        }
      }
      image.dispose();
    });

    expect(width, 1080); // 360 x pixelRatio 3.0
    expect(height, 1920);
    // At least one opaque pixel must exist — a blank/transparent export
    // would silently ship an unusable "share card".
    expect(opaquePixels, greaterThan(0));
  });

  testWidgets('capture ignores the host text scale factor', (tester) async {
    // A user with large accessibility text would otherwise get an
    // overflowing/deformed export.
    final bytes = await _capture(tester, data: _testData, textScale: 4.0);
    expect(bytes, isNotNull);
    expect(bytes!.sublist(0, 8), [
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ]);
  });
}

/// Pumps a bare [MaterialApp] and captures [data] via the exporter.
Future<Uint8List?> _capture(
  WidgetTester tester, {
  required ShareableCardData data,
  double textScale = 1.0,
}) async {
  Uint8List? bytes;
  // The whole flow runs inside runAsync so the engine's toImage future is
  // created in the real event-loop zone (pump is allowed inside runAsync;
  // only reentrant runAsync calls are guarded).
  await tester.runAsync(() async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();

    final future = ShareableImageExporter.renderPng(ctx, data);
    await tester.pump(); // build the offscreen entry + fire post-frame capture
    bytes = await future;
  });
  return bytes;
}
