import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../utils/env.dart';

final _userIsSubscribedProvider = StateProvider<bool>((_) => false);

class InAppPurchaseService {
  InAppPurchaseService._();

  static final _log = Logger('InAppPurchaseService');
  static const _premiumEntitlementId = 'premium';
  static WidgetRef? _ref;
  static List<StoreProduct> _products = [];

  static List<StoreProduct> get products => _products;
  static StateProvider<bool> get $userIsSubscribed => _userIsSubscribedProvider;

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

    _loadOfferings();
    await fetchUserSubscription();
  }

  // ignore: use_setters_to_change_properties
  static void setRef(WidgetRef ref) {
    _ref = ref;
    fetchUserSubscription();
  }

  static Future<void> setUserId(String id) async {
    try {
      await Purchases.logIn(id);
      await fetchUserSubscription();
    } catch (e) {
      _log.severe('Failed to set user id', e);
    }
  }

  static Future<void> removeUserId() async {
    try {
      await Purchases.logOut();
      await fetchUserSubscription();
    } catch (e) {
      _log.severe('Failed to remove user id', e);
    }
  }

  static Future<bool> buy(String productIdentifier) async {
    try {
      final customerInfo = await Purchases.purchaseProduct(productIdentifier);
      await fetchUserSubscription();
      return _customerisSubscribed(customerInfo);
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
      await fetchUserSubscription();
      return _customerisSubscribed(restoredInfo);
    } catch (e) {
      _log.severe(e);
    }
    return false;
  }

  static Future<void> fetchUserSubscription() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _ref?.read($userIsSubscribed.notifier).state =
          _customerisSubscribed(customerInfo);
    } catch (e) {
      _log.severe(e);
    }
  }

  static bool _customerisSubscribed(CustomerInfo customerInfo) {
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
