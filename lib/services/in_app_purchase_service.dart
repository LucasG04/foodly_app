import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logging/logging.dart';

import '../models/purchasable_product.dart';
import '../models/store_state.dart';
import 'authentication_service.dart';
import 'foodly_user_service.dart';

class InAppPurchaseService {
  InAppPurchaseService._();

  static final _log = Logger('InAppPurchaseService');
  static const _storeKeySubscriptionMonth = 'premium_monthly';
  static const _storeKeySubscriptionYear = 'premium_yearly';

  static StoreState _storeState = StoreState.loading;
  static List<PurchasableProduct> _products = [];
  static late StreamSubscription<List<PurchaseDetails>> _$purchases;

  static List<PurchasableProduct> get products => _products;
  static StoreState get storeState => _storeState;

  static Future<void> initialize() async {
    _$purchases = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );
    await _loadPurchases();
  }

  static Future<void> _loadPurchases() async {
    if (_products.isNotEmpty) {
      return;
    }
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      _storeState = StoreState.notAvailable;
      return;
    }
    final ids = <String>{
      _storeKeySubscriptionMonth,
      _storeKeySubscriptionYear,
    };
    final response = await InAppPurchase.instance.queryProductDetails(ids);
    for (final element in response.notFoundIDs) {
      _log.finer('Purchase $element not found');
    }
    _products =
        response.productDetails.map((e) => PurchasableProduct(e)).toList();
    _storeState = StoreState.available;
  }

  static Future<void> buy(PurchasableProduct product) async {
    final purchaseParam = PurchaseParam(productDetails: product.productDetails);
    if (product.id == _storeKeySubscriptionMonth ||
        product.id == _storeKeySubscriptionYear) {
      await InAppPurchase.instance
          .buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      _log.severe(
          product.productDetails, '${product.id} is not a known product');
    }
  }

  static void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach(_handlePurchase);
  }

  static void _handlePurchase(PurchaseDetails purchaseDetails) {
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      if (purchaseDetails.productID == _storeKeySubscriptionMonth) {
        _log.finer('Purchased month subscription');
        final now = DateTime.now();
        final expiresAt = DateTime(
          now.year,
          now.month + 1,
          now.day,
          now.hour,
          now.minute,
        );
        if (AuthenticationService.currentUser != null) {
          FoodlyUserService.subscribeToPremium(
            AuthenticationService.currentUser!.uid,
            expiresAt,
          );
        } else {
          _log.severe('ERR! No user logged in');
        }
      } else if (purchaseDetails.productID == _storeKeySubscriptionYear) {
        _log.finer('Purchased year subscription');
      }
    }

    if (purchaseDetails.pendingCompletePurchase) {
      InAppPurchase.instance.completePurchase(purchaseDetails);
    }
  }

  static Future<void> restore() async {
    // TODO: handle validation: https://pub.dev/packages/in_app_purchase#restoring-previous-purchases
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      _log.severe(e);
    }
  }

  static void _updateStreamOnDone() {
    _$purchases.cancel();
  }

  static void _updateStreamOnError(dynamic error) {
    _log.severe('ERR! in app purchase stream', error);
  }
}
