import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/domain/entities/habit.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';
import 'package:emerge_app/features/monetization/data/repositories/habit_contract_repository.dart';
import 'package:emerge_app/features/monetization/domain/entities/habit_contract.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:emerge_app/features/monetization/presentation/screens/habit_contract_screen.dart';
import 'package:emerge_app/features/gamification/presentation/providers/gamification_providers.dart';

class MockHabitContractRepository extends Mock
    implements HabitContractRepository {}

class FakeIsPremium extends IsPremium {
  final bool premium;
  FakeIsPremium(this.premium);
  @override
  Future<bool> build() async => premium;
}

final testUser = AuthUser(id: 'test-uid', email: 'test@example.com', displayName: 'Test User');

final testProfile = UserProfile(uid: 'test-uid');

Widget createTest({bool isPremium = true, List<Habit> habits = const []}) {
  return ProviderScope(
    overrides: [
      isPremiumProvider.overrideWith(() => FakeIsPremium(isPremium)),
      habitsProvider.overrideWith((ref) => Stream.value(habits)),
      authStateChangesProvider.overrideWith(
        (ref) => Stream.value(testUser),
      ),
      userProfileProvider.overrideWith(
        (ref) => Stream.value(testProfile),
      ),
      habitContractRepositoryProvider.overrideWith(
        (ref) => MockHabitContractRepository(),
      ),
    ],
    child: const MaterialApp(
      home: HabitContractScreen(),
    ),
  );
}

void main() {
  testWidgets('shows premium feature locked when not premium', (tester) async {
    await tester.pumpWidget(createTest(isPremium: false));
    await tester.pump();

    expect(find.text('Premium Feature'), findsOneWidget);
    expect(find.text('Upgrade to create accountability contracts.'),
        findsOneWidget);
    expect(find.text('Upgrade Now'), findsOneWidget);
  });

  testWidgets('shows contract form when premium', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    await tester.pumpWidget(createTest(isPremium: true));
    await tester.pump();

    expect(find.text('New Habit Contract'), findsOneWidget);
    expect(find.text('Make it Costly'), findsOneWidget);
    expect(find.text("Partner's Email"), findsOneWidget);
    expect(find.text('Penalty (if you miss)'), findsOneWidget);
    expect(find.text('Create Contract'), findsOneWidget);
  });
}
