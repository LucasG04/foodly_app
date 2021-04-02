import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class SettingsService {
  SettingsService._();

  static Box _settingsBox;
  static bool _isReady = false;

  static Future initialize() async {
    var dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    _settingsBox = await Hive.openBox('settings');
    _isReady = true;
  }

  static bool get isReady => _isReady;

  static bool get isFirstUsage => _settingsBox.get('firstUsage') ?? true;

  static Future<void> setFirstUsageFalse() async {
    await _settingsBox.put('firstUsage', false);
  }
}
