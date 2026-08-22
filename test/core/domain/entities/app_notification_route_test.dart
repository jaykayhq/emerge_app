import 'package:emerge_app/core/domain/entities/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies that every derived notification route actually exists in the
/// go_router table (see lib/core/router/router.dart). A route here that
/// does not resolve makes the tap a dead end for the user.
void main() {
  AppNotification build(
    AppNotificationType type, {
    Map<String, dynamic> data = const {},
  }) {
    return AppNotification(
      id: 'n1',
      type: type,
      title: 't',
      body: 'b',
      data: data,
      createdAt: DateTime(2026),
    );
  }

  /// Routes that exist in the router table today.
  const existingRoutes = {
    '/social',
    '/social/accountability',
    '/social/contracts',
    '/social/contacts',
    '/social/challenges',
    '/social/all',
    '/profile',
    '/challenges',
  };

  bool routeExists(String route) {
    if (existingRoutes.contains(route)) return true;
    // Parameterized routes.
    final challengeDetail = RegExp(r'^/challenges/[^/]+$');
    final socialChallengeDetail = RegExp(r'^/social/challenge/[^/]+$');
    final tribeDetail = RegExp(r'^/social/tribe/[^/]+$');
    return challengeDetail.hasMatch(route) ||
        socialChallengeDetail.hasMatch(route) ||
        tribeDetail.hasMatch(route);
  }

  group('AppNotificationExt.routePath resolves to real routes', () {
    test('friendRequest falls back to the friends screen', () {
      final route = build(AppNotificationType.friendRequest).routePath!;
      expect(routeExists(route), isTrue, reason: '$route is not routed');
      expect(route, '/social/accountability');
    });

    test('friendRequestAccepted falls back to the friends screen', () {
      final route =
          build(AppNotificationType.friendRequestAccepted).routePath!;
      expect(route, '/social/accountability');
    });

    test('challengeInvite with challengeId targets challenge detail', () {
      final route = build(
        AppNotificationType.challengeInvite,
        data: {'challengeId': 'c1'},
      ).routePath!;
      expect(routeExists(route), isTrue, reason: '$route is not routed');
    });

    test('tribeActivity with tribeId targets tribe detail on social shell',
        () {
      final route = build(
        AppNotificationType.tribeActivity,
        data: {'tribeId': 't1'},
      ).routePath!;
      expect(routeExists(route), isTrue, reason: '$route is not routed');
      expect(route, '/social/tribe/t1');
    });

    test('explicit route in data wins and must be routable', () {
      final route = build(
        AppNotificationType.system,
        data: {'route': '/social/accountability'},
      ).routePath!;
      expect(routeExists(route), isTrue);
    });

    test('nudge targets the partners screen', () {
      final route = build(AppNotificationType.nudge).routePath!;
      expect(routeExists(route), isTrue, reason: '$route is not routed');
      expect(route, '/social/accountability');
    });
  });
}
