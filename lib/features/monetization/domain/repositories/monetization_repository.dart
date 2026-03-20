import 'package:fpdart/fpdart.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

abstract class MonetizationRepository {
  /// Initialize the monetization SDK (e.g. RevenueCat)
  Future<void> initialize({String? uid});

  /// Identify the user in the monetization SDK
  Future<void> identify(String uid);

  /// Reset the user identification (on sign-out)
  Future<void> reset();

  /// Get available offerings
  Future<Either<String, Offerings>> getOfferings();

  /// Get the current entitlement status (e.g. "premium" or null)
  Future<Either<String, bool>> get isPremium;

  /// Purchase a package/product
  Future<Either<String, bool>> purchasePremium();

  /// Restore purchases
  Future<Either<String, bool>> restorePurchases();

  /// Get the price string for the premium package
  Future<String?> get premiumPriceString;

  /// Stream of premium status changes
  Stream<bool> get premiumStatusStream;

  /// Purchase a consumable item by product ID (e.g., a title or nameplate).
  /// Returns Right(true) on success.
  Future<Either<String, bool>> purchaseConsumable(String productId);

  /// Get available consumable products with their price strings.
  Future<Either<String, Map<String, String>>> getConsumablePrices(
    List<String> productIds,
  );
}
