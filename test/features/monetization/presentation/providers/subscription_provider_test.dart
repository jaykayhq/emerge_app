import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emerge_app/features/auth/domain/entities/auth_user.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real [IsPremium] with the platform seam forced to web so the Firestore
/// doc path runs under `flutter test` (`kIsWeb` is compile-time false on
/// the VM).
class _WebIsPremium extends IsPremium {
  @override
  bool get isWeb => true;
}

void main() {
  const user = AuthUser(id: 'uid-1', email: 'user@example.com');

  ProviderContainer makeContainer(FakeFirebaseFirestore fdb) {
    return ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(fdb),
        authStateChangesProvider.overrideWith((ref) => Stream.value(user)),
        isPremiumProvider.overrideWith(() => _WebIsPremium()),
      ],
    );
  }

  /// Polls the provider until [predicate] holds (or the deadline passes).
  /// `read` alone does not subscribe a StreamProvider in Riverpod 3, so
  /// callers must keep a `container.listen` subscription open for the
  /// provider's lifetime; this only polls the current state.
  Future<void> pollUntil(
    ProviderContainer container,
    bool Function(bool?) predicate, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!predicate(container.read(isPremiumProvider).value) &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  test('web premium activates when the users doc has isPremium true', () async {
    final fdb = FakeFirebaseFirestore();
    await fdb.collection('users').doc('uid-1').set({'isPremium': true});
    final container = makeContainer(fdb);
    addTearDown(container.dispose);
    final sub = container.listen<AsyncValue<bool>>(
      isPremiumProvider,
      (previous, next) {},
    );
    addTearDown(sub.close);

    await pollUntil(container, (v) => v == true);
    expect(container.read(isPremiumProvider).value, isTrue);
  });

  test('a pause written mid-session drops premium at premiumEndsAt '
      'without relaunch', () async {
    final fdb = FakeFirebaseFirestore();
    await fdb.collection('users').doc('uid-1').set({'isPremium': true});
    final container = makeContainer(fdb);
    addTearDown(container.dispose);
    final values = <bool>[];
    final sub = container.listen<AsyncValue<bool>>(
      isPremiumProvider,
      (previous, next) {
        if (next is AsyncData<bool>) values.add(next.value);
      },
    );
    addTearDown(sub.close);

    await pollUntil(container, (v) => v == true);

    // Manage Premium → Pause mid-session: the doc becomes paused with a
    // short future end date, and the stream re-emits (schedules the timer).
    await fdb.collection('users').doc('uid-1').update({
      'subscriptionStatus': 'paused',
      'premiumEndsAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(seconds: 2)),
      ),
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // Paused with a future end date: still premium. (The emission is
    // value-invisible to listeners — true → true — so read the state.)
    expect(container.read(isPremiumProvider).value, isTrue);

    // ...until the pause window ends: the scheduled timer fires, re-reads
    // the doc and drops premium mid-session (true → false notifies).
    await pollUntil(container, (v) => v == false);
    expect(values.last, isFalse);
  });

  test('a Firestore stream error keeps the last known premium state',
      () async {
    final fdb = FakeFirebaseFirestore();
    final controller = StreamController<Map<String, dynamic>?>();
    addTearDown(controller.close);
    final notifier = _WebIsPremium()
      ..docDataStream = (firestore, uid) => controller.stream;
    final container = ProviderContainer(
      overrides: [
        firestoreProvider.overrideWithValue(fdb),
        authStateChangesProvider.overrideWith((ref) => Stream.value(user)),
        isPremiumProvider.overrideWith(() => notifier),
      ],
    );
    addTearDown(container.dispose);
    final values = <bool>[];
    final sub = container.listen<AsyncValue<bool>>(
      isPremiumProvider,
      (previous, next) {
        if (next is AsyncData<bool>) values.add(next.value);
      },
    );
    addTearDown(sub.close);

    // The controller-driven stream starts empty: wait for the initial
    // build (missing doc → false) to land.
    await pollUntil(container, (v) => v == false);
    values.clear();

    controller.add({'isPremium': true});
    await pollUntil(container, (v) => v == true);
    expect(values.last, isTrue);

    controller.addError(Exception('stream exploded'), StackTrace.current);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // The last known state is kept — a transient stream error never flips
    // a paying user to free mid-session.
    expect(container.read(isPremiumProvider).value, isTrue);
  });
}
