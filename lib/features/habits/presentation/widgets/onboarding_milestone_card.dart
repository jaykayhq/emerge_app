import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/onboarding/domain/entities/onboarding_milestone.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// Hero-style milestone card for onboarding steps in the timeline
///
/// Design follows the "Next Action" card from mockup with:
/// - Large background image/illustration
/// - Dark surface background with border
/// - Progress badge and icon
/// - Primary and secondary CTAs
/// - Fade-out animation for completed state
class OnboardingMilestoneCard extends StatelessWidget {
  final OnboardingMilestone milestone;
  final VoidCallback? onSkip;
  final VoidCallback? onDismiss;
  final bool showCompletedState;

  const OnboardingMilestoneCard({
    super.key,
    required this.milestone,
    this.onSkip,
    this.onDismiss,
    this.showCompletedState = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = milestone.isCompleted || showCompletedState;

    return AnimatedOpacity(
      opacity: isCompleted ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Stack(
          children: [
            // Main card container
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderDark, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.vitalityGreen.withValues(alpha: 0.1),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive layout: vertical on mobile, horizontal on tablet+
                  final isWideLayout = constraints.maxWidth > 600;

                  return isWideLayout
                      ? _buildHorizontalLayout(theme, isCompleted)
                      : _buildVerticalLayout(theme, isCompleted);
                },
              ),
            ),

            // Dismiss button for completed milestones
            if (isCompleted && onDismiss != null)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppTheme.slateBlue,
                  onPressed: onDismiss,
                ),
              ),

            // Progress badge
            if (!isCompleted)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.deepSunriseOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.deepSunriseOrange.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Step ${milestone.order} of 3',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.deepSunriseOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // Completed check icon overlay
            if (isCompleted)
              Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.vitalityGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.vitalityGreen.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: AppTheme.backgroundDark,
                      size: 48,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalLayout(ThemeData theme, bool isCompleted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Background image section
        _buildImageSection(),

        // Content section
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.vitalityGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  milestone.icon,
                  color: AppTheme.vitalityGreen,
                  size: 24,
                ),
              ),
              const Gap(12),

              // Title
              Text(
                milestone.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(8),

              // Description
              Text(
                milestone.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.slateBlue,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Gap(16),

              // CTAs
              if (!isCompleted) _buildActions(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout(ThemeData theme, bool isCompleted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Background image section (fixed width on tablet+)
        SizedBox(width: 280, child: _buildImageSection(roundedCorners: 'left')),

        // Content section
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon badge
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.vitalityGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    milestone.icon,
                    color: AppTheme.vitalityGreen,
                    size: 24,
                  ),
                ),
                const Gap(12),

                // Title
                Text(
                  milestone.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(8),

                // Description
                Text(
                  milestone.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.slateBlue,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(16),

                // CTAs
                if (!isCompleted) _buildActions(theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection({String roundedCorners = 'top'}) {
    return ClipRRect(
      borderRadius: roundedCorners == 'left'
          ? const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            )
          : const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child:
            milestone.backgroundImageUrl != null &&
                milestone.backgroundImageUrl!.isNotEmpty
            ? Image.network(
                milestone.backgroundImageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildImagePlaceholder(isLoading: true);
                },
                errorBuilder: (context, error, stackTrace) {
                  // Gracefully handle network image errors
                  debugPrint('Milestone image load error: $error');
                  return _buildImagePlaceholder();
                },
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder({bool isLoading = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.vitalityGreen.withValues(alpha: 0.3),
            AppTheme.deepSunriseOrange.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator(
                color: AppTheme.vitalityGreen,
                strokeWidth: 2,
              )
            : Icon(
                milestone.icon,
                size: 64,
                color: AppTheme.vitalityGreen.withValues(alpha: 0.5),
              ),
      ),
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary CTA - Begin This Step
        Builder(
          builder: (context) => ElevatedButton.icon(
            onPressed: () {
              context.push(milestone.routePath);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.vitalityGreen,
              foregroundColor: AppTheme.backgroundDark,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.arrow_forward),
            label: const Text(
              'Begin This Step',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),

        // Secondary CTA - Skip for now
        if (milestone.canSkip && onSkip != null) ...[
          const Gap(8),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.slateBlue,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Skip for now',
              style: TextStyle(
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
