import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:flutter/material.dart';

/// Renders a nameplate background behind a user's name/card.
/// The `nameplateKey` corresponds to the `displayValue` from RewardCatalog.
class NameplateRenderer extends StatelessWidget {
  final String nameplateKey;
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsets padding;

  const NameplateRenderer({
    super.key,
    required this.nameplateKey,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: _getGradient(),
        border: Border.all(
          color: _getBorderColor(),
          width: _isSpecial() ? 1.5 : 1.0,
        ),
        boxShadow: _isSpecial()
            ? [
                BoxShadow(
                  color: _getGlowColor().withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  bool _isSpecial() => nameplateKey != 'default' && nameplateKey.isNotEmpty;

  LinearGradient _getGradient() {
    switch (nameplateKey) {
      case 'ember':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1B1B), Color(0xFF3D1F1F), Color(0xFF1A0D0D)],
        );
      case 'aurora':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1B2A), Color(0xFF1B3A4B), Color(0xFF0D2137)],
        );
      case 'voidstar':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0A15), Color(0xFF1A0A2E), Color(0xFF0F0F1A)],
        );
      case 'nebula':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0528), Color(0xFF2D0B3D), Color(0xFF15032B)],
        );
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EmergeColors.glassWhite,
            EmergeColors.glassWhite.withValues(alpha: 0.06),
          ],
        );
    }
  }

  Color _getBorderColor() {
    switch (nameplateKey) {
      case 'ember':
        return const Color(0xFF8B2500).withValues(alpha: 0.6);
      case 'aurora':
        return const Color(0xFF00BCD4).withValues(alpha: 0.4);
      case 'voidstar':
        return const Color(0xFF9C27B0).withValues(alpha: 0.5);
      case 'nebula':
        return const Color(0xFFE040FB).withValues(alpha: 0.4);
      default:
        return EmergeColors.glassBorder;
    }
  }

  Color _getGlowColor() {
    switch (nameplateKey) {
      case 'ember':
        return const Color(0xFFFF6B35);
      case 'aurora':
        return const Color(0xFF00E5FF);
      case 'voidstar':
        return const Color(0xFF7C4DFF);
      case 'nebula':
        return const Color(0xFFE040FB);
      default:
        return Colors.transparent;
    }
  }
}

/// Renders a user's display name with their equipped title suffix/prefix.
class TitleDisplay extends StatelessWidget {
  final String displayName;
  final String titleDisplayValue;
  final TextStyle? nameStyle;
  final TextStyle? titleStyle;

  const TitleDisplay({
    super.key,
    required this.displayName,
    this.titleDisplayValue = '',
    this.nameStyle,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (titleDisplayValue.isEmpty) {
      return Text(
        displayName,
        style:
            nameStyle ??
            const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
        overflow: TextOverflow.ellipsis,
      );
    }

    // Prefix titles end with space, suffix titles start with comma
    final isPrefix = titleDisplayValue.endsWith(' ');

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: [
          if (isPrefix)
            TextSpan(
              text: titleDisplayValue,
              style:
                  titleStyle ??
                  TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: EmergeColors.yellow.withValues(alpha: 0.9),
                  ),
            ),
          TextSpan(
            text: displayName,
            style:
                nameStyle ??
                const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          if (!isPrefix)
            TextSpan(
              text: titleDisplayValue,
              style:
                  titleStyle ??
                  TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: EmergeColors.yellow.withValues(alpha: 0.8),
                  ),
            ),
        ],
      ),
    );
  }
}
