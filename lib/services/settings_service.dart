import 'package:hive/hive.dart';

class SettingsService {
  SettingsService._();

  static late Box _settingsBox;
  static bool _isReady = false;

  static Future initialize() async {
    _settingsBox = await Hive.openBox('settings');
    _isReady = true;
  }

  static bool get isReady => _isReady;

  static bool get isFirstUsage => _settingsBox.get('firstUsage') ?? true;

  static Future<void> setFirstUsageFalse() async {
    await _settingsBox.put('firstUsage', false);
  }

  static bool get multipleMealsPerTime =>
      _settingsBox.get('multipleMealsPerTime') ?? true;

  static bool get showSuggestions =>
      _settingsBox.get('showSuggestions') ?? true;

  static Future<void> setMultipleMealsPerTime(bool value) async {
    await _settingsBox.put('multipleMealsPerTime', value);
  }

  static Future<void> setShowSuggestions(bool value) async {
    await _settingsBox.put('showSuggestions', value);
  }
}
