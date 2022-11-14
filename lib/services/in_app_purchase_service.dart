import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../utils/env.dart';

class InAppPurchaseService {
  InAppPurchaseService._();

  static final _log = Logger('InAppPurchaseService');
  static const _premiumEntitlementId = 'premium';

  static List<StoreProduct> _products = [];
  static bool _userIsSubscribed = false;

  static List<StoreProduct> get products => _products;
  static bool get userIsSubscribed => _userIsSubscribed;

  static Future<void> initialize() async {
    await Purchases.setDebugLogsEnabled(true);

    PurchasesConfiguration? configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(Env.revenuecatGoogleKey);
    } else if (Platform.isIOS || Platform.isMacOS) {
      configuration = PurchasesConfiguration(Env.revenuecatAppleKey);
    }

    if (configuration != null) {
      await Purchases.configure(configuration);
    }

    await _loadOfferings();
    fetchUserSubscription();
  }

  static Future<void> setUserId(String id) async {
    try {
      await Purchases.logIn(id);
      fetchUserSubscription();
    } catch (e) {
      _log.severe('Failed to set user id', e);
    }
  }

  static Future<void> removeUserId() async {
    try {
      await Purchases.logOut();
      fetchUserSubscription();
    } catch (e) {
      _log.severe('Failed to remove user id', e);
    }
  }

  static Future<bool> buy(String productIdentifier) async {
    try {
      final customerInfo = await Purchases.purchaseProduct(productIdentifier);
      fetchUserSubscription();
      return _customerHasPremium(customerInfo);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        _log.severe(e);
      }
    }
    return false;
  }

  static Future<bool> restore() async {
    try {
      final restoredInfo = await Purchases.restorePurchases();
      fetchUserSubscription();
      return _customerHasPremium(restoredInfo);
    } catch (e) {
      _log.severe(e);
    }
    return false;
  }

  static Future<void> fetchUserSubscription() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _userIsSubscribed = _customerHasPremium(customerInfo);
    } catch (e) {
      _log.severe(e);
    }
  }

  static bool _customerHasPremium(CustomerInfo customerInfo) {
    final entitlementInfo =
        customerInfo.entitlements.all[_premiumEntitlementId];
    return entitlementInfo != null && entitlementInfo.isActive;
  }

  static Future<void> _loadOfferings() async {
    if (_products.isNotEmpty) {
      return;
    }
    try {
      final Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        _products = offerings.current!.availablePackages
            .map((e) => e.storeProduct)
            .toList();
      }
    } catch (e) {
      _log.severe('Failed to get offerings', e);
    }
  }
}
