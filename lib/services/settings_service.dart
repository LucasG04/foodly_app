import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/shopping_list_sort.dart';
import '../primary_colors.dart';
import 'in_app_purchase_service.dart';

class SettingsService {
  SettingsService._();

  static late Box _settingsBox;
  static bool _isReady = false;
  static WidgetRef? _ref;

  static Future initialize() async {
    _settingsBox = await Hive.openBox<dynamic>('settings');
    _isReady = true;
  }

  // ignore: use_setters_to_change_properties
  static void setRef(WidgetRef ref) {
    _ref = ref;
  }

  static bool get isReady => _isReady;

  static bool get isFirstUsage =>
      _settingsBox.get('firstUsage', defaultValue: true) as bool;

  static Future<void> setFirstUsageFalse() async {
    await _settingsBox.put('firstUsage', false);
  }

  static bool get multipleMealsPerTime =>
      _settingsBox.get('multipleMealsPerTime', defaultValue: false) as bool;

  static bool get showSuggestions {
    final showSuggestions =
        _settingsBox.get('showSuggestions', defaultValue: true) as bool;
    final userHasPremium =
        _ref?.read(InAppPurchaseService.$userIsSubscribed) ?? false;
    return showSuggestions && userHasPremium;
  }

  static bool get removeBoughtImmediately =>
      _settingsBox.get('removeBoughtImmediately', defaultValue: false) as bool;

  static bool get planWithBreakfast =>
      _settingsBox.get('planWithBreakfast', defaultValue: false) as bool;

  static Color get primaryColor {
    final value = _settingsBox.get('primaryColor') as int?;
    return value != null ? Color(value) : primaryBlueColor;
  }

  static ShoppingListSort? get shoppingListSort {
    final value = _settingsBox.get('shoppingListSort') as int?;
    const defaultSort = ShoppingListSort.name;
    if (value == null) {
      return defaultSort;
    }
    final userHasPremium =
        _ref?.read(InAppPurchaseService.$userIsSubscribed) ?? false;
    final premiumSorts = [ShoppingListSort.group];
    for (final element in ShoppingListSort.values) {
      if (element.index == value) {
        if (premiumSorts.contains(element) && !userHasPremium) {
          return defaultSort;
        }
        return element;
      }
    }
    return defaultSort;
  }

  static List<String> get productGroupOrder {
    final value = _settingsBox.get('productGroupOrder') as List<dynamic>?;
    if (value == null) {
      return <String>[];
    }
    return value.cast<String>();
  }

  static Future<void> setMultipleMealsPerTime(bool value) async {
    await _settingsBox.put('multipleMealsPerTime', value);
  }

  static Future<void> setShowSuggestions(bool value) async {
    await _settingsBox.put('showSuggestions', value);
  }

  static Future<void> setRemoveBoughtImmediately(bool value) async {
    await _settingsBox.put('removeBoughtImmediately', value);
  }

  static Future<void> setPlanWithBreakfast(bool value) async {
    await _settingsBox.put('planWithBreakfast', value);
  }

  static Future<void> setPrimaryColor(Color value) async {
    await _settingsBox.put('primaryColor', value.value);
  }

  static Future<void> setShoppingListSort(ShoppingListSort value) async {
    await _settingsBox.put('shoppingListSort', value.index);
  }

  static Future<void> setProductGroupOrder(List<String> value) async {
    await _settingsBox.put('productGroupOrder', value);
  }

  static Stream<BoxEvent> streamShoppingListSort() {
    return _settingsBox.watch(key: 'shoppingListSort');
  }

  static Stream<BoxEvent> streamMultipleMealsPerTime() {
    return _settingsBox.watch(key: 'multipleMealsPerTime');
  }

  static Stream<bool> streamPlanWithBreakfast() {
    return _settingsBox
        .watch(key: 'planWithBreakfast')
        .map((event) => event.value == true);
  }

  static Stream<List<String>> streamProductGroupOrder() {
    return _settingsBox
        .watch(key: 'productGroupOrder')
        .map((event) => event.value as List<String>);
  }
}
