import 'package:emerge_app/features/monetization/domain/services/paywall_web_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldFetchOfferings', () {
    test('web never fetches RevenueCat offerings', () {
      expect(shouldFetchOfferings(isWeb: true), isFalse);
    });

    test('native fetches offerings', () {
      expect(shouldFetchOfferings(isWeb: false), isTrue);
    });
  });

  group('shouldShowPaywallErrorSnackBar', () {
    test('web suppresses error snackbars regardless of error', () {
      expect(
        shouldShowPaywallErrorSnackBar(isWeb: true, error: 'RevenueCat not configured'),
        isFalse,
      );
    });

    test('native surfaces a non-null error', () {
      expect(
        shouldShowPaywallErrorSnackBar(isWeb: false, error: 'Purchase failed'),
        isTrue,
      );
    });

    test('native stays quiet when there is no error', () {
      expect(shouldShowPaywallErrorSnackBar(isWeb: false, error: null), isFalse);
    });
  });
}
