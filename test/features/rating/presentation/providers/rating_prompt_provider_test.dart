import 'package:emerge_app/features/rating/domain/rating_prompt_gate.dart';
import 'package:emerge_app/features/rating/domain/rating_prompt_store.dart';
import 'package:emerge_app/features/rating/domain/review_launcher.dart';
import 'package:emerge_app/features/rating/presentation/providers/rating_prompt_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStore implements RatingPromptStore {
  DateTime? askedAt;
  String? version;
  bool dontAsk = false;
  @override
  Future<DateTime?> lastAskedAt() async => askedAt;
  @override
  Future<String?> versionAskedFor() async => version;
  @override
  Future<bool> dontAskAgain() async => dontAsk;
  @override
  Future<void> recordAsked(DateTime at, String version) async {
    askedAt = at;
    this.version = version;
  }

  @override
  Future<void> setDontAskAgain() async => dontAsk = true;
}

class _FakeLauncher implements ReviewLauncher {
  int launches = 0;
  @override
  Future<bool> launch() async {
    launches++;
    return true;
  }
}

void main() {
  test(
    'notifyMilestone prompts (does not auto-review) on first milestone',
    () async {
      final store = _FakeStore();
      final launcher = _FakeLauncher();
      final controller = RatingPromptController(
        store: store,
        launcher: launcher,
      );
      controller.currentVersion = '1.0.7+12';
      var prompted = false;
      controller.onPromptRequested = () async => prompted = true;

      await controller.notifyMilestone(RatingPromptSignal.sevenDayStreak);

      expect(prompted, isTrue); // dialog asked
      expect(launcher.launches, 0); // NOT auto-reviewed
    },
  );

  test('notifyMilestone does not prompt twice in the same version', () async {
    final store = _FakeStore()
      ..askedAt = DateTime(2026, 1, 1)
      ..version = '1.0.7+12';
    final launcher = _FakeLauncher();
    final controller = RatingPromptController(store: store, launcher: launcher);
    controller.currentVersion = '1.0.7+12';
    var prompted = false;
    controller.onPromptRequested = () async => prompted = true;

    await controller.notifyMilestone(RatingPromptSignal.challengeCompleted);

    expect(prompted, isFalse);
  });

  test('low rating routes to feedback and records the ask', () async {
    final store = _FakeStore();
    final launcher = _FakeLauncher();
    final controller = RatingPromptController(store: store, launcher: launcher);
    controller.currentVersion = '1.0.7+12';
    final navigated = <String>[];
    controller.onOpenFeedback = () async => navigated.add('feedback');

    await controller.handleRating(2);

    expect(store.askedAt, isNotNull);
    expect(navigated, ['feedback']);
    expect(launcher.launches, 0);
  });

  test('high rating launches the review flow', () async {
    final store = _FakeStore();
    final launcher = _FakeLauncher();
    final controller = RatingPromptController(store: store, launcher: launcher);
    controller.currentVersion = '1.0.7+12';

    await controller.handleRating(5);

    expect(launcher.launches, 1);
    expect(store.askedAt, isNotNull);
  });

  test('rating of 3 (the threshold low side) routes to feedback', () async {
    final store = _FakeStore();
    final launcher = _FakeLauncher();
    final controller = RatingPromptController(store: store, launcher: launcher);
    controller.currentVersion = '1.0.7+12';
    var openedFeedback = false;
    controller.onOpenFeedback = () async => openedFeedback = true;

    await controller.handleRating(3);

    expect(openedFeedback, isTrue);
    expect(launcher.launches, 0);
    expect(store.askedAt, isNotNull);
  });

  test('rating of 4 (the threshold high side) launches review', () async {
    final store = _FakeStore();
    final launcher = _FakeLauncher();
    final controller = RatingPromptController(store: store, launcher: launcher);
    controller.currentVersion = '1.0.7+12';

    await controller.handleRating(4);

    expect(launcher.launches, 1);
    expect(store.askedAt, isNotNull);
  });

  test('notNow records the ask without reviewing', () async {
    final store = _FakeStore();
    final launcher = _FakeLauncher();
    final controller = RatingPromptController(store: store, launcher: launcher);
    controller.currentVersion = '1.0.7+12';

    await controller.notNow();

    expect(store.askedAt, isNotNull);
    expect(store.version, '1.0.7+12');
    expect(launcher.launches, 0);
  });
}
