import 'dart:io';

import 'package:emerge_app/core/config/app_config.dart';
import 'package:emerge_app/features/monetization/domain/repositories/monetization_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatRepository implements MonetizationRepository {
  late final String _googleApiKey;
  late final String _appleApiKey;
  bool _isConfigured = false;

  static const _entitlementId =
      'premium'; // The identifier you set in RevenueCat

  @override
  Future<void> initialize() async {
    // Initialize API keys from secure config
    _googleApiKey = AppConfig.getRevenueCatApiKey('android');
    _appleApiKey = AppConfig.getRevenueCatApiKey('ios');

    // Skip initialization if keys are not configured (development mode)
    final currentKey = Platform.isAndroid ? _googleApiKey : _appleApiKey;
    if (currentKey.isEmpty) {
      debugPrint('⚠️ RevenueCat not configured - skipping initialization');
      _isConfigured = false;
      return;
    }

    // Validate configuration
    if (AppConfig.isProduction && !_validateProductionConfig()) {
      throw Exception(
        'Invalid RevenueCat configuration for production environment',
      );
    }

    await Purchases.setLogLevel(
      AppConfig.isDevelopment ? LogLevel.debug : LogLevel.error,
    );

    PurchasesConfiguration configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_googleApiKey);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(_appleApiKey);
    } else {
      return;
    }

    await Purchases.configure(configuration);
    _isConfigured = true;
  }

  bool _validateProductionConfig() {
    return _googleApiKey.isNotEmpty &&
        !_googleApiKey.startsWith('test_') &&
        _appleApiKey.isNotEmpty &&
        _appleApiKey != 'YOUR_REVENUECAT_APPLE_API_KEY';
  }

  /// Raw customer info access for verification (internal use)
  Future<CustomerInfo?> getCustomerInfoRaw() async {
    if (!_isConfigured) return null;
    return await Purchases.getCustomerInfo();
  }

  @override
  Future<Either<String, bool>> get isPremium async {
    if (!_isConfigured) {
      // TESTING MODE: Treat as premium user when RevenueCat not configured
      // Change back to `return const Right(false);` to enable paywall
      return const Right(true);
    }
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isPremium =
          customerInfo.entitlements.all[_entitlementId]?.isActive ?? false;
      return Right(isPremium);
    } on PlatformException catch (e) {
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
      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        final package = offerings.current!.availablePackages.first;
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
        return const Left('No offerings available');
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
}
