import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';

import '../constants.dart';
import '../models/plan.dart';
import '../models/plan_meal.dart';
import '../utils/convert_util.dart';
import 'app_review_service.dart';
import 'authentication_service.dart';
import 'meal_stat_service.dart';
import 'shopping_list_service.dart';

class PlanService {
  static final _log = Logger('PlanService');

  static final CollectionReference<Plan> _firestore =
      FirebaseFirestore.instance.collection('plans').withConverter<Plan>(
            fromFirestore: (snapshot, _) =>
                Plan.fromMap(snapshot.id, snapshot.data()!),
            toFirestore: (model, _) => model.toMap(),
          );

  static late Box _planBox;

  PlanService._();

  static Future initialize() async {
    _planBox = await Hive.openBox<dynamic>('plan');
  }

  static Future<String?> getCurrentPlanId() async {
    _log.finer(
        'Call getCurrentPlanId for User: ${AuthenticationService.currentUser}');
    if (AuthenticationService.currentUser == null) {
      _log.finer('getCurrentPlanId: currentUser is null');
      return null;
    }

    final currentUserId = AuthenticationService.currentUser!.uid;
    final querySnaps = await _firestore
        .where('users', arrayContains: currentUserId)
        .limit(1)
        .get();

    return querySnaps.docs.isEmpty ? null : querySnaps.docs.first.id;
  }

  static Future<Plan?> getPlanById(String? id) async {
    _log.finer('Call getPlanById with $id');
    if (id == null || id.isEmpty) {
      return null;
    }
    final doc = await _firestore.doc(id).get();

    return doc.exists && doc.data() != null ? doc.data() : null;
  }

  static Future<List<Plan>> getPlansByIds(List<String?> ids) async {
    _log.finer('Call getPlansByIds with $ids');
    if (ids.isEmpty) {
      return [];
    }
    final List<DocumentSnapshot<Plan>> documents = [];

    for (final idList in ConvertUtil.splitArray(ids)) {
      final results =
          await _firestore.where(FieldPath.documentId, whereIn: idList).get();
      documents.addAll(results.docs);
    }

    documents.removeWhere((e) => !e.exists);
    return documents.map((e) => e.data()!).toList();
  }

  static Stream<Plan> streamPlanById(String id) {
    _log.finer('Call streamPlanById with $id');
    return _firestore
        .doc(id)
        .snapshots()
        .where((e) => e.exists)
        .map((snap) => snap.data()!);
  }

  static Future<Plan> createPlan(String? name) async {
    _log.finer('Call createPlan');
    String code = generateCode();
    while ((await getPlanById(code)) != null) {
      code = generateCode();
    }
    _log.finest('createPlan: Generated code: $code');

    final now = DateTime.now();
    final plan = Plan(
      code: code,
      hourDiffToUtc: now.differenceTimeZoneOffset(now.toUtc()).inHours,
      name: name,
      users: [],
      lastUserJoined: DateTime.now(),
    );
    _log.finest('createPlan: Plan is: ${plan.toMap()}');

    final created = await _firestore.add(plan);
    plan.id = created.id;

    await ShoppingListService.createShoppingListWithPlanId(created.id);

    return plan;
  }

  static String generateCode() {
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    final Random rnd = Random();

    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  static Future<Plan?> getPlanByCode(String code,
      {bool withMeals = true}) async {
    _log.finer('Call getPlanByCode with $code');
    final snaps =
        await _firestore.where('code', isEqualTo: code).limit(1).get();

    if (snaps.docs.isEmpty) {
      return null;
    }
    _log.finest('getPlanByCode: Query result: ${snaps.docs}');

    final plan = snaps.docs.first.data();

    if (!withMeals) {
      final snapMeals = await _firestore.doc(plan.id).collection('meals').get();

      _log.finest('getPlanByCode: Query meals result: ${snapMeals.docs}');

      plan.meals = snapMeals.docs
          .map((doc) => PlanMeal.fromMap(doc.id, doc.data()))
          .toList();
    }

    return plan;
  }

  static Future<void> updatePlan(Plan plan) {
    _log.finer('Call updatePlan with ${plan.toMap()}');
    return _firestore.doc(plan.id).update(plan.toMap());
  }

  static Stream<List<PlanMeal>> streamPlanMealsByPlanId(String? id) {
    _log.finer('Call streamPlanMealsByPlanId with $id');
    return _firestore
        .doc(id)
        .collection('meals')
        .snapshots()
        .map((snap) => snap.docs
            .map(
              (e) => PlanMeal.fromMap(e.id, e.data()),
            )
            .toList());
  }

  static Future<List<PlanMeal>> getPlanMealHistoryByPlanId(String id) async {
    _log.finer('Call getPlanMealHistoryByPlanId with $id');
    final snaps = await _firestore.doc(id).collection('mealHistory').get();
    return snaps.docs
        .map(
          (snap) => PlanMeal.fromMap(snap.id, snap.data()),
        )
        .toList();
  }

  static Future<void> addPlanMealToPlan(
      String planId, PlanMeal planMeal) async {
    _log.finer(
        'Call addPlanMealToPlan with planId: $planId | planMeal: ${planMeal.toMap()}');
    if (!planMeal.meal.startsWith(kPlaceholderSymbol)) {
      await MealStatService.bumpStat(planId, planMeal.meal,
          bumpCount: true, bumpLastPlanned: true);
    }
    await _firestore.doc(planId).collection('meals').add(planMeal.toMap());
    AppReviewService.logPlanMeal();
  }

  static Future<void> updatePlanMealFromPlan(String? planId, PlanMeal meal) {
    _log.finer(
        'Call updatePlanMealFromPlan with planId: $planId | planMeal: ${meal.toMap()}');
    return _firestore
        .doc(planId)
        .collection('meals')
        .doc(meal.id)
        .set(meal.toMap(), SetOptions(merge: true));
  }

  static Future<void> deletePlanMealFromPlan(String? planId, String? mealId) {
    if (planId == null || mealId == null) {
      return Future.value();
    }
    _log.finer(
        'Call deletePlanMealFromPlan with planId: $planId | mealId: $mealId');
    return _firestore.doc(planId).collection('meals').doc(mealId).delete();
  }

  static Future<void> addPlanMealToPlanHistory(
      String planId, PlanMeal planMeal) async {
    _log.finer(
        'Call addPlanMealToPlanHistory with planId: $planId | planMeal: ${planMeal.toMap()}');
    final mealInHistory = await _firestore
        .doc(planId)
        .collection('mealHistory')
        .doc(planMeal.id)
        .get();

    if (mealInHistory.exists) {
      return;
    }

    await _firestore
        .doc(planId)
        .collection('mealHistory')
        .doc(planMeal.id)
        .set(planMeal.toMap());
  }

  static Future<void> updateHistoryPlanMealFromPlan(
      String? planId, PlanMeal meal) {
    _log.finer(
        'Call updateHistoryPlanMealFromPlan with planId: $planId | planMeal: ${meal.toMap()}');
    return _firestore
        .doc(planId)
        .collection('mealHistory')
        .doc(meal.id)
        .set(meal.toMap(), SetOptions(merge: true));
  }

  static Future<void> voteForPlanMeal(
      String? planId, PlanMeal planMeal, String userId) {
    _log.finer(
        'Call voteForPlanMeal with planId: $planId | planMeal: ${planMeal.toMap()} | userId: $userId');
    if (planMeal.upvotes!.contains(userId)) {
      _log.finest('voteForPlanMeal: upvotes contain userId.');
      planMeal.upvotes!.remove(userId);
    } else {
      _log.finest('voteForPlanMeal: upvotes dont contain userId.');
      planMeal.upvotes!.add(userId);
    }

    return _firestore
        .doc(planId)
        .collection('meals')
        .doc(planMeal.id)
        .update(planMeal.toMap());
  }

  static Future<void> leavePlan(String? planId, String userId) async {
    _log.finer('Call leavePlan with planId: $planId | userId: $userId');
    if (planId == null) {
      return;
    }
    final plan = await getPlanById(planId);

    if (plan == null || plan.users == null) {
      return;
    }

    if (plan.users!.length == 1 && plan.locked != null && plan.locked!) {
      plan.locked = false;
    }

    if (plan.users!.contains(userId)) {
      plan.users!.remove(userId);
      await _firestore.doc(planId).update(<String, Object>{
        'users': plan.users ?? <dynamic>[],
        'locked': plan.locked ?? false
      });
    }
  }

  static Future<void> lockPlan(String planId) async {
    _log.finer('Call lockPlan');
    final plan = await getPlanById(planId);
    if (plan == null) {
      return;
    }
    plan.locked = true;
    await updatePlan(plan);
  }

  static DateTime? lastLockedChecked() {
    _log.finer('Call lastLockedChecked');
    final milliseconds = _planBox.get('lastLockedCheck') as int?;
    return milliseconds != null
        ? DateTime.fromMillisecondsSinceEpoch(milliseconds)
        : null;
  }

  static Future<void> setLastLockedCheck() async {
    _log.finer('Call setLastLockedCheck');
    await _planBox.put(
        'lastLockedCheck', DateTime.now().millisecondsSinceEpoch);
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
