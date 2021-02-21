import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'shopping_list_service.dart';
import 'package:hive/hive.dart';

import '../models/plan.dart';
import '../models/plan_meal.dart';

class PlanService {
  PlanService._();

  static FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String> getCurrentPlanId() async {
    // return (await _getFoodlyBox()).get('planId') ?? '';
    return 'UYxXSAWedTwgj3LygjaF';
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
      meals: [],
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

    return snaps.docs.isNotEmpty
        ? Plan.fromMap(snaps.docs.first.id, snaps.docs.first.data())
        : null;
  }

  static Future<void> updatePlan(Plan plan) async {
    _firestore.collection('plans').doc(plan.id).update(plan.toMap());
  }

  static Future<void> addPlanMealToPlan(
      String planId, PlanMeal planMeal) async {
    final plan = await getPlanById(planId);

    if (!plan.meals.contains(planMeal)) {
      plan.meals.add(planMeal);
      _firestore
          .collection('plans')
          .doc(planId)
          .update({'meals': plan.meals.map((e) => e.toMap()).toList()});
    }
  }

  static Future<void> deletePlanMealFromPlan(
      String planId, PlanMeal planMeal) async {
    final plan = await getPlanById(planId);

    if (plan.meals.contains(planMeal)) {
      plan.meals.remove(planMeal);
      _firestore
          .collection('plans')
          .doc(planId)
          .update({'meals': plan.meals.map((e) => e.toMap()).toList()});
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
