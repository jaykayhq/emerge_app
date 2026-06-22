import 'package:flutter/material.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';

/// Shared primary CTA button used across the app's high-conversion surfaces
/// (lobby sticky action bar, creator profile JOIN VANGUARD, world map XP, etc.).
///
/// Visuals: a 56px gradient pill with a soft cyan glow, uppercase letter-spaced
/// label, optional leading/trailing icons, and an inline loading spinner that
/// replaces the icon row when [isLoading] is true.
class EmergePrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool fullWidth;
  final double height;
  final EdgeInsetsGeometry padding;
  final LinearGradient? gradient;
  final Color? textColor;
  final double borderRadius;

  const EmergePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = true,
    this.height = 56,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.gradient,
    this.textColor,
    this.borderRadius = 28,
  });

  bool get _isInteractive => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final fill = gradient ?? EmergeColors.nebulaCtaGradient;
    final fg = textColor ?? Colors.white;

    final disabledFill = LinearGradient(
      colors: [
        EmergeColors.nebulaPrimaryContainer.withValues(alpha: 0.4),
        EmergeColors.nebulaSecondary.withValues(alpha: 0.4),
      ],
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: Opacity(
        opacity: _isInteractive ? 1.0 : 0.55,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: _isInteractive ? onPressed : null,
            child: Ink(
              decoration: BoxDecoration(
                gradient: _isInteractive ? fill : disabledFill,
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: EmergeColors.nebulaPrimaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Container(
                padding: padding,
                alignment: Alignment.center,
                child: isLoading
                    ? SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(fg),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (leadingIcon != null) ...[
                            Icon(leadingIcon, color: fg, size: 18),
                            const SizedBox(width: 10),
                          ],
                          Flexible(
                            child: Text(
                              label.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: fg,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          if (trailingIcon != null) ...[
                            const SizedBox(width: 10),
                            Icon(trailingIcon, color: fg, size: 18),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
