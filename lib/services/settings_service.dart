import 'package:flutter/painting.dart';
import 'package:hive/hive.dart';

import '../models/shopping_list_sort.dart';

class SettingsService {
  SettingsService._();

  static late Box _settingsBox;
  static bool _isReady = false;

  static Future initialize() async {
    _settingsBox = await Hive.openBox<dynamic>('settings');
    _isReady = true;
  }

  static bool get isReady => _isReady;

  static bool get isFirstUsage =>
      _settingsBox.get('firstUsage', defaultValue: true) as bool;

  static Future<void> setFirstUsageFalse() async {
    await _settingsBox.put('firstUsage', false);
  }

  static bool get multipleMealsPerTime =>
      _settingsBox.get('multipleMealsPerTime', defaultValue: false) as bool;

  static bool get showSuggestions =>
      _settingsBox.get('showSuggestions', defaultValue: true) as bool;

  static bool get removeBoughtImmediately =>
      _settingsBox.get('removeBoughtImmediately', defaultValue: false) as bool;

  static bool get planWithBreakfast =>
      _settingsBox.get('planWithBreakfast', defaultValue: false) as bool;

  static Color? get primaryColor => _settingsBox.get('primaryColor') as Color?;

  static ShoppingListSort? get shoppingListSort {
    final value = _settingsBox.get('shoppingListSort') as int?;
    if (value == null) {
      return ShoppingListSort.name;
    }
    for (final element in ShoppingListSort.values) {
      if (element.index == value) {
        return element;
      }
    }
    return ShoppingListSort.name;
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
    await _settingsBox.put('primaryColor', value);
  }

  static Future<void> setShoppingListSort(ShoppingListSort value) async {
    await _settingsBox.put('shoppingListSort', value.index);
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
}
