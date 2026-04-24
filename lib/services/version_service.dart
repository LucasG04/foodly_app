import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';

class VersionService {
  VersionService._();

  static final _log = Logger('VersionService');
  static late Box _settingsBox;

  static Future<void> initialize() async {
    _log.fine('Initializing');
    _settingsBox = await Hive.openBox<dynamic>('verison');
  }

  static String? get lastCheckedVersion =>
      _settingsBox.get('lastCheckedVersion') as String?;

  static set lastCheckedVersion(String? version) {
    _settingsBox.put('lastCheckedVersion', version);
  }

  static DateTime? get lastCheckedForUpdate =>
      _settingsBox.get('lastCheckedForUpdate') as DateTime?;

  static set lastCheckedForUpdate(DateTime? date) {
    _settingsBox.put('lastCheckedForUpdate', date);
  }
}
