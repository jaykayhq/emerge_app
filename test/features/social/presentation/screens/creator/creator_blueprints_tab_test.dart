import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:emerge_app/features/social/presentation/screens/creator/creator_blueprints_tab.dart';
import 'package:emerge_app/features/blueprints/data/repositories/blueprint_repository.dart';
import 'package:emerge_app/features/blueprints/domain/models/blueprint.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';

// A fake repository that returns an empty stream
class FakeEmptyBlueprintRepository extends BlueprintRepository {
  FakeEmptyBlueprintRepository(super.firestore);

  @override
  Stream<List<Blueprint>> getBlueprints({String? category}) {
    return Stream.value([]);
  }
}

// A fake repository that returns a stream with one blueprint
class FakePopulatedBlueprintRepository extends BlueprintRepository {
  FakePopulatedBlueprintRepository(super.firestore);

  @override
  Stream<List<Blueprint>> getBlueprints({String? category}) {
    return Stream.value([
      Blueprint(
        id: 'bp1',
        creatorUserId: 'test_uid', // This will match the dummy auth user if we mock auth, but for now we just test UI
        creatorName: 'Test Creator',
        creatorArchetype: 'Athlete',
        title: 'Test Blueprint',
        description: 'Description',
        habits: [const BlueprintHabit(title: 'Habit 1')],
        createdAt: DateTime.now(),
        imageUrl: 'http://image.com',
        category: 'Morning',
        difficulty: BlueprintDifficulty.beginner,
      )
    ]);
  }
}

void main() {
  testWidgets('CreatorBlueprintsTab renders empty state when no blueprints', (tester) async {
    // Setup fake firebase
    final fakeFirestore = FakeFirebaseFirestore();

    // Override the repository and auth providers
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          blueprintRepositoryProvider.overrideWithValue(BlueprintRepository(fakeFirestore)),
          authStateChangesProvider.overrideWith((ref) => Stream.value(const AuthUser(id: 'test_uid', email: 'test@example.com'))),
        ],
        child: const MaterialApp(
          home: CreatorBlueprintsTab(),
        ),
      ),
    );

    // Pump to let the stream emit
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Blueprint Studio'), findsOneWidget);
    expect(find.text('No blueprints yet'), findsOneWidget);
    expect(find.text('Create Blueprint'), findsOneWidget);
  });
}
