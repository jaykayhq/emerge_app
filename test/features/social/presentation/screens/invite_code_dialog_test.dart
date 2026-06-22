import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:emerge_app/features/social/presentation/screens/invite_code_dialog.dart';
import 'package:emerge_app/features/social/presentation/providers/friend_provider.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/social/domain/repositories/friend_repository.dart';
import 'package:emerge_app/features/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockFriendRepository extends Mock implements FriendRepository {}

class _ProviderPump extends ConsumerWidget {
  final Widget child;
  const _ProviderPump({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateChangesProvider);
    return child;
  }
}

void main() {
  late MockAuthRepository mockAuthRepo;
  late MockFriendRepository mockFriendRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockFriendRepo = MockFriendRepository();

    when(() => mockAuthRepo.user).thenAnswer(
      (_) => Stream.value(const AuthUser(id: 'test_uid', email: 'test@test.com')),
    );
  });

  Widget buildTest() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
        friendRepositoryProvider.overrideWithValue(mockFriendRepo),
      ],
      child: _ProviderPump(
        child: const MaterialApp(home: InviteCodeDialog()),
      ),
    );
  }

  Future<void> setScreenSize(tester) async {
    tester.view.physicalSize = const Size(600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('InviteCodeDialog renders form elements', (tester) async {
    await setScreenSize(tester);
    await tester.pumpWidget(buildTest());
    await tester.pump();

    expect(find.text('Form a Partnership'), findsOneWidget);
    expect(find.text('HAVE A CODE?'), findsOneWidget);
    expect(find.text('Redeem Code'), findsOneWidget);
    expect(find.text('Generate My Code'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('InviteCodeDialog generates code', (tester) async {
    await setScreenSize(tester);
    when(() => mockFriendRepo.generateInviteCode(any()))
        .thenAnswer((_) async => 'ABC123');

    await tester.pumpWidget(buildTest());
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Generate My Code'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Generate My Code'), findsNothing);
    expect(find.text('ABC123'), findsOneWidget);
  });
}
