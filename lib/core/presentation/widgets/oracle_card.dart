import 'package:flutter/material.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:gap/gap.dart';

class OracleCard extends StatelessWidget {
  final String title;
  final String description;
  final String? quote;
  final IconData icon;
  final Color iconColor;
  final bool isPremiumLocked;
  final Widget? footer;
  final VoidCallback? onQuoteTap;

  const OracleCard({
    super.key,
    required this.title,
    required this.description,
    this.quote,
    required this.icon,
    this.iconColor = EmergeColors.teal,
    this.isPremiumLocked = false,
    this.footer,
    this.onQuoteTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = iconColor.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: EmergeColors.hexLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMainDark,
                  ),
                ),
              ),
              if (isPremiumLocked)
                const Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: AppTheme.textSecondaryDark,
                ),
            ],
          ),
          const Gap(12),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textMainDark,
              height: 1.5,
            ),
          ),
          if (quote != null && quote!.isNotEmpty) ...[
            const Gap(16),
            InkWell(
              onTap: onQuoteTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: EmergeColors.violet.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: EmergeColors.violet.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '"$quote"',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: EmergeColors.violet,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
          if (footer != null) ...[
            const Gap(16),
            footer!,
          ],
        ],
      ),
    );
  }
}
