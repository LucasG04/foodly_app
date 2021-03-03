import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodly/services/authentication_service.dart';
import 'shopping_list_service.dart';
import 'package:hive/hive.dart';

import '../models/plan.dart';
import '../models/plan_meal.dart';

class PlanService {
  PlanService._();

  static FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String> getCurrentPlanId() async {
    // return ProviderContainer().read(planProvider).state.id;
    final currentUserId = AuthenticationService.currentUser.uid;
    final querySnaps = await _firestore
        .collection('plans')
        .where('users', arrayContains: currentUserId)
        .limit(1)
        .get();

    return querySnaps.docs.first.id;
  }

  static Future<Plan> getPlanById(String id) async {
    final doc = await _firestore.collection('plans').doc(id).get();

    return Plan.fromMap(id, doc.data());
  }

  static Stream<Plan> streamPlanById(String id) {
    return _firestore
        .collection('plans')
        .doc(id)
        .snapshots()
        .map((snap) => Plan.fromMap(snap.id, snap.data()));
  }

  static Stream<List<PlanMeal>> streamPlanMealsByPlanId(String id) {
    return _firestore
        .collection('plans')
        .doc(id)
        .collection('meals')
        .snapshots()
        .map((snap) =>
            snap.docs.map((e) => PlanMeal.fromMap(e.id, e.data())).toList());
  }

  static Future<Plan> createPlan() async {
    String code = _generateCode().toString();
    while ((await getPlanById(code)) != null) {
      code = _generateCode().toString();
    }

    final now = DateTime.now();
    final plan = new Plan(
      code: code,
      hourDiffToUtc: now.differenceTimeZoneOffset(now.toUtc()).inHours,
      name: '',
      users: [],
    );

    final doc = await _firestore.collection('plans').add(plan.toMap());
    await ShoppingListService.createShoppingListWithPlanId(doc.id);

    return Plan.fromMap(doc.id, (await doc.get()).data());
  }

  static int _generateCode() {
    int min = 10000000;
    int max = 99999999;
    var randomizer = new Random();
    return min + randomizer.nextInt(max - min);
  }

  static Future<Plan> getPlanByCode(String code) async {
    final snaps = await _firestore
        .collection('plans')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (snaps.docs.isEmpty) return null;

    final plan = Plan.fromMap(snaps.docs.first.id, snaps.docs.first.data());

    final snapMeals = await _firestore
        .collection('plans')
        .doc(plan.id)
        .collection('meals')
        .get();
    plan.meals =
        snapMeals.docs.map((doc) => PlanMeal.fromMap(doc.id, doc.data()));

    return plan;
  }

  static Future<void> updatePlan(Plan plan) {
    return _firestore.collection('plans').doc(plan.id).update(plan.toMap());
  }

  static Future<void> addPlanMealToPlan(String planId, PlanMeal planMeal) {
    return _firestore
        .collection('plans')
        .doc(planId)
        .collection('meals')
        .add(planMeal.toMap());
  }

  static Future<void> updatePlanMealFromPlan(String planId, PlanMeal meal) {
    return _firestore
        .collection('plans')
        .doc(planId)
        .collection('meals')
        .doc(meal.id)
        .set(meal.toMap(), SetOptions(merge: true));
  }

  static Future<void> deletePlanMealFromPlan(String planId, String mealId) {
    return _firestore
        .collection('plans')
        .doc(planId)
        .collection('meals')
        .doc(mealId)
        .delete();
  }

  static Future<void> voteForPlanMeal(
      String planId, PlanMeal planMeal, String userId) {
    if (planMeal.upvotes.contains(userId)) return null;

    planMeal.upvotes.add(userId);
    return _firestore
        .collection('plans')
        .doc(planId)
        .collection('meals')
        .doc(planMeal.id)
        .update(planMeal.toMap());
  }

  static Future<void> leavePlan(String planId, String userId) async {
    final plan = await getPlanById(planId);

    if (plan.users.contains(userId)) {
      plan.users.remove(userId);
      _firestore.collection('plans').doc(planId).update({'users': plan.users});
    }
  }

  static Future<Box> _getFoodlyBox() async {
    return await Hive.boxExists('foodly')
        ? Hive.box('foodly')
        : await Hive.openBox('foodly');
  }
}

extension DateTimeExtensions on DateTime {
  Duration differenceTimeZoneOffset(DateTime other) {
    if (this.isUtc) {
      return this.difference(other);
    } else {
      return this.add(this.timeZoneOffset).difference(other);
    }
  }
}
