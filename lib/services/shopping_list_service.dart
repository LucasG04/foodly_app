import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../models/grocery.dart';
import '../models/shopping_list.dart';

class ShoppingListService {
  static final log = Logger('ShoppingListService');

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
    log.finer('Call createShoppingListWithPlanId with $planId');
    final list = ShoppingList(meals: [], planId: planId);

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await _firestore.doc(id).set(list);
    list.id = id;

    return list;
  }

  static Future<ShoppingList> getShoppingListByPlanId(String planId) async {
    log.finer('Call getShoppingListByPlanId with $planId');
    final snaps =
        await _firestore.where('planId', isEqualTo: planId).limit(1).get();

    return snaps.docs.first.data();
  }

  static Stream<List<Grocery>> streamShoppingList(String listId) {
    log.finer('Call streamShoppingList with $listId');
    return _firestore.doc(listId).collection('groceries').snapshots().map(
        (event) =>
            event.docs.map((e) => Grocery.fromMap(e.id, e.data())).toList());
  }

  static Future<void> updateGrocery(String listId, Grocery grocery) {
    log.finer(
        'Call updateGrocery with listId: $listId | Grocery: ${grocery.toMap()}');
    return _firestore
        .doc(listId)
        .collection('groceries')
        .doc(grocery.id)
        .update(grocery.toMap());
  }

  static Future<void> addGrocery(String listId, Grocery grocery) async {
    log.finer(
        'Call addGrocery with listId: $listId | Grocery: ${grocery.toMap()}');

    if (await _checkForDuplicateGrocery(listId, grocery)) {
      log.finest('addGrocery: adding prevented and existing one updated');
      return;
    }
    await _firestore.doc(listId).collection('groceries').add(grocery.toMap());
  }

  static Future<void> deleteGrocery(String listId, String groceryId) {
    log.finer(
        'Call deleteGrocery with listId: $listId | groceryId: $groceryId');
    return _firestore
        .doc(listId)
        .collection('groceries')
        .doc(groceryId)
        .delete();
  }

  static Future<void> deleteAllBoughtGrocery(String listId) async {
    log.finer('Call deleteAllBoughtGrocery with $listId');
    final snaps = await _firestore
        .doc(listId)
        .collection('groceries')
        .where('bought', isEqualTo: true)
        .get();

    log.finest(
        'deleteAllBoughtGrocery: Query results: ${snaps.docs.toString()}');

    await Future.wait(
        snaps.docs.map((e) => deleteGrocery(listId, e.id)).toList());
  }

  /// Checks current groceries for an already existing one.
  /// If one exists then no new one will be created, but the existing one will be updated.
  ///
  /// Returns `true` if one was updated, false otherwise.
  static Future<bool> _checkForDuplicateGrocery(
      String listId, Grocery grocery) async {
    final groceriesSnap = await _firestore
        .doc(listId)
        .collection('groceries')
        .where('name', isEqualTo: grocery.name)
        .where('unit', isEqualTo: grocery.unit)
        .where('productGroup', isEqualTo: grocery.productGroup)
        .where('bought', isEqualTo: false)
        .get();

    if (groceriesSnap.size > 0) {
      final existingGrocery = Grocery.fromMap(
          groceriesSnap.docs.first.id, groceriesSnap.docs.first.data());

      if (grocery.unit == null || grocery.unit!.isEmpty) {
        existingGrocery.amount =
            (existingGrocery.amount ?? 1) + (grocery.amount ?? 1);
      } else if (grocery.amount == null || existingGrocery.amount == null) {
        return false;
      } else {
        existingGrocery.amount = existingGrocery.amount! + grocery.amount!;
      }

      await updateGrocery(listId, existingGrocery);
      return true;
    }
    return false;
  }
}
