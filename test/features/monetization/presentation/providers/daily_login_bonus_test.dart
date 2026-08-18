import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:emerge_app/features/monetization/presentation/providers/subscription_provider.dart';

class _TestIsPremium extends IsPremium {
  final bool premium;
  _TestIsPremium(this.premium);

  @override
  Future<bool> build() async => premium;
}

ProviderContainer _container({required bool premium}) {
  final c = ProviderContainer(
    overrides: [isPremiumProvider.overrideWith(() => _TestIsPremium(premium))],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('free users never get a daily bonus', () async {
    final c = _container(premium: false);
    final available = await c.read(dailyLoginBonusProvider.future);
    expect(available, isFalse);
  });

  test('premium users get a bonus when unclaimed today', () async {
    final c = _container(premium: true);
    final available = await c.read(dailyLoginBonusProvider.future);
    expect(available, isTrue);
  });

  test('claiming persists and prevents a second claim today', () async {
    final c = _container(premium: true);
    expect(await c.read(dailyLoginBonusProvider.future), isTrue);

    await c.read(dailyLoginBonusProvider.notifier).claimBonus();
    expect(c.read(dailyLoginBonusProvider).value, isFalse);

    // A fresh container (same prefs) must see the claim as consumed today.
    final c2 = _container(premium: true);
    expect(await c2.read(dailyLoginBonusProvider.future), isFalse);
  });
}
