import 'dart:async';
import 'package:emerge_app/core/config/app_config.dart';
import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/monetization/domain/repositories/monetization_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
class RevenueCatRepository implements MonetizationRepository {
  String? _googleApiKey;
  String? _appleApiKey;

  RevenueCatRepository();

  static const _entitlementId =
      'premium'; // The identifier you set in RevenueCat

  final _premiumStatusController = StreamController<bool>.broadcast();

  @override
  Stream<bool> get premiumStatusStream => _premiumStatusController.stream;

  Completer<void>? _initCompleter;

  @override
  Future<void> initialize({String? uid}) async {
    // If already configured and no new UID is provided, we are done
    if (_isConfigured && uid == null) return;

    // If already configured and same UID is provided, we are done
    if (_isConfigured && uid != null && uid == _currentUid) return;

    // If already configured but new UID is provided, use identify instead of re-configuring
    if (_isConfigured && uid != null && uid != _currentUid) {
      await identify(uid);
      return;
    }

    // Guard against concurrent initialization attempts
    if (_initCompleter != null) {
      await _initCompleter!.future;
      // Re-check after previous initialization finishes
      if (_isConfigured) {
        if (uid != null && uid != _currentUid) {
          await identify(uid);
        }
        return;
      }
    }

    _initCompleter = Completer<void>();
    try {

    // Initialize API keys if not already set
    _googleApiKey ??= AppConfig.getRevenueCatApiKey('android');
    _appleApiKey ??= AppConfig.getRevenueCatApiKey('ios');
    final webApiKey = AppConfig.getRevenueCatApiKey('web');

    String currentKey = '';
    if (kIsWeb) {
      currentKey = webApiKey;
      if (kDebugMode) {
        AppLogger.i('RevenueCat: Initializing for Web with key: ${currentKey.isNotEmpty ? "SET" : "EMPTY"}');
      }
    } else {
      // Use defaultTargetPlatform instead of Platform to be web-safe
      final isAndroid = defaultTargetPlatform == TargetPlatform.android;
      currentKey = (isAndroid ? _googleApiKey : _appleApiKey) ?? '';
    }

    if (currentKey.isEmpty) {
      AppLogger.w('RevenueCat not configured for ${kIsWeb ? "web" : defaultTargetPlatform.name} - skipping initialization');
      _isConfigured = false;
      return;
    }

    // Validate configuration
    if (AppConfig.isProduction && !_validateProductionConfig()) {
      AppLogger.w('RevenueCat: Invalid production config detected');
    }

    await Purchases.setLogLevel(
      AppConfig.isDevelopment ? LogLevel.debug : LogLevel.error,
    );

      PurchasesConfiguration configuration;
      if (kIsWeb) {
        configuration = PurchasesConfiguration(webApiKey);
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        configuration = PurchasesConfiguration(_googleApiKey!);
      } else {
        configuration = PurchasesConfiguration(_appleApiKey!);
      }

      // Link User UID if provided
      if (uid != null && uid.isNotEmpty) {
        configuration.appUserID = uid;
        _currentUid = uid;
        if (kDebugMode) AppLogger.i('RevenueCat: Setting App User ID: $uid');
      }

      await Purchases.configure(configuration);
      _isConfigured = true;
      AppLogger.i('RevenueCat initialized successfully for ${kIsWeb ? "web" : "mobile"}');

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        final isPremium =
            customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
        _premiumStatusController.add(isPremium);
      });
    } catch (e) {
      AppLogger.e('RevenueCat configuration failed', e);
      _isConfigured = false;
    } finally {
      _initCompleter?.complete();
      _initCompleter = null;
    }
  }

  @override
  Future<void> identify(String uid) async {
    if (uid.isEmpty) {
      AppLogger.w('RevenueCat: Cannot identify with empty UID');
      return;
    }

    if (!_isConfigured) {
      // Re-try initialization with the UID
      await initialize(uid: uid);
      return;
    }
    
    if (uid == _currentUid) return;

    try {
      await Purchases.logIn(uid);
      _currentUid = uid;
      AppLogger.i('RevenueCat identified user: $uid');
    } catch (e) {
      AppLogger.w('RevenueCat identify failed: $e');
    }
  }

  @override
  Future<void> reset() async {
    if (!_isConfigured) return;
    try {
      await Purchases.logOut();
      _currentUid = null;
      AppLogger.i('RevenueCat user reset');
    } catch (e) {
      AppLogger.w('RevenueCat reset failed: $e');
    }
  }

  bool _validateProductionConfig() {
    if (kIsWeb) return AppConfig.getRevenueCatApiKey('web').isNotEmpty;
    return (_googleApiKey?.isNotEmpty ?? false) &&
        !(_googleApiKey?.startsWith('test_') ?? false) &&
        (_appleApiKey?.isNotEmpty ?? false) &&
        _appleApiKey != 'YOUR_REVENUECAT_APPLE_API_KEY';
  }

  @override
  Future<Either<String, Offerings>> getOfferings() async {
    if (!_isConfigured) {
      return const Left('RevenueCat not configured');
    }
    try {
      final offerings = await Purchases.getOfferings();
      if (kDebugMode) {
        AppLogger.i('RevenueCat Offerings: ${offerings.all.length} total, current: ${offerings.current != null ? "FOUND" : "NULL"}');
        if (offerings.current != null) {
          AppLogger.i('RevenueCat Current Offering: ${offerings.current!.identifier}, Packages: ${offerings.current!.availablePackages.length}');
        }
      }
      return Right(offerings);
    } on PlatformException catch (e) {
      AppLogger.e('RevenueCat PlatformException fetching offerings: ${e.message} (Code: ${e.code})');
      return Left(e.message ?? 'Failed to fetch offerings');
    } catch (e) {
      AppLogger.e('RevenueCat error fetching offerings', e);
      return Left(e.toString());
    }
  }

  /// Raw customer info access for verification (internal use)
  Future<CustomerInfo?> getCustomerInfoRaw() async {
    if (!_isConfigured) return null;
    return await Purchases.getCustomerInfo();
  }

  @override
  Future<Either<String, bool>> get isPremium async {
    if (!_isConfigured) {
      return const Right(false);
    }
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isPremium =
          customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
      
      // Cache the result
      await _cacheService?.savePremiumStatus(isPremium);
      
      return Right(isPremium);
    } on PlatformException catch (e) {
      AppLogger.w('RevenueCat: Failed to check premium status offline: ${e.message}');
      return Left(e.message ?? 'Failed to check subscription status');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> purchasePremium() async {
    if (!_isConfigured) {
      return const Left('RevenueCat not configured');
    }
    try {
      final offerings = await Purchases.getOfferings();
      
      // Fallback logic: Use current offering, or the first one found if current is null
      final offering = offerings.current ?? 
                       (offerings.all.isNotEmpty ? offerings.all.values.first : null);

      if (offering != null && offering.availablePackages.isNotEmpty) {
        final package = offering.availablePackages.first;
        // Use new purchase API
        final purchaseResult = await Purchases.purchase(
          PurchaseParams.package(package),
        );
        final isPremium =
            purchaseResult
                .customerInfo
                .entitlements
                .all[_entitlementId]
                ?.isActive ??
            false;
        return Right(isPremium);
      } else {
        return const Left('No offerings available in RevenueCat');
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return const Left('Purchase cancelled');
      }
      return Left(e.message ?? 'Purchase failed');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, bool>> restorePurchases() async {
    if (!_isConfigured) {
      return const Left('RevenueCat not configured');
    }
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isPremium =
          customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
      return Right(isPremium);
    } on PlatformException catch (e) {
      return Left(e.message ?? 'Restore failed');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<String?> get premiumPriceString async {
    if (!_isConfigured) return null;
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        return offerings
            .current!
            .availablePackages
            .first
            .storeProduct
            .priceString;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Either<String, bool>> purchaseConsumable(String productId) async {
    if (!_isConfigured) {
      return const Left('RevenueCat not configured');
    }
    try {
      final products = await Purchases.getProducts([
        productId,
      ], productCategory: ProductCategory.nonSubscription);
      if (products.isEmpty) {
        return Left('Product not found: $productId');
      }
      final product = products.first;
      await Purchases.purchase(PurchaseParams.storeProduct(product));
      return const Right(true);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return const Left('Purchase cancelled');
      }
      return Left(e.message ?? 'Purchase failed');
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, Map<String, String>>> getConsumablePrices(
    List<String> productIds,
  ) async {
    if (!_isConfigured) {
      return const Left('RevenueCat not configured');
    }
    try {
      final products = await Purchases.getProducts(
        productIds,
        productCategory: ProductCategory.nonSubscription,
      );
      final prices = <String, String>{};
      for (final product in products) {
        prices[product.identifier] = product.priceString;
      }
      return Right(prices);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
