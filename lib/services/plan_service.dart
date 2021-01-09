import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodly/models/plan.dart';
import 'package:foodly/models/plan_meal.dart';
import 'package:hive/hive.dart';

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
