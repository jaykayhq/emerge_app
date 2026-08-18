// test/core/presentation/services/shareable_image_exporter_test.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emerge_app/core/presentation/services/shareable_image_exporter.dart';
import 'package:emerge_app/core/presentation/widgets/shareable/shareable_card_data.dart';

void main() {
  testWidgets('renderPng returns valid PNG bytes', (tester) async {
    const data = ShareableCardData(
      headline: 'TEST',
      stats: [ShareableStat(label: 'A', value: '1', color: Color(0xFF2BEE79))],
    );
    Uint8List? bytes;

    // The whole flow runs inside runAsync so the engine's toImage future is
    // created in the real event-loop zone (pump is allowed inside runAsync;
    // only reentrant runAsync calls are guarded).
    await tester.runAsync(() async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
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

    expect(bytes, isNotNull);
    // PNG magic header: 89 50 4E 47 0D 0A 1A 0A
    expect(
      bytes!.sublist(0, 8),
      [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
    );
  });
}