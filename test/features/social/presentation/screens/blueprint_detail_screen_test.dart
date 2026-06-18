import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/blueprints/presentation/providers/blueprint_detail_controller.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart'
    show isPremiumProvider, IsPremium;
import 'package:emerge_app/features/social/presentation/screens/blueprint_detail_screen.dart';

class MockBlueprintDetailController extends Mock
    implements BlueprintDetailController {}

class _MockIsPremium extends IsPremium {
  @override
  Future<bool> build() async => false;
}

final testBlueprint = Blueprint(
  id: 'test-bp-1',
  creatorUserId: 'creator-1',
  creatorName: 'Test Creator',
  creatorArchetype: 'Scholar',
  title: 'Test Blueprint',
  description: 'A test blueprint description.',
  habits: [],
  createdAt: DateTime(2024, 1, 1),
  category: 'Scholar',
  imageUrl: null,
);

final testUser = AuthUser(
  id: 'test-uid',
  email: 'test@example.com',
  displayName: 'Test User',
);

Widget _buildTest() {
  return ProviderScope(
    overrides: [
      authStateChangesProvider.overrideWith(
        (ref) => Stream.value(testUser),
      ),
      isPremiumProvider.overrideWith(() => _MockIsPremium()),
      blueprintDetailControllerProvider.overrideWith(
        () => MockBlueprintDetailController(),
      ),
    ],
    child: MaterialApp(
      home: BlueprintDetailScreen(blueprint: testBlueprint),
    ),
  );
}

void main() {
  testWidgets('BlueprintDetailScreen renders with data', (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('By Test Creator'), findsOneWidget);
    expect(find.text('A test blueprint description.'), findsOneWidget);
    expect(find.text('THE HABIT STACK'), findsOneWidget);
    expect(find.text('ABOUT THIS BLUEPRINT'), findsOneWidget);
  });

  testWidgets('BlueprintDetailScreen shows adopt button',
      (tester) async {
    await tester.pumpWidget(_buildTest());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ADOPT BLUEPRINT'), findsOneWidget);
  });
}
