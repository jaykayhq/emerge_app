import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/core/utils/password_rules.dart';
import 'package:flutter/material.dart';

/// Live password-requirements checklist.
///
/// Visible only while the password field is being completed (non-empty),
/// per the design decision: never render on an untouched/empty field, and
/// never attach to the confirm-password field. When every rule passes the
/// list collapses to a single success line so a valid field stays compact.
class PasswordRequirementChecklist extends StatelessWidget {
  const PasswordRequirementChecklist({super.key, required this.passwordController});

  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: passwordController,
      builder: (context, _) {
        final value = passwordController.text;
        if (value.isEmpty) return const SizedBox.shrink();

        final allPass = PasswordRules.checklistItems
            .every((rule) => rule.passes(value));

        if (allPass) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 16, color: EmergeColors.teal),
                const SizedBox(width: 6),
                Text(
                  'Password looks good',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: EmergeColors.teal,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final rule in PasswordRules.checklistItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        rule.passes(value)
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: rule.passes(value)
                            ? EmergeColors.teal
                            : AppTheme.textSecondaryDark,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          rule.label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: rule.passes(value)
                                    ? AppTheme.textMainDark
                                    : AppTheme.textSecondaryDark,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
