import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';

import '../models/foodly_version.dart';

class VersionService {
  VersionService._();

  static final _log = Logger('ShoppingListService');

  static late Box _settingsBox;

  static final CollectionReference<FoodlyVersion> _firestore = FirebaseFirestore
      .instance
      .collection('versions')
      .withConverter<FoodlyVersion>(
        fromFirestore: (snapshot, _) => FoodlyVersion.fromMap(snapshot.data()!),
        toFirestore: (model, _) => model.toMap(),
      );

  static Future initialize() async {
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
