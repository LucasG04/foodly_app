import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';

import '../models/foodly_version.dart';

class VersionService {
  VersionService._();

  static final log = Logger('ShoppingListService');

  static late Box _settingsBox;
  static bool _isReady = false;

  static final CollectionReference<FoodlyVersion> _firestore = FirebaseFirestore
      .instance
      .collection('shoppinglists')
      .withConverter<FoodlyVersion>(
        fromFirestore: (snapshot, _) => FoodlyVersion.fromMap(snapshot.data()!),
        toFirestore: (model, _) => model.toMap(),
      );

  static Future initialize() async {
    _settingsBox = await Hive.openBox<dynamic>('verison');
    _isReady = true;
  }

  static bool get isReady => _isReady;

  static String? get lastCheckedVersion =>
      _settingsBox.get('lastCheckedVersion') as String?;

  static Future<FoodlyVersion> getNotesForVersionAndLanguage(
      String version, String languageCode) async {
    //TODO
    return [];
  }
}
