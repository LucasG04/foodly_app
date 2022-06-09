import 'package:hive/hive.dart';

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

  static Future<void> setMultipleMealsPerTime(bool value) async {
    await _settingsBox.put('multipleMealsPerTime', value);
  }

  static Future<void> setShowSuggestions(bool value) async {
    await _settingsBox.put('showSuggestions', value);
  }

  static Future<void> setRemoveBoughtImmediately(bool value) async {
    await _settingsBox.put('removeBoughtImmediately', value);
  }

  static Stream<BoxEvent> streamMultipleMealsPerTime() {
    return _settingsBox.watch(key: 'multipleMealsPerTime');
  }
}
