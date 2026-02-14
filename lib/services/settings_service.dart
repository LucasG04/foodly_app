import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../constants.dart';
import '../models/plan_meal.dart';
import '../models/shopping_list_sort.dart';
import '../primary_colors.dart';
import 'in_app_purchase_service.dart';
import 'storage_service.dart';

part 'settings_service.g.dart';

@collection
class SettingsData {
  Id id = Isar.autoIncrement;

  bool? firstUsage;
  bool? multipleMealsPerTime;
  bool? showSuggestions;
  bool? removeBoughtImmediately;
  int? primaryColor;
  int? shoppingListSort;
  List<String>? productGroupOrder;
  List<int>? activeMealTypes;
  bool? useDevApi;
}

class SettingsService {
  SettingsService._();

  static late Isar _isar;
  static WidgetRef? _ref;

  static Future initialize() async {
    _isar = await StorageService.getIsar();
  }

  // ignore: use_setters_to_change_properties
  static void setRef(WidgetRef ref) {
    _ref = ref;
  }

  static SettingsData _getSettings() {
    return _isar.settingsDatas.where().findFirstSync() ?? SettingsData();
  }

  static Future<void> _updateSettings(void Function(SettingsData) update) async {
    await _isar.writeTxn(() async {
      var settings = _isar.settingsDatas.where().findFirstSync() ?? SettingsData();
      update(settings);
      await _isar.settingsDatas.put(settings);
    });
  }

  static bool get isFirstUsage {
    final settings = _getSettings();
    return settings.firstUsage ?? true;
  }

  static Future<void> setFirstUsageFalse() async {
    await _updateSettings((settings) {
      settings.firstUsage = false;
    });
  }

  static bool get multipleMealsPerTime {
    final settings = _getSettings();
    return settings.multipleMealsPerTime ?? false;
  }

  static bool get showSuggestions {
    final settings = _getSettings();
    final showSuggestions = settings.showSuggestions ?? true;
    final userHasPremium =
        _ref?.read(InAppPurchaseService.$userIsSubscribed) ?? false;
    return showSuggestions && userHasPremium;
  }

  static bool get removeBoughtImmediately {
    final settings = _getSettings();
    return settings.removeBoughtImmediately ?? false;
  }

  static Color get primaryColor {
    final settings = _getSettings();
    final value = settings.primaryColor;
    return value != null ? Color(value) : defaultPrimaryColor;
  }

  static ShoppingListSort? get shoppingListSort {
    final settings = _getSettings();
    final value = settings.shoppingListSort;
    if (value == null) {
      return defaultShoppingListSort;
    }
    final userHasPremium =
        _ref?.read(InAppPurchaseService.$userIsSubscribed) ?? false;
    final premiumSorts = [ShoppingListSort.group];
    for (final element in ShoppingListSort.values) {
      if (element.index == value) {
        if (premiumSorts.contains(element) && !userHasPremium) {
          return defaultShoppingListSort;
        }
        return element;
      }
    }
    return defaultShoppingListSort;
  }

  static List<String> get productGroupOrder {
    final settings = _getSettings();
    return settings.productGroupOrder ?? <String>[];
  }

  static List<MealType> get activeMealTypes {
    final settings = _getSettings();
    return _convertToMealTypes(settings.activeMealTypes);
  }

  static bool get useDevApi {
    final settings = _getSettings();
    return settings.useDevApi ?? false;
  }

  static Future<void> setMultipleMealsPerTime(bool value) async {
    await _updateSettings((settings) {
      settings.multipleMealsPerTime = value;
    });
  }

  static Future<void> setShowSuggestions(bool value) async {
    await _updateSettings((settings) {
      settings.showSuggestions = value;
    });
  }

  static Future<void> setRemoveBoughtImmediately(bool value) async {
    await _updateSettings((settings) {
      settings.removeBoughtImmediately = value;
    });
  }

  static Future<void> setPrimaryColor(Color value) async {
    await _updateSettings((settings) {
      settings.primaryColor = value.toARGB32();
    });
  }

  static Future<void> setShoppingListSort(ShoppingListSort value) async {
    await _updateSettings((settings) {
      settings.shoppingListSort = value.index;
    });
  }

  static Future<void> setProductGroupOrder(List<String> value) async {
    await _updateSettings((settings) {
      settings.productGroupOrder = value;
    });
  }

  static Future<void> setActiveMealTypes(List<MealType> value) async {
    await _updateSettings((settings) {
      settings.activeMealTypes = value.map((e) => e.index).toList();
    });
  }

  static Future<void> setUseDevApi(bool value) async {
    await _updateSettings((settings) {
      settings.useDevApi = value;
    });
  }

  static Stream<void> streamShoppingListSort() {
    return _isar.settingsDatas.watchLazy();
  }

  static Stream<void> streamMultipleMealsPerTime() {
    return _isar.settingsDatas.watchLazy();
  }

  static Stream<List<MealType>> streamActiveMealTypes() {
    return _isar.settingsDatas.watchLazy().map((_) {
      final settings = _getSettings();
      return _convertToMealTypes(settings.activeMealTypes);
    });
  }

  static Stream<List<String>> streamProductGroupOrder() {
    return _isar.settingsDatas.watchLazy().map((_) {
      final settings = _getSettings();
      return settings.productGroupOrder ?? <String>[];
    });
  }

  static Stream<bool> streamUseDevApi() {
    return _isar.settingsDatas.watchLazy().map((_) {
      final settings = _getSettings();
      return settings.useDevApi ?? false;
    });
  }

  static List<MealType> _convertToMealTypes(List<int>? value) {
    final defaultValues = [MealType.LUNCH, MealType.DINNER];
    try {
      if (value == null) {
        return defaultValues;
      }
      return value.map((e) => MealType.values[e]).toList();
    } catch (e) {
      return defaultValues;
    }
  }
}
