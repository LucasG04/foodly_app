import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../models/grocery.dart';
import '../models/shopping_list.dart';
import 'lunix_api_service.dart';

class ShoppingListService {
  static final _log = Logger('ShoppingListService');

  static final CollectionReference<ShoppingList> _firestore = FirebaseFirestore
      .instance
      .collection('shoppinglists')
      .withConverter<ShoppingList>(
        fromFirestore: (snapshot, _) =>
            ShoppingList.fromMap(snapshot.id, snapshot.data()!),
        toFirestore: (model, _) => model.toMap(),
      );

  ShoppingListService._();

  static Future<ShoppingList> createShoppingListWithPlanId(
      String planId) async {
    _log.finer('Call createShoppingListWithPlanId with $planId');
    final list = ShoppingList(meals: [], planId: planId);

    final created = await _firestore.add(list);
    list.id = created.id;

    return list;
  }

  static Future<ShoppingList?> getShoppingListByPlanId(String planId) async {
    _log.finer('Call getShoppingListByPlanId with $planId');
    final snaps =
        await _firestore.where('planId', isEqualTo: planId).limit(1).get();

    return snaps.docs.isEmpty ? null : snaps.docs.first.data();
  }

  static Stream<List<Grocery>> streamShoppingList(String listId) {
    _log.finer('Call streamShoppingList with $listId');
    return _firestore
        .doc(listId)
        .collection('groceries')
        .orderBy('name')
        .snapshots()
        .map((event) =>
            event.docs.map((e) => Grocery.fromMap(e.id, e.data())).toList());
  }

  static Future<void> groceryToggleBought(String listId, Grocery grocery) {
    _log.finer(
        'Call groceryToggleBought with listId: $listId | Grocery: ${grocery.toMap()}');

    grocery.bought = !grocery.bought;
    grocery.lastBoughtEdited = DateTime.now();
    return _firestore
        .doc(listId)
        .collection('groceries')
        .doc(grocery.id)
        .update(grocery.toMap());
  }

  static Future<void> updateGrocery(
      String listId, Grocery grocery, String langCode) async {
    _log.finer(
        'Call updateGrocery with listId: $listId | Grocery: ${grocery.toMap()}');

    await LunixApiService.dio.put<void>(
      '${LunixApiService.apiEndpoint}/grocery',
      data: grocery.toJson(),
      queryParameters: <String, dynamic>{
        'shoppinglistId': listId,
        'language': langCode,
        'groceryId': grocery.id,
      },
    );
  }

  static Future<void> addGrocery(
      String listId, Grocery grocery, String langCode) async {
    _log.finer(
        'Call addGrocery with listId: $listId | Grocery: ${grocery.toMap()}');

    await LunixApiService.dio.post<void>(
      '${LunixApiService.apiEndpoint}/grocery',
      data: grocery.toJson(),
      queryParameters: <String, dynamic>{
        'shoppinglistId': listId,
        'language': langCode
      },
    );
  }

  static Future<void> addGroceries(
      String listId, List<Grocery> groceries, String langCode) async {
    _log.finer('Call addGrocery with listId: $listId');

    await LunixApiService.dio.post<void>(
      '${LunixApiService.apiEndpoint}/grocery',
      data: jsonEncode(groceries),
      queryParameters: <String, dynamic>{
        'shoppinglistId': listId,
        'language': langCode
      },
    );
  }

  static Future<void> deleteGrocery(String listId, String groceryId) {
    _log.finer(
        'Call deleteGrocery with listId: $listId | groceryId: $groceryId');
    return _firestore
        .doc(listId)
        .collection('groceries')
        .doc(groceryId)
        .delete();
  }

  static Future<void> deleteAllBoughtGrocery(String listId) async {
    _log.finer('Call deleteAllBoughtGrocery with $listId');
    final snaps = await _firestore
        .doc(listId)
        .collection('groceries')
        .where('bought', isEqualTo: true)
        .get();

    _log.finest(
        'deleteAllBoughtGrocery: Query results: ${snaps.docs.map((e) => e.id)}');

    await Future.wait(
      snaps.docs.map((e) => deleteGrocery(listId, e.id)).toList(),
    );
  }
}
