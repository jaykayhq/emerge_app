import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/gamification/presentation/providers/attribute_progress_provider.dart';
import 'package:emerge_app/features/world_map/domain/models/world_type_config.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/world_map/presentation/widgets/attribute_heatmap_card.dart';

class AttributeDetailScreen extends ConsumerWidget {
  final HabitAttribute attribute;

  const AttributeDetailScreen({super.key, required this.attribute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(attributeProgressProvider(attribute.name));
    final level = progress?.currentLevel ?? 1;
    final progressPercent = progress?.progressPercent ?? 0.0;
    
    final config = WorldTypeConfig.forAttribute(attribute);
    
    final habitsAsync = ref.watch(habitsProvider);
    final habits = habitsAsync.value?.where((h) => h.attribute == attribute).toList() ?? [];

    return Scaffold(
      body: Stack(
        children: [
          // Layer 0: Background image
          Positioned.fill(
            child: Image.asset(
              config.backgroundAssetPath(level),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: config.primaryColor),
            ),
          ),
          // Layer 1: Dark gradient/overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
          // Layer 2: CustomScrollView
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                floating: true,
                title: Text(config.worldName),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: config.primaryColor, width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config.stageName(level),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Level $level',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: progressPercent,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(config.primaryColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: AttributeHeatmapCard(attribute: attribute),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Habits',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final habit = habits[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: Card(
                        color: Colors.black.withValues(alpha: 0.5),
                        child: ListTile(
                          title: Text(
                            habit.title,
                            style: const TextStyle(color: Colors.white),
                          ),
                          leading: Icon(
                            config.fallbackIcon,
                            color: config.primaryColor,
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: habits.length,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
