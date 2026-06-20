import 'package:isar/isar.dart';
import 'package:logging/logging.dart';

import 'storage_service.dart';

part 'version_service.g.dart';

@collection
class VersionData {
  Id id = Isar.autoIncrement;

  String? lastCheckedVersion;
  DateTime? lastCheckedForUpdate;
}

class VersionService {
  VersionService._();

  static final _log = Logger('VersionService');

  static late Isar _isar;

  static Future<void> initialize() async {
    _log.fine('Initializing');
    _isar = await StorageService.getIsar();
  }

  static VersionData _getVersion() {
    return _isar.versionDatas.where().findFirstSync() ?? VersionData();
  }

  static Future<void> _updateVersion(void Function(VersionData) update) async {
    await _isar.writeTxn(() async {
      final version =
          await _isar.versionDatas.where().findFirst() ?? VersionData();
      update(version);
      await _isar.versionDatas.put(version);
    });
  }

  static String? get lastCheckedVersion {
    final version = _getVersion();
    return version.lastCheckedVersion;
  }

  static Future<void> setLastCheckedVersion(String? version) async {
    await _updateVersion((data) {
      data.lastCheckedVersion = version;
    });
  }

  static DateTime? get lastCheckedForUpdate {
    final version = _getVersion();
    return version.lastCheckedForUpdate;
  }

  static Future<void> setLastCheckedForUpdate(DateTime? date) async {
    await _updateVersion((data) {
      data.lastCheckedForUpdate = date;
    });
  }

  /// Restores version state from a previous storage backend. Only non-null
  /// values are applied, so existing data is never overwritten with nulls.
  static Future<void> restore({
    String? lastCheckedVersion,
    DateTime? lastCheckedForUpdate,
  }) async {
    await _updateVersion((data) {
      data.lastCheckedVersion = lastCheckedVersion ?? data.lastCheckedVersion;
      data.lastCheckedForUpdate =
          lastCheckedForUpdate ?? data.lastCheckedForUpdate;
    });
  }
}
