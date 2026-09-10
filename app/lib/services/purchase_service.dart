import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseService {
  static String? _configuredKey;
  static String entitlementId = 'plus';

  /// Initialize RevenueCat SDK with dynamic keys from backend or fallbacks
  static Future<void> init({String? userId, String? googleKey, String? appleKey}) async {
    try {
      String? apiKey;
      if (Platform.isAndroid && googleKey != null && googleKey.isNotEmpty) {
        apiKey = googleKey;
      } else if (Platform.isIOS && appleKey != null && appleKey.isNotEmpty) {
        apiKey = appleKey;
      } else {
        apiKey = googleKey ?? appleKey;
      }

      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('[RevenueCat] No API key configured.');
        return;
      }

      debugPrint('[RevenueCat] Initializing RevenueCat with key: ${apiKey.substring(0, 8)}... (UserID: $userId)');
      await Purchases.setLogLevel(LogLevel.debug);

      if (_configuredKey != apiKey) {
        final configuration = PurchasesConfiguration(apiKey);
        if (userId != null && userId.isNotEmpty) {
          configuration.appUserID = userId;
        }
        await Purchases.configure(configuration);
        _configuredKey = apiKey;
        debugPrint('[RevenueCat] Configured successfully with: ${apiKey.substring(0, 8)}...');
      }

      if (userId != null && userId.isNotEmpty) {
        final logInResult = await Purchases.logIn(userId);
        debugPrint('[RevenueCat] Logged In Customer ID: ${logInResult.customerInfo.originalAppUserId}');
      } else {
        final info = await Purchases.getCustomerInfo();
        debugPrint('[RevenueCat] Customer Info initialized: ${info.originalAppUserId}');
      }
    } catch (e) {
      debugPrint('[RevenueCat Init/Login Error]: $e');
    }
  }

  /// Check if user has active entitlement
  static Future<bool> isUserPremium() async {
    if (_configuredKey == null) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final active = customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
      return active;
    } catch (_) {
      return false;
    }
  }

  /// Purchase an Offering Package
  static Future<Map<String, dynamic>> purchase(Package package) async {
    if (_configuredKey == null) {
      return {'success': false, 'message': 'RevenueCat not configured'};
    }
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      final isPremium = customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
      return {
        'success': isPremium,
        'customerInfo': customerInfo,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Restore purchases (Mandatory for Apple StoreKit Guidelines)
  static Future<bool> restorePurchases() async {
    if (_configuredKey == null) return false;
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Fetch Offerings / Packages from RevenueCat
  static Future<List<Package>> getPackages() async {
    if (_configuredKey == null) return [];
    try {
      final offerings = await Purchases.getOfferings();
      debugPrint('[RevenueCat Offerings Map]: ${offerings.all.keys.toList()}');
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        debugPrint('[RevenueCat Current Packages]: ${offerings.current!.availablePackages.map((p) => p.identifier).toList()}');
        return offerings.current!.availablePackages;
      } else if (offerings.all.isNotEmpty) {
        final firstOffering = offerings.all.values.first;
        debugPrint('[RevenueCat Fallback Packages]: ${firstOffering.availablePackages.map((p) => p.identifier).toList()}');
        return firstOffering.availablePackages;
      }
    } catch (e) {
      debugPrint('[RevenueCat Offerings Error]: $e');
    }
    return [];
  }
}
