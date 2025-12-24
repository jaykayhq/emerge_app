import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:emerge_app/features/onboarding/data/services/remote_config_service.dart';
import 'package:emerge_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class IdentityAttributesScreen extends ConsumerWidget {
  const IdentityAttributesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch attributes from Remote Config
    final config = ref.watch(remoteConfigServiceProvider).getOnboardingConfig();
    final availableAttributes = config.attributes;

    final onboardingState = ref.watch(onboardingStateProvider);
    final attributes = onboardingState.attributes;
    final remainingPoints = onboardingState.remainingPoints;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Step 2 of 5: Shape Your Identity',
          style: GoogleFonts.splineSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 2 / 5, // Step 2 of 5
            backgroundColor: AppTheme.surfaceDark,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.vitalityGreen,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Orb Visual
          Expanded(
            flex: 2,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glowing Orb Image
                  Image.asset(
                    'assets/images/attribute_orb.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to an icon if the asset fails
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppTheme.primary.withValues(alpha: 0.5),
                              AppTheme.primary.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$remainingPoints',
                        style: GoogleFonts.splineSans(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Points Left',
                        style: GoogleFonts.splineSans(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Attributes List
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 32),
                itemCount: availableAttributes.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final attributeConfig = availableAttributes[index];
                  final currentPoints = attributes[attributeConfig.title] ?? 0;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Icon
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: HexColor.fromHex(
                              attributeConfig.color,
                            ).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconData(attributeConfig.icon),
                            color: HexColor.fromHex(attributeConfig.color),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                attributeConfig.title,
                                style: GoogleFonts.splineSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                attributeConfig.description,
                                style: GoogleFonts.splineSans(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Controls
                        Row(
                          children: [
                            IconButton(
                              onPressed: currentPoints > 0
                                  ? () {
                                      final newAttributes =
                                          Map<String, int>.from(attributes);
                                      newAttributes[attributeConfig.title] =
                                          currentPoints - 1;

                                      debugPrint(
                                        'Decreasing ${attributeConfig.title}: current=$currentPoints, remaining=$remainingPoints',
                                      );
                                      ref
                                          .read(
                                            onboardingStateProvider.notifier,
                                          )
                                          .update(
                                            (state) => state.copyWith(
                                              attributes: newAttributes,
                                              remainingPoints:
                                                  remainingPoints + 1,
                                            ),
                                          );
                                    }
                                  : null,
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '$currentPoints',
                              style: GoogleFonts.splineSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              onPressed: remainingPoints > 0
                                  ? () {
                                      final newAttributes =
                                          Map<String, int>.from(attributes);
                                      newAttributes[attributeConfig.title] =
                                          currentPoints + 1;

                                      debugPrint(
                                        'Increasing ${attributeConfig.title}: current=$currentPoints, remaining=$remainingPoints',
                                      );
                                      ref
                                          .read(
                                            onboardingStateProvider.notifier,
                                          )
                                          .update(
                                            (state) => state.copyWith(
                                              attributes: newAttributes,
                                              remainingPoints:
                                                  remainingPoints - 1,
                                            ),
                                          );
                                    }
                                  : null,
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: remainingPoints > 0
                                    ? AppTheme.primary
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // CTA
          Container(
            color: AppTheme.surfaceDark,
            padding: const EdgeInsets.all(24.0),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: remainingPoints == 0
                    ? AppTheme.primary
                    : Colors.grey[800],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: remainingPoints == 0
                      ? () async {
                          // Complete milestone and go to next step
                          await ref
                              .read(onboardingControllerProvider.notifier)
                              .completeMilestone(1);
                          if (context.mounted) {
                            context.push('/onboarding/why');
                          }
                        }
                      : null,
                  borderRadius: BorderRadius.circular(28),
                  child: Center(
                    child: Text(
                      'Forge My Path',
                      style: GoogleFonts.splineSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: remainingPoints == 0
                            ? AppTheme.backgroundDark
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'favorite':
        return Icons.favorite;
      case 'psychology':
        return Icons.psychology;
      case 'brush':
        return Icons.brush;
      case 'fitness_center':
        return Icons.fitness_center;
      default:
        return Icons.star;
    }
  }
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
