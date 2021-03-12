import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/grocery.dart';
import '../models/shopping_list.dart';

class ShoppingListService {
  ShoppingListService._();

  static FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> createShoppingListWithPlanId(String planId) async {
    final list = new ShoppingList(meals: [], planId: planId);
    await _firestore.collection('shoppinglists').add(list.toMap());
  }

  static Future<ShoppingList> getShoppingListByPlanId(String planId) async {
    final snaps = await _firestore
        .collection('shoppinglists')
        .where('planId', isEqualTo: planId)
        .limit(1)
        .get();

    return ShoppingList.fromMap(snaps.docs.first.id, snaps.docs.first.data());
  }

  static Stream<List<Grocery>> streamShoppingList(String listId) {
    return _firestore
        .collection('shoppinglists')
        .doc(listId)
        .collection('groceries')
        .snapshots()
        .map((event) =>
            event.docs.map((e) => Grocery.fromMap(e.id, e.data())).toList());
  }

  static Future<void> updateGrocery(String listId, Grocery grocery) async {
    return _firestore
        .collection('shoppinglists')
        .doc(listId)
        .collection('groceries')
        .doc(grocery.id)
        .update(grocery.toMap());
  }

  static Future<void> addGrocery(String listId, Grocery grocery) async {
    return _firestore
        .collection('shoppinglists')
        .doc(listId)
        .collection('groceries')
        .add(grocery.toMap());
  }

  static Future<void> deleteGrocery(String listId, String groceryId) async {
    return _firestore
        .collection('shoppinglists')
        .doc(listId)
        .collection('groceries')
        .doc(groceryId)
        .delete();
  }

  static Future<void> deleteAllBoughtGrocery(String listId) async {
    final snaps = await _firestore
        .collection('shoppinglists')
        .doc(listId)
        .collection('groceries')
        .where('bought', isEqualTo: true)
        .get();

    return Future.wait(
        snaps.docs.map((e) => deleteGrocery(listId, e.id)).toList());
  }
}
