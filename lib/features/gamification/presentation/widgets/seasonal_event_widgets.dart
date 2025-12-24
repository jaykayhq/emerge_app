import 'package:emerge_app/features/gamification/domain/models/world_expansion.dart';
import 'package:emerge_app/features/gamification/domain/services/world_events_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

/// Banner showing current or upcoming seasonal event
class SeasonalEventBanner extends StatelessWidget {
  final VoidCallback? onTap;

  const SeasonalEventBanner({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final currentEvent = WorldEventsService.getCurrentEvent();
    final nextEvent = WorldEventsService.getNextEvent();

    if (currentEvent == null && nextEvent == null) {
      return const SizedBox.shrink();
    }

    final event = currentEvent ?? nextEvent!;
    final isActive = currentEvent != null;

    return GestureDetector(
      onTap: onTap,
      child:
          Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isActive
                        ? [Colors.amber.shade700, Colors.orange.shade600]
                        : [Colors.indigo.shade800, Colors.purple.shade700],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (isActive ? Colors.amber : Colors.purple)
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Event Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isActive ? Icons.celebration : Icons.event,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const Gap(16),

                    // Event Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _getCountdownText(event.startDate),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Gap(4),
                          Text(
                            event.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            event.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          if (isActive && event.bonusXpMultiplier > 1.0) ...[
                            const Gap(6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${((event.bonusXpMultiplier - 1) * 100).toInt()}% Bonus XP!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const Icon(Icons.chevron_right, color: Colors.white54),
                  ],
                ),
              )
              .animate()
              .fadeIn()
              .slideY(begin: -0.2)
              .then()
              .shimmer(
                delay: 2.seconds,
                duration: 1500.ms,
                color: Colors.white24,
              ),
    );
  }

  String _getCountdownText(DateTime eventDate) {
    final now = DateTime.now();
    final diff = eventDate.difference(now);

    if (diff.inDays > 0) {
      return 'IN ${diff.inDays} DAYS';
    } else if (diff.inHours > 0) {
      return 'IN ${diff.inHours} HOURS';
    } else {
      return 'STARTING SOON';
    }
  }
}

/// Compact event indicator for app bar or stats bar
class EventIndicatorChip extends StatelessWidget {
  const EventIndicatorChip({super.key});

  @override
  Widget build(BuildContext context) {
    final event = WorldEventsService.getCurrentEvent();
    if (event == null) return const SizedBox.shrink();

    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade600, Colors.orange.shade500],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
              const Gap(4),
              Text(
                '${((event.bonusXpMultiplier - 1) * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 1.seconds,
        );
  }
}

/// Widget showing rare blueprint drop
class RareBlueprintDropCard extends StatelessWidget {
  final RareBlueprint blueprint;
  final VoidCallback? onClaim;

  const RareBlueprintDropCard({
    super.key,
    required this.blueprint,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.purple.shade800, Colors.deepPurple.shade900],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.purple.shade400, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 24),
                  const Gap(8),
                  const Text(
                    'RARE BLUEPRINT DISCOVERED!',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Gap(8),
                  const Icon(Icons.stars, color: Colors.amber, size: 24),
                ],
              ),

              const Gap(20),

              // Blueprint Icon
              Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: const Icon(
                      Icons.architecture,
                      color: Colors.amber,
                      size: 40,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 1.seconds,
                  )
                  .animate()
                  .shimmer(delay: 500.ms, duration: 1500.ms),

              const Gap(16),

              // Blueprint Name
              Text(
                _formatBuildingName(blueprint.buildingId),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Gap(8),

              Text(
                blueprint.description,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),

              const Gap(20),

              // Claim Button
              ElevatedButton.icon(
                onPressed: onClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.download_done),
                label: const Text(
                  'CLAIM BLUEPRINT',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }

  String _formatBuildingName(String id) {
    return id
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
