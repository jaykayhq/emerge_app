/// Pure web-vs-native paywall decisions.
///
/// RevenueCat is never configured on web (`revenue_cat_repository.dart:29-34`
/// early-returns; `AppConfig.getRevenueCatApiKey('web')` always returns ''),
/// so `getOfferings()` would only produce the 'RevenueCat not configured'
/// error. Web purchases go through external Paystack pages instead.
/// Extracted as pure functions because `kIsWeb` is compile-time and cannot
/// be faked in widget tests.
library;

/// Whether the RevenueCat offering fetch should run on this platform.
bool shouldFetchOfferings({required bool isWeb}) => !isWeb;

/// Whether a paywall state error should surface as a SnackBar.
/// Errors on web are RevenueCat leftovers; the Paystack page reports its
/// own failures.
bool shouldShowPaywallErrorSnackBar({required bool isWeb, String? error}) =>
    !isWeb && error != null;
