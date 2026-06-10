import 'package:flutter/material.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/theme/app_theme.dart';

class HealthConnectTile extends StatelessWidget {
  final bool isConnected;
  final VoidCallback onTap;

  const HealthConnectTile({
    super.key,
    required this.isConnected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: EmergeColors.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.favorite_outline,
          color: isConnected ? EmergeColors.teal : AppTheme.textSecondaryDark,
        ),
      ),
      title: Text(
        'Connect Health Data',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppTheme.textMainDark,
        ),
      ),
      subtitle: Text(
        isConnected ? 'Connected' : 'Not Connected',
        style: TextStyle(
          color: isConnected ? EmergeColors.teal : AppTheme.textSecondaryDark,
          fontSize: 12,
        ),
      ),
      trailing: Icon(
        isConnected ? Icons.check_circle : Icons.chevron_right,
        color: isConnected ? EmergeColors.teal : AppTheme.textSecondaryDark,
      ),
      onTap: onTap,
    );
  }
}
