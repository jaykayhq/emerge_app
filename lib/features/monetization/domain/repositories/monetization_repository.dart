import 'package:fpdart/fpdart.dart';

abstract class MonetizationRepository {
  /// Initialize the monetization SDK (e.g. RevenueCat)
  Future<void> initialize();

  /// Get the current entitlement status (e.g. "premium" or null)
  Future<Either<String, bool>> get isPremium;

  /// Purchase a package/product
  Future<Either<String, bool>> purchasePremium();

  /// Restore purchases
  Future<Either<String, bool>> restorePurchases();

  /// Get the price string for the premium package
  Future<String?> get premiumPriceString;

  /// Purchase a consumable item by product ID (e.g., a title or nameplate).
  /// Returns Right(true) on success.
  Future<Either<String, bool>> purchaseConsumable(String productId);

  /// Get available consumable products with their price strings.
  Future<Either<String, Map<String, String>>> getConsumablePrices(
    List<String> productIds,
  );
}
