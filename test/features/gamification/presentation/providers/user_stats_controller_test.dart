import 'dart:async';

import 'package:emerge_app/core/services/event_bus.dart';
import 'package:emerge_app/features/auth/domain/entities/user_extension.dart';
import 'package:emerge_app/features/gamification/data/repositories/user_stats_repository.dart';
import 'package:emerge_app/features/gamification/presentation/providers/user_stats_providers.dart';
import 'package:emerge_app/features/social/domain/services/club_activity_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserStatsRepository extends Mock implements UserStatsRepository {}

class MockSocialActivityService extends Mock implements SocialActivityService {}

class FakeUserProfile extends Fake implements UserProfile {}

class FakeUserAvatarStats extends Fake implements UserAvatarStats {}

class FakeUserWorldState extends Fake implements UserWorldState {}

void main() {
  late MockUserStatsRepository mockUserStatsRepository;
  late MockSocialActivityService mockSocialActivityService;
  late UserStatsController controller;

  setUpAll(() {
    registerFallbackValue(FakeUserProfile());
    registerFallbackValue(FakeUserAvatarStats());
    registerFallbackValue(FakeUserWorldState());
  });

  setUp(() {
    mockUserStatsRepository = MockUserStatsRepository();
    mockSocialActivityService = MockSocialActivityService();

    controller = UserStatsController(
      repository: mockUserStatsRepository,
      socialActivityService: mockSocialActivityService,
      userId: '123',
      userName: 'Test User',
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test('UserStatsController should initialize without error', () async {
    expect(controller, isA<UserStatsController>());
  });

  test('UserStatsController should register and unregister EventBus subscription', () async {
    // We verify the stream subscription by checking the EventBus's active subscription count.
    EventBus.reset();

    final initialCount = EventBus().activeSubscriptionCount;

    // Creating the controller initializes the EventBus subscription
    final newController = UserStatsController(
      repository: mockUserStatsRepository,
      socialActivityService: mockSocialActivityService,
      userId: 'user_123',
      userName: 'Test User',
    );

    // Verify the subscription was added to the active pool
    expect(EventBus().activeSubscriptionCount, equals(initialCount + 1));

    // Disposing the controller unregisters the subscription
    newController.dispose();

    // Verify the subscription was removed from the active pool
    expect(EventBus().activeSubscriptionCount, equals(initialCount));
  });
}
