// test/core/presentation/services/share_delivery_test.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:emerge_app/core/presentation/services/share_delivery.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  final String tempDir;
  _FakePathProviderPlatform(this.tempDir);

  @override
  Future<String?> getTemporaryPath() async => tempDir;
}

void main() {
  final bytes = Uint8List.fromList(List<int>.generate(16, (i) => i));
  late Directory tempDir;
  late PathProviderPlatform previous;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('share_delivery_test');
    previous = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() {
    PathProviderPlatform.instance = previous;
    tempDir.deleteSync(recursive: true);
  });

  test('web branch builds in-memory XFiles (no disk writes)', () async {
    final files = await buildShareFiles(
      fileNames: const ['a.png', 'b.png'],
      images: [bytes, bytes],
      web: true,
    );

    expect(files, hasLength(2));
    expect(files[0].mimeType, 'image/png');
    expect(files[1].mimeType, 'image/png');
    // Content stays in memory — readAsBytes round-trips.
    expect(await files[0].readAsBytes(), bytes);
    expect(await files[1].readAsBytes(), bytes);
    // Nothing was materialized on disk by the web path.
    expect(tempDir.listSync(), isEmpty);
  });

  test(
    'native branch writes temp files and returns path-based XFiles',
    () async {
      final files = await buildShareFiles(
        fileNames: const ['a.png', 'b.png'],
        images: [bytes, bytes],
        web: false,
      );

      expect(files, hasLength(2));
      expect(files[0].mimeType, 'image/png');
      final written = tempDir
          .listSync()
          .whereType<File>()
          .map((f) => f.path.split('/').last)
          .toList();
      expect(written.toSet(), {'a.png', 'b.png'});
      expect(await files[0].readAsBytes(), bytes);
    },
  );

  test('maps share_plus results to our outcome enum', () {
    expect(
      mapShareResult(const ShareResult('x', ShareResultStatus.success)),
      ShareDeliveryResult.success,
    );
    expect(
      mapShareResult(const ShareResult('x', ShareResultStatus.dismissed)),
      ShareDeliveryResult.dismissed,
    );
    expect(
      mapShareResult(const ShareResult('x', ShareResultStatus.unavailable)),
      ShareDeliveryResult.failed,
    );
  });

  test('sharePngBytes never throws for the bytes delivered', () async {
    // With no native share channel registered, the SharePlus call fails —
    // the helper must return failed rather than throwing.
    final result = await sharePngBytes(
      bytes: bytes,
      fileName: 'emerge_share.png',
      text: 'Join my tribe on Emerge!',
      web: true,
    );
    expect(result, ShareDeliveryResult.failed);
  });
}
