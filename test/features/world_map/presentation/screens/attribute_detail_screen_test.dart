import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/world_map/presentation/screens/attribute_detail_screen.dart';
import 'package:emerge_app/features/gamification/presentation/providers/attribute_progress_provider.dart';
import 'package:emerge_app/features/world_map/domain/models/world_type_config.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';

void main() {
  testWidgets('AttributeDetailScreen renders correctly', (WidgetTester tester) async {
    final habit = Habit(
      id: '1',
      title: 'Run 5km',
      attribute: HabitAttribute.strength,
      userId: 'user_1',
      createdAt: DateTime.now(),
    );

    final progress = AttributeProgress(
      attribute: HabitAttribute.strength.name,
      totalXp: 150,
      currentLevel: 2,
      overallLevel: 5,
      contributionToOverall: 150,
      xpForNextLevel: 500,
      contributionPercent: 0.1,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attributeProgressProvider(HabitAttribute.strength.name).overrideWithValue(progress),
          habitsProvider.overrideWith((ref) => Stream.value([habit])),
        ],
        child: const MaterialApp(
          home: AttributeDetailScreen(attribute: HabitAttribute.strength),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final config = WorldTypeConfig.forAttribute(HabitAttribute.strength);

    expect(find.text(config.worldName), findsOneWidget);
    expect(find.text(config.stageName(2)), findsOneWidget);
    expect(find.text('Run 5km'), findsOneWidget);
  });
}
