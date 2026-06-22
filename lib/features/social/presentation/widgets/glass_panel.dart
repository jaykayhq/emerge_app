import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/emerge_colors.dart';

enum GlassLevel {
  level1,
  level2,
  level3,
}

class GlassPanel extends StatefulWidget {
  final Widget child;
  final GlassLevel level;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool isElectric;
  final bool isViolet;
  final VoidCallback? onTap;

  const GlassPanel({
    super.key,
    required this.child,
    this.level = GlassLevel.level2,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 12,
    this.isElectric = false,
    this.isViolet = false,
    this.onTap,
  });

  @override
  State<GlassPanel> createState() => _GlassPanelState();
}

class _GlassPanelState extends State<GlassPanel> {
  bool _isHovering = false;
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    // Determine styles based on glass level
    double opacity;
    double blur;
    Border? border;

    switch (widget.level) {
      case GlassLevel.level1:
        opacity = 0.1;
        blur = 8.0;
        border = null;
        break;
      case GlassLevel.level2:
        opacity = 0.2;
        blur = 20.0;
        border = Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1);
        break;
      case GlassLevel.level3:
        opacity = 0.3;
        blur = 40.0;
        border = Border.all(color: EmergeColors.nebulaPrimaryContainer, width: 1);
        break;
    }

    // Custom glows
    List<BoxShadow>? shadows;
    if (widget.isElectric) {
      shadows = [
        BoxShadow(
          color: const Color(0xFF00D2FF).withValues(alpha: 0.3),
          blurRadius: 15,
        )
      ];
      border = Border.all(color: const Color(0xFF47D6FF).withValues(alpha: 0.5));
    } else if (widget.isViolet) {
      shadows = [
        BoxShadow(
          color: const Color(0xFFEDB1FF).withValues(alpha: 0.3),
          blurRadius: 15,
        )
      ];
      border = Border.all(color: const Color(0xFFEDB1FF).withValues(alpha: 0.5));
    }

    Widget content = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: EmergeColors.nebulaTertiary.withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: border,
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isTapped = true),
          onTapUp: (_) {
            setState(() => _isTapped = false);
            widget.onTap?.call();
          },
          onTapCancel: () => setState(() => _isTapped = false),
          child: AnimatedScale(
            scale: _isTapped ? 0.98 : (_isHovering ? 1.02 : 1.0),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}
