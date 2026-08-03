import 'package:emerge_app/features/monetization/domain/models/premium_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 2, 12);

  test('active premium doc is premium', () {
    final state = computePremiumState(
      record: {'isPremium': true},
      now: now,
    );
    expect(state.isPremium, isTrue);
  });

  test('missing or free doc is not premium', () {
    expect(computePremiumState(record: null, now: now).isPremium, isFalse);
    expect(
      computePremiumState(record: {'isPremium': false}, now: now).isPremium,
      isFalse,
    );
  });

  test('paused with future end date stays premium', () {
    final state = computePremiumState(
      record: {
        'isPremium': true,
        'subscriptionStatus': 'paused',
        'premiumEndsAt': now.add(const Duration(days: 30)),
      },
      now: now,
    );
    expect(state.isPremium, isTrue);
    expect(state.isPaused, isTrue);
    expect(state.premiumEndsAt, now.add(const Duration(days: 30)));
  });

  test('paused after end date is free', () {
    final state = computePremiumState(
      record: {
        'isPremium': true,
        'subscriptionStatus': 'paused',
        'premiumEndsAt': now.subtract(const Duration(days: 1)),
      },
      now: now,
    );
    expect(state.isPremium, isFalse);
  });

  test('active status doc is premium', () {
    final state = computePremiumState(
      record: {'isPremium': true, 'subscriptionStatus': 'active'},
      now: now,
    );
    expect(state.isPremium, isTrue);
    expect(state.isPaused, isFalse);
  });

  test('cancelled doc is free', () {
    final state = computePremiumState(
      record: {
        'isPremium': false,
        'subscriptionStatus': 'cancelled',
        'cancelledAt': now,
      },
      now: now,
    );
    expect(state.isPremium, isFalse);
  });

  test('isPremium non-boolean values are not premium', () {
    expect(
      computePremiumState(record: {'isPremium': 'yes'}, now: now).isPremium,
      isFalse,
    );
  });
}
