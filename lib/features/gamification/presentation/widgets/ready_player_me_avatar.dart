import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ReadyPlayerMeAvatar extends StatelessWidget {
  final String modelUrl;
  final double? height;
  final double? width;

  const ReadyPlayerMeAvatar({
    super.key,
    required this.modelUrl,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: ModelViewer(
        src: modelUrl,
        alt: "A 3D model of an avatar",
        ar: true,
        autoRotate: true,
        cameraControls: true,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
