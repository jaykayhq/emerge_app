import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Shared blueprint artwork that resolves a URL into either a network image
/// or the branded gradient fallback. Asset paths are no longer supported —
/// they resolve to the fallback.
class BlueprintArtwork extends StatelessWidget {
  final String? imageUrl;
  final bool useCachedNetworkImage;

  const BlueprintArtwork({
    super.key,
    required this.imageUrl,
    this.useCachedNetworkImage = false,
  });

  /// Returns [url] only when it points at a remote image; local paths and
  /// null/empty values resolve to null so the branded fallback renders.
  String? _resolve(String? url) {
    if (url == null || url.isEmpty) return null;
    return url.startsWith('http://') || url.startsWith('https://') ? url : null;
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolve(imageUrl);
    if (resolved == null) return const _Fallback();

    if (useCachedNetworkImage) {
      return CachedNetworkImage(
        imageUrl: resolved,
        fit: BoxFit.cover,
        placeholder: (context, url) => const _Fallback(),
        errorWidget: (context, url, error) => const _Fallback(),
      );
    }

    return Image.network(
      resolved,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const _Fallback(),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1B4E), Color(0xFF1A0A2E)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          size: 64,
          color: Colors.white10,
        ),
      ),
    );
  }
}
