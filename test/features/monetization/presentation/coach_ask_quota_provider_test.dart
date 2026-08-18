import 'package:emerge_app/features/monetization/domain/services/coach_ask_quota.dart';
import 'package:emerge_app/features/monetization/presentation/providers/coach_ask_quota_provider.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeIsPremium extends IsPremium {
  _FakeIsPremium(this._premium);
  final bool _premium;

  @override
  Future<bool> build() async => _premium;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer makeContainer({bool premium = false}) {
    return ProviderContainer(
      overrides: [
        isPremiumProvider.overrideWith(() => _FakeIsPremium(premium)),
      ],
    );
  }

  test('free user starts at 3 remaining', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    final quota = await container.read(coachAskQuotaControllerProvider.future);
    expect(quota.remaining, 3);
  });

  test('consume persists the counter to shared_prefs', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    final before = await container.read(coachAskQuotaControllerProvider.future);

    await container.read(coachAskQuotaControllerProvider.notifier).consume();

    final after = await container.read(coachAskQuotaControllerProvider.future);
    expect(after.usedToday, 1);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('coach_asks_${before.dateKey}'), 1);
  });

  test('premium user consume never increments the counter', () async {
    final container = makeContainer(premium: true);
    addTearDown(container.dispose);
    final before = await container.read(coachAskQuotaControllerProvider.future);

    final after = await container
        .read(coachAskQuotaControllerProvider.notifier)
        .consume();

    expect(after.usedToday, 0);
    expect(before.usedToday, 0);
  });

  test('consume rolls over when state is from a previous day', () async {
    final yesterday = CoachAskQuota.dateKeyFor(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    SharedPreferences.setMockInitialValues({'coach_asks_$yesterday': 3});

    final container = makeContainer();
    addTearDown(container.dispose);
    final before = await container.read(coachAskQuotaControllerProvider.future);
    expect(before.usedToday, 0); // Today's key is fresh.

    await container.read(coachAskQuotaControllerProvider.notifier).consume();

    final after = await container.read(coachAskQuotaControllerProvider.future);
    expect(after.usedToday, 1);

    final prefs = await SharedPreferences.getInstance();
    final today = CoachAskQuota.dateKeyFor(DateTime.now());
    expect(prefs.getInt('coach_asks_$today'), 1);
    expect(prefs.getInt('coach_asks_$yesterday'), 3); // Untouched.
  });

  test('rapid double consume does not lose updates', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    await container.read(coachAskQuotaControllerProvider.future);

    final notifier = container.read(coachAskQuotaControllerProvider.notifier);
    // Fire both without awaiting the first; the synchronous state write in
    // consume() must prevent both from reading the same count.
    final f1 = notifier.consume();
    final f2 = notifier.consume();
    await Future.wait([f1, f2]);

    final after = container.read(coachAskQuotaControllerProvider).value;
    expect(after?.usedToday, 2);

    final prefs = await SharedPreferences.getInstance();
    final today = CoachAskQuota.dateKeyFor(DateTime.now());
    expect(prefs.getInt('coach_asks_$today'), 2);
  });
}
