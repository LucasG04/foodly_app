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

  static Future<ShoppingList> getShoppingListByPlanId(String planId) async {
    _log.finer('Call getShoppingListByPlanId with $planId');
    final snaps =
        await _firestore.where('planId', isEqualTo: planId).limit(1).get();

    return snaps.docs.first.data();
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

  static Future<void> updateGrocery(String listId, Grocery grocery) {
    _log.finer(
        'Call updateGrocery with listId: $listId | Grocery: ${grocery.toMap()}');
    return _firestore
        .doc(listId)
        .collection('groceries')
        .doc(grocery.id)
        .update(grocery.toMap());
  }

  static Future<List<Grocery>> getGroceryGroups(
      List<Grocery> groceries, String langCode) async {
    _log.finer('Call getGroceryGroups with $groceries');
    final withChefkochGroup =
        groceries.where((e) => e.group != null && e.group!.length > 2).toList();
    final noGroup = groceries
        .where((e) =>
            ((e.group == null || e.group!.isEmpty) && e.name != null) &&
            !withChefkochGroup.contains(e))
        .toList();

    if (withChefkochGroup.isNotEmpty) {
      final groups = await LunixApiService.mapChefkochGroupsToGroupIds(
          withChefkochGroup.map((e) => e.group ?? '').toList());
      for (var i = 0; i < withChefkochGroup.length; i++) {
        withChefkochGroup[i].group = groups[i].id;
      }
    }

    if (noGroup.isNotEmpty) {
      final groups = await LunixApiService.getFirstGroceryGroupByQueries(
          noGroup.map((e) => e.group ?? '').toList(), langCode);
      for (var i = 0; i < noGroup.length; i++) {
        noGroup[i].group = groups[i]?.id ?? '';
      }
    }

    final groceriesWithGroup = groceries
        .where((element) =>
            !withChefkochGroup.contains(element) && !noGroup.contains(element))
        .toList();

    return [...withChefkochGroup, ...noGroup, ...groceriesWithGroup];
  }

  static Future<void> addGrocery(
      String listId, Grocery grocery, String langCode) async {
    _log.finer(
        'Call addGrocery with listId: $listId | Grocery: ${grocery.toMap()}');

    if (await _checkForDuplicateGrocery(listId, grocery)) {
      _log.finest('addGrocery: adding prevented and existing one updated');
      return;
    }
    if ((grocery.group == null || grocery.group!.isEmpty) &&
        grocery.name != null) {
      final groups = await LunixApiService.getFirstGroceryGroupByQueries(
        [grocery.name!],
        langCode,
      );
      if (groups.isNotEmpty) {
        grocery.group = groups.first?.id ?? '';
      }
    } else if (grocery.group != null && grocery.group!.length > 2) {
      final groups =
          await LunixApiService.mapChefkochGroupsToGroupIds([grocery.group!]);
      if (groups.isNotEmpty) {
        grocery.group = groups.first.id;
      }
    }
    await _firestore.doc(listId).collection('groceries').add(grocery.toMap());
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
    _log.finer('Call _checkForDuplicateGrocery with $listId, ${grocery.id}');
    final groceriesSnap = await _firestore
        .doc(listId)
        .collection('groceries')
        .where('name', isEqualTo: grocery.name)
        .where('unit', isEqualTo: grocery.unit)
        .where('group', isEqualTo: grocery.group)
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
