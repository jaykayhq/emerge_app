// lib/core/presentation/services/share_delivery.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Outcome of a share call — mirrors [ShareResultStatus] so callers can
/// distinguish a real failure from a user dismissal.
enum ShareDeliveryResult {
  /// The share sheet/download was handed off successfully.
  success,

  /// The user cancelled/dismissed the share sheet.
  dismissed,

  /// Sharing itself failed.
  failed,
}

/// Builds the [XFile] payload for a share call.
///
/// Web: in-memory files so share_plus can fall back to a browser download
/// (path-based files have no meaning inside a browser).
/// Native: real temp files — the OS share sheet requires paths.
Future<List<XFile>> buildShareFiles({
  required List<String> fileNames,
  required List<Uint8List> images,
  bool web = kIsWeb,
}) async {
  assert(fileNames.length == images.length);
  if (web) {
    return [
      for (var i = 0; i < images.length; i++)
        XFile.fromData(
          images[i],
          mimeType: 'image/png',
          name: fileNames[i],
          length: images[i].length,
        ),
    ];
  }
  final tempDir = await getTemporaryDirectory();
  final files = <XFile>[];
  for (var i = 0; i < images.length; i++) {
    final file = File('${tempDir.path}/${fileNames[i]}');
    await file.writeAsBytes(images[i]);
    files.add(XFile(file.path, mimeType: 'image/png'));
  }
  return files;
}

/// Maps a share_plus [ShareResult] to our outcome so callers never depend on
/// the plugin's enum directly.
ShareDeliveryResult mapShareResult(ShareResult result) {
  return switch (result.status) {
    ShareResultStatus.success => ShareDeliveryResult.success,
    ShareResultStatus.dismissed => ShareDeliveryResult.dismissed,
    ShareResultStatus.unavailable => ShareDeliveryResult.failed,
  };
}

/// Shares one or more PNG images on every platform.
///
/// Never throws. Returns the share outcome so callers can decide whether a
/// dismissal is a failure (it isn't) or simply close.
Future<ShareDeliveryResult> sharePngImages({
  required List<String> fileNames,
  required List<Uint8List> images,
  required String text,
  bool web = kIsWeb,
}) async {
  try {
    final files = await buildShareFiles(
      fileNames: fileNames,
      images: images,
      web: web,
    );
    final result = await SharePlus.instance.share(
      ShareParams(
        files: files,
        text: text,
        // Native sheets otherwise infer names from temp paths; keep the
        // presented filename identical across platforms.
        fileNameOverrides: web ? null : fileNames,
      ),
    );
    return mapShareResult(result);
  } catch (_) {
    return ShareDeliveryResult.failed;
  }
}

/// Convenience for single-image shares.
Future<ShareDeliveryResult> sharePngBytes({
  required String fileName,
  required Uint8List bytes,
  required String text,
  bool web = kIsWeb,
}) {
  return sharePngImages(
    fileNames: [fileName],
    images: [bytes],
    text: text,
    web: web,
  );
}
