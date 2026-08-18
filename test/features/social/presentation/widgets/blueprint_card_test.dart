import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/social/presentation/widgets/blueprint_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _deadUrl =
    'https://images.unsplash.com/photo-1545205597-3d9d02e29597?w=800';

Blueprint _buildBlueprint({
  String? imageUrl,
  List<BlueprintHabit> habits = const [],
}) => Blueprint(
  id: 'bp-1',
  creatorUserId: 'creator-1',
  creatorName: 'Test Creator',
  creatorArchetype: 'Scholar',
  title: 'Test Blueprint',
  description: 'A test blueprint description.',
  habits: habits,
  createdAt: DateTime(2024, 1, 1),
  category: 'Scholar',
  imageUrl: imageUrl,
);

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 300, height: 400, child: child)),
  );
}

void main() {
  testWidgets('renders fallback icon (not a blank area) for a dead image URL', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(BlueprintCard(blueprint: _buildBlueprint(imageUrl: _deadUrl))),
    );
    await tester.pump();

    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    expect(find.text('Test Blueprint'), findsOneWidget);
  });

  testWidgets('renders fallback icon when imageUrl is null', (tester) async {
    await tester.pumpWidget(
      _wrap(BlueprintCard(blueprint: _buildBlueprint(imageUrl: null))),
    );
    await tester.pump();

    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    expect(find.text('Test Blueprint'), findsOneWidget);
  });

  testWidgets(
    'renders time-of-day and attribute badges when habit data present',
    (tester) async {
      final blueprint = _buildBlueprint(
        habits: const [
          BlueprintHabit(
            title: 'Wake Up at 6 AM',
            timeOfDay: 'Morning',
            attribute: HabitAttribute.focus,
          ),
          BlueprintHabit(
            title: 'Read',
            timeOfDay: 'Evening',
            attribute: HabitAttribute.focus,
          ),
          BlueprintHabit(
            title: 'Reflect',
            timeOfDay: 'Evening',
            attribute: HabitAttribute.intellect,
          ),
        ],
      );

      await tester.pumpWidget(_wrap(BlueprintCard(blueprint: blueprint)));
      await tester.pump();

      expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
      expect(find.text('Evening'), findsOneWidget);
      expect(find.text('FOCUS'), findsOneWidget);
    },
  );

  testWidgets('renders no badges when blueprint has no habits', (tester) async {
    final blueprint = _buildBlueprint(habits: const []);

    await tester.pumpWidget(_wrap(BlueprintCard(blueprint: blueprint)));
    await tester.pump();

    expect(find.byIcon(Icons.wb_sunny), findsNothing);
    expect(find.text('Morning'), findsNothing);
    expect(find.text('VITALITY'), findsNothing);
  });

  testWidgets('shows the dominant time-of-day when the stack varies', (
    tester,
  ) async {
    final blueprint = _buildBlueprint(
      habits: const [
        BlueprintHabit(title: 'A', timeOfDay: 'Morning'),
        BlueprintHabit(title: 'B', timeOfDay: 'Evening'),
        BlueprintHabit(title: 'C', timeOfDay: 'Evening'),
      ],
    );

    await tester.pumpWidget(_wrap(BlueprintCard(blueprint: blueprint)));
    await tester.pump();

    expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    expect(find.text('Evening'), findsOneWidget);
    expect(find.text('Morning'), findsNothing);
  });

  test('dominantBlueprintTimeOfDay returns null without slot data', () {
    expect(dominantBlueprintTimeOfDay(_buildBlueprint()), isNull);
    expect(
      dominantBlueprintTimeOfDay(
        _buildBlueprint(habits: const [BlueprintHabit(title: 'Generic')]),
      ),
      isNull,
    );
  });

  test('dominantBlueprintTimeOfDay returns the most common slot', () {
    final bp = _buildBlueprint(
      habits: const [
        BlueprintHabit(title: 'A', timeOfDay: 'Morning'),
        BlueprintHabit(title: 'B', timeOfDay: 'Evening'),
        BlueprintHabit(title: 'C', timeOfDay: 'Evening'),
      ],
    );
    expect(dominantBlueprintTimeOfDay(bp), 'Evening');
  });

  test('dominantBlueprintAttribute returns the most common attribute', () {
    final bp = _buildBlueprint(
      habits: const [
        BlueprintHabit(title: 'A', attribute: HabitAttribute.focus),
        BlueprintHabit(title: 'B', attribute: HabitAttribute.focus),
        BlueprintHabit(title: 'C', attribute: HabitAttribute.vitality),
      ],
    );
    expect(dominantBlueprintAttribute(bp), HabitAttribute.focus);
    expect(dominantBlueprintAttribute(_buildBlueprint()), isNull);
  });
}
