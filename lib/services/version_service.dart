import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar/isar.dart';
import 'package:logging/logging.dart';

import '../models/foodly_version.dart';
import 'storage_service.dart';

@collection
class VersionData {
  Id id = Isar.autoIncrement;

  String? lastCheckedVersion;
  DateTime? lastCheckedForUpdate;
}

class VersionService {
  VersionService._();

  static final _log = Logger('ShoppingListService');

  static late Isar _isar;

  static final CollectionReference<FoodlyVersion> _firestore = FirebaseFirestore
      .instance
      .collection('versions')
      .withConverter<FoodlyVersion>(
        fromFirestore: (snapshot, _) => FoodlyVersion.fromMap(snapshot.data()!),
        toFirestore: (model, _) => model.toMap(),
      );

  static Future initialize() async {
    _log.fine('Initializing');
    _isar = await StorageService.getIsar();
  }

  static VersionData _getVersion() {
    return _isar.versionDatas.where().findFirstSync() ?? VersionData();
  }

  static Future<void> _updateVersion(void Function(VersionData) update) async {
    await _isar.writeTxn(() async {
      var version = _isar.versionDatas.where().findFirstSync() ?? VersionData();
      update(version);
      await _isar.versionDatas.put(version);
    });
  }

  static String? get lastCheckedVersion {
    final version = _getVersion();
    return version.lastCheckedVersion;
  }

  static set lastCheckedVersion(String? version) {
    _updateVersion((data) {
      data.lastCheckedVersion = version;
    });
  }

  static DateTime? get lastCheckedForUpdate {
    final version = _getVersion();
    return version.lastCheckedForUpdate;
  }

  static set lastCheckedForUpdate(DateTime? date) {
    _updateVersion((data) {
      data.lastCheckedForUpdate = date;
    });
  }

  static Future<List<FoodlyVersion>?> getNotesForVersionsAndLanguage(
      List<String> versions, String languageCode) async {
    _log.fine('getNotesForVersionAndLanguage with $versions and $languageCode');

    if (versions.isEmpty || languageCode.isEmpty) {
      return [];
    }

    final snaps = await _firestore.where('version', whereIn: versions).get();

    if (snaps.size < 1) {
      return null;
    }

    final requestedVersions = snaps.docs.map((e) => e.data()).toList();
    for (final version in requestedVersions) {
      version.notes.removeWhere((e) => e.language != languageCode);
    }
    return requestedVersions;
  }
}
