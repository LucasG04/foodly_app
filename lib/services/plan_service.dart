import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../constants.dart';
import '../models/plan.dart';
import '../models/plan_meal.dart';
import '../utils/convert_util.dart';
import 'authentication_service.dart';
import 'meal_stat_service.dart';
import 'shopping_list_service.dart';

class PlanService {
  static final log = Logger('PlanService');

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PlanService._();

  static Future<String?> getCurrentPlanId() async {
    log.finer(
        'Call getCurrentPlanId for User: ${AuthenticationService.currentUser}');
    if (AuthenticationService.currentUser == null) return '';

    final currentUserId = AuthenticationService.currentUser!.uid;
    final querySnaps = await _firestore
        .collection('plans')
        .where('users', arrayContains: currentUserId)
        .limit(1)
        .get();

    return querySnaps.docs.isEmpty ? null : querySnaps.docs.first.id;
  }

  static Future<Plan?> getPlanById(String? id) async {
    log.finer('Call getPlanById with $id');
    final doc = await _firestore.collection('plans').doc(id).get();

    return doc.exists ? Plan.fromMap(id, doc.data()!) : null;
  }

  static Future<List<Plan>> getPlansByIds(List<String?> ids) async {
    log.finer('Call getPlansByIds with ${ids.toString()}');
    final List<DocumentSnapshot> documents = [];

    for (final idList in ConvertUtil.splitArray(ids)) {
      final results = await _firestore
          .collection('plans')
          .where(FieldPath.documentId, whereIn: idList)
          .get();
      documents.addAll(results.docs);
    }

    documents.removeWhere((e) => !e.exists);
    return documents.map((e) => Plan.fromMap(e.id, e.data()!)).toList();
  }

  static Stream<Plan> streamPlanById(String id) {
    log.finer('Call streamPlanById with $id');
    return _firestore
        .collection('plans')
        .doc(id)
        .snapshots()
        .map((snap) => Plan.fromMap(snap.id, snap.data()!));
  }

  static Future<Plan> createPlan(String? name) async {
    log.finer('Call createPlan');
    String code = _generateCode().toString();
    while ((await getPlanById(code)) != null) {
      code = _generateCode().toString();
    }
    log.finest('createPlan: Generated code: $code');

    final now = DateTime.now();
    final plan = Plan(
      code: code,
      hourDiffToUtc: now.differenceTimeZoneOffset(now.toUtc()).inHours,
      name: name,
      users: [],
    );
    log.finest('createPlan: Plan is: ${plan.toMap()}');

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await _firestore.collection('plans').doc(id).set(plan.toMap());
    plan.id = id;

    await ShoppingListService.createShoppingListWithPlanId(id);

    return plan;
  }

  static int _generateCode() {
    const int min = 10000000;
    const int max = 99999999;
    final randomizer = Random();
    return min + randomizer.nextInt(max - min);
  }

  static Future<Plan?> getPlanByCode(String code,
      {bool withMeals = true}) async {
    log.finer('Call getPlanByCode with $code');
    final snaps = await _firestore
        .collection('plans')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (snaps.docs.isEmpty) return null;
    log.finest('getPlanByCode: Query result: ${snaps.docs.toString()}');

    final plan = Plan.fromMap(snaps.docs.first.id, snaps.docs.first.data());

    if (!withMeals) {
      final snapMeals = await _firestore
          .collection('plans')
          .doc(plan.id)
          .collection('meals')
          .get();

      log.finest(
          'getPlanByCode: Query meals result: ${snapMeals.docs.toString()}');

      plan.meals = snapMeals.docs
          .map((doc) => PlanMeal.fromMap(doc.id, doc.data()))
          .toList();
    }

    return plan;
  }

  static Future<void> updatePlan(Plan plan) {
    log.finer('Call updatePlan with ${plan.toMap()}');
    return _firestore.collection('plans').doc(plan.id).update(plan.toMap());
  }

  static Stream<List<PlanMeal>> streamPlanMealsByPlanId(String? id) {
    log.finer('Call streamPlanMealsByPlanId with $id');
    return _firestore
        .collection('plans')
        .doc(id)
        .collection('meals')
        .snapshots()
        .map((snap) =>
            snap.docs.map((e) => PlanMeal.fromMap(e.id, e.data())).toList());
  }

  static Future<void> addPlanMealToPlan(
      String planId, PlanMeal planMeal) async {
    log.finer(
        'Call addPlanMealToPlan with planId: $planId | planMeal: ${planMeal.toMap()}');
    if (!planMeal.meal.startsWith(kPlaceholderSymbol)) {
      await MealStatService.bumpStat(planId, planMeal.meal,
          bumpCount: true, bumpLastPlanned: true);
    }
    await _firestore
        .collection('plans')
        .doc(planId)
        .collection('meals')
        .add(planMeal.toMap());
  }

  static Future<void> updatePlanMealFromPlan(String? planId, PlanMeal meal) {
    log.finer(
        'Call updatePlanMealFromPlan with planId: $planId | planMeal: ${meal.toMap()}');
    return _firestore
        .collection('plans')
        .doc(planId)
        .collection('meals')
        .doc(meal.id)
        .set(meal.toMap(), SetOptions(merge: true));
  }

  static Future<void> deletePlanMealFromPlan(String? planId, String? mealId) {
    log.finer(
        'Call deletePlanMealFromPlan with planId: $planId | mealId: $mealId');
    return _firestore
        .collection('plans')
        .doc(planId)
        .collection('meals')
        .doc(mealId)
        .delete();
  }

  static Future<void> voteForPlanMeal(
      String? planId, PlanMeal planMeal, String userId) {
    log.finer(
        'Call voteForPlanMeal with planId: $planId | planMeal: ${planMeal.toMap()} | userId: $userId');
    if (planMeal.upvotes!.contains(userId)) {
      log.finest('voteForPlanMeal: upvotes contain userId.');
      planMeal.upvotes!.remove(userId);
    } else {
      log.finest('voteForPlanMeal: upvotes dont contain userId.');
      planMeal.upvotes!.add(userId);
    }

    return _firestore
        .collection('plans')
        .doc(planId)
        .collection('meals')
        .doc(planMeal.id)
        .update(planMeal.toMap());
  }

  static Future<void> leavePlan(String? planId, String userId) async {
    log.finer('Call leavePlan with planId: $planId | userId: $userId');
    final plan = await getPlanById(planId);

    if (plan != null && plan.users != null && plan.users!.contains(userId)) {
      plan.users!.remove(userId);
      _firestore
          .collection('plans')
          .doc(planId)
          .update(<String, List<String>>{'users': plan.users ?? []});
    }
  }
}

extension DateTimeExtensions on DateTime {
  Duration differenceTimeZoneOffset(DateTime other) {
    if (isUtc) {
      return difference(other);
    } else {
      return add(timeZoneOffset).difference(other);
    }
  }
}
