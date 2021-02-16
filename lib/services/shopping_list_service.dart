import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodly/models/shopping_list.dart';

class ShoppingListService {
  ShoppingListService._();

  static FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<ShoppingList> getShoppingListByPlanId(String planId) async {
    final snaps = await _firestore
        .collection('shoppinglists')
        .where('planId', isEqualTo: planId)
        .get();

    return ShoppingList.fromMap(snaps.docs.first.id, snaps.docs.first.data());
  }

  static Stream<ShoppingList> streamShoppingListByPlanId(String planId) {
    return _firestore
        .collection('shoppinglists')
        .where('planId', isEqualTo: planId)
        .snapshots()
        .map((snaps) =>
            ShoppingList.fromMap(snaps.docs.first.id, snaps.docs.first.data()));
  }
}
