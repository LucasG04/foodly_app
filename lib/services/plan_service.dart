import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodly/services/authentication_service.dart';
import 'package:foodly/utils/convert_util.dart';
import 'package:logging/logging.dart';
import 'shopping_list_service.dart';
import 'package:hive/hive.dart';

import '../models/plan.dart';
import '../models/plan_meal.dart';

class PlanService {
  static final log = Logger('PlanService');

  static FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PlanService._();

  static Future<String> getCurrentPlanId() async {
    // return ProviderContainer().read(planProvider).state.id;
    log.finer(
        'Call getCurrentPlanId for User: ${AuthenticationService.currentUser}');
    if (AuthenticationService.currentUser == null) return '';

    final currentUserId = AuthenticationService.currentUser.uid;
    final querySnaps = await _firestore
        .collection('plans')
        .where('users', arrayContains: currentUserId)
        .limit(1)
        .get();

    return querySnaps.docs.first.id;
  }

  static Future<Plan> getPlanById(String id) async {
    log.finer('Call getPlanById with $id');
    final doc = await _firestore.collection('plans').doc(id).get();

    return Plan.fromMap(id, doc.data());
  }

  static Future<List<Plan>> getPlansByIds(List<String> ids) async {
    log.finer('Call getPlansByIds with ${ids.toString()}');
    final List<DocumentSnapshot> documents = [];

    for (var idList in ConvertUtil.splitArray(ids)) {
      final results = await _firestore
          .collection('plans')
          .where(FieldPath.documentId, whereIn: idList)
          .get();
      documents.addAll(results.docs);
    }

    return documents.map((e) => Plan.fromMap(e.id, e.data())).toList();
  }

  static Stream<Plan> streamPlanById(String id) {
    log.finer('Call streamPlanById with $id');
    return _firestore
        .collection('plans')
        .doc(id)
        .snapshots()
        .map((snap) => Plan.fromMap(snap.id, snap.data()));
  }

  static Future<Plan> createPlan() async {
    log.finer('Call createPlan');
    String code = _generateCode().toString();
    while ((await getPlanById(code)) != null) {
      code = _generateCode().toString();
    }
    log.finest('createPlan: Generated code: $code');

    final now = DateTime.now();
    final plan = new Plan(
      code: code,
      hourDiffToUtc: now.differenceTimeZoneOffset(now.toUtc()).inHours,
      name: '',
      users: [],
    );
    log.finest('createPlan: Plan is: ${plan.toMap()}');

    final id = new DateTime.now().microsecondsSinceEpoch.toString();
    await _firestore.collection('plans').doc(id).set(plan.toMap());
    plan.id = id;

    await ShoppingListService.createShoppingListWithPlanId(id);

    return plan;
  }

  static int _generateCode() {
    int min = 10000000;
    int max = 99999999;
    var randomizer = new Random();
    return min + randomizer.nextInt(max - min);
  }

  static Future<Plan> getPlanByCode(String code, {withMeals = true}) async {
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

  static Stream<List<PlanMeal>> streamPlanMealsByPlanId(String id) {
    log.finer('Call streamPlanMealsByPlanId with $id');
    return _firestore
        .collection('plans')
        .doc(id)
        .collection('meals')
        .snapshots()
        .map((snap) =>
            snap.docs.map((e) => PlanMeal.fromMap(e.id, e.data())).toList());
  }

  static Future<void> addPlanMealToPlan(String planId, PlanMeal planMeal) {
    log.finer(
        'Call addPlanMealToPlan with planId: $planId | planMeal: ${planMeal.toMap()}');
    return _firestore
        .collection('plans')
        .doc(planId)
        .collection('meals')
        .add(planMeal.toMap());
  }

  static Future<void> updatePlanMealFromPlan(String planId, PlanMeal meal) {
    log.finer(
        'Call updatePlanMealFromPlan with planId: $planId | planMeal: ${meal.toMap()}');
    return _firestore
        .collection('plans')
        .doc(planId)
        .collection('meals')
        .doc(meal.id)
        .set(meal.toMap(), SetOptions(merge: true));
  }

  static Future<void> deletePlanMealFromPlan(String planId, String mealId) {
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
      String planId, PlanMeal planMeal, String userId) {
    log.finer(
        'Call voteForPlanMeal with planId: $planId | planMeal: ${planMeal.toMap()} | userId: $userId');
    if (planMeal.upvotes.contains(userId)) {
      log.finest('voteForPlanMeal: upvotes contain userId.');
      planMeal.upvotes.remove(userId);
    } else {
      log.finest('voteForPlanMeal: upvotes dont contain userId.');
      planMeal.upvotes.add(userId);
    }

    return _firestore
        .collection('plans')
        .doc(planId)
        .collection('meals')
        .doc(planMeal.id)
        .update(planMeal.toMap());
  }

  static Future<void> leavePlan(String planId, String userId) async {
    log.finer('Call leavePlan with planId: $planId | userId: $userId');
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
