import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/presentation/widgets/emerge_branding.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Glassmorphism card widget for cosmic aesthetic
class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const GlassmorphismCard({
    required this.child,
    this.padding,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Standard section header with teal accent bar
class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: EmergeColors.teal,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textMainDark,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/// Frequency chip widget
class FrequencyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FrequencyChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? EmergeColors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? EmergeColors.teal
                  : AppTheme.textSecondaryDark.withValues(alpha: 0.3),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
