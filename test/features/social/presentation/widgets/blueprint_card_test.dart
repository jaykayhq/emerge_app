import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/social/presentation/widgets/blueprint_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _deadUrl =
    'https://images.unsplash.com/photo-1545205597-3d9d02e29597?w=800';

Blueprint _buildBlueprint({String? imageUrl}) => Blueprint(
  id: 'bp-1',
  creatorUserId: 'creator-1',
  creatorName: 'Test Creator',
  creatorArchetype: 'Scholar',
  title: 'Test Blueprint',
  description: 'A test blueprint description.',
  habits: const [],
  createdAt: DateTime(2024, 1, 1),
  category: 'Scholar',
  imageUrl: imageUrl,
);

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 300, height: 400, child: child),
    ),
  );
}

void main() {
  testWidgets('renders fallback icon (not a blank area) for a dead image URL',
      (tester) async {
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
}
