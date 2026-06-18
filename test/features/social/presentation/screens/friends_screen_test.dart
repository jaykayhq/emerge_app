import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emerge_app/features/social/presentation/screens/friends_screen.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_stream_provider.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    when(() => mockAuthRepo.user).thenAnswer(
      (_) => Stream.value(const AuthUser(id: 'test_uid', email: 'test@test.com')),
    );
  });

  testWidgets('FriendsScreen renders header', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          partnersListStreamProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
        ],
        child: const MaterialApp(home: FriendsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PARTNERS'), findsOneWidget);
    expect(find.text('Find a partner...'), findsOneWidget);
  });
}
