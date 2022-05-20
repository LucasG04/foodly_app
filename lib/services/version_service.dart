import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';

import '../models/foodly_version.dart';

class VersionService {
  VersionService._();

  static final _log = Logger('ShoppingListService');

  static late Box _settingsBox;
  static bool _isReady = false;

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
    _isReady = true;
  }

  static bool get isReady => _isReady;

  static String? get lastCheckedVersion =>
      _settingsBox.get('lastCheckedVersion') as String?;

  static set lastCheckedVersion(String? version) {
    _settingsBox.put('lastCheckedVersion', version);
  }

  static Future<FoodlyVersion?> getNotesForVersionAndLanguage(
      String version, String languageCode) async {
    _log.fine('getNotesForVersionAndLanguage with $version and $languageCode');
    final snaps = await _firestore.where('version', isEqualTo: version).get();

    if (snaps.size < 1) {
      return null;
    }

    final requestedVersion = snaps.docs.first.data();
    requestedVersion.notes.removeWhere((e) => e.language != languageCode);
    return requestedVersion;
  }
}
