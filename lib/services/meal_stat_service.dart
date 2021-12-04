import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodly/models/meal.dart';
import 'package:foodly/models/meal_stat.dart';
import 'package:foodly/services/meal_service.dart';
import 'package:logging/logging.dart';

class MealStatService {
  static final log = Logger('MealStatService');

  static FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MealStatService._();

  static Future<List<MealStat>> getStatsOfPlan(String planId) async {
    log.finer('Call getStatsOfPlan from $planId');
    final querySnapshot = await _firestore
        .collection('plans')
        .doc(planId)
        .collection('stats')
        .get();

    return querySnapshot.docs.map((e) => MealStat.fromMap(e.id, e.data()));
  }

  static Future<List<Meal>> getMealRecommendations(String planId) async {
    final stats = await Future.wait(
        [getLeastPlanned(planId), getLongestNotPlanned(planId)]);
    List<String> mealIds = stats != null && stats.isNotEmpty
        ? stats.expand((i) => i).map((i) => i.mealId).toList()
        : [];
    mealIds = [
      ...{...mealIds}
    ];

    final meals = await MealService.getMealsByIds(mealIds);

    return meals != null && meals.isNotEmpty
        ? meals.where((meal) => mealIds.contains(meal.id)).toList()
        : [];
  }

  static Future<List<MealStat>> getLeastPlanned(String planId,
      [int limit = 5]) async {
    log.finer('Call getLeastPlanned from $planId');
    final querySnapshot = await _firestore
        .collection('plans')
        .doc(planId)
        .collection('stats')
        .orderBy('plannedCount')
        .limit(limit)
        .get();

    return querySnapshot.docs
        .map((e) => MealStat.fromMap(e.id, e.data()))
        .toList();
  }

  static Future<List<MealStat>> getLongestNotPlanned(String planId,
      [int limit = 5]) async {
    log.finer('Call getLongestNotPlanned from $planId');
    final querySnapshot = await _firestore
        .collection('plans')
        .doc(planId)
        .collection('stats')
        .orderBy('lastTimePlanned')
        .limit(limit)
        .get();

    return querySnapshot.docs
        .map((e) => MealStat.fromMap(e.id, e.data()))
        .toList();
  }

  static Future<void> bumpStat(String planId, String mealId,
      {bool bumpCount, bool bumpLastPlanned}) async {
    log.finer('Call updateStat for plan $planId');
    try {
      final querySnapshot = await _firestore
          .collection('plans')
          .doc(planId)
          .collection('stats')
          .where('mealId', isEqualTo: mealId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        final stat = new MealStat(
            mealId: mealId, lastTimePlanned: DateTime.now(), plannedCount: 1);
        await _firestore
            .collection('plans')
            .doc(planId)
            .collection('stats')
            .add(stat.toMap());
      } else {
        final stat = MealStat.fromMap(
            querySnapshot.docs.first.id, querySnapshot.docs.first.data());
        if (bumpCount) {
          stat.plannedCount++;
        }
        if (bumpLastPlanned) {
          stat.lastTimePlanned = DateTime.now();
        }
        await _firestore
            .collection('plans')
            .doc(planId)
            .collection('stats')
            .doc(stat.id)
            .update(stat.toMap());
      }
    } catch (e) {
      log.severe('ERR: updateStat for plan $planId with $mealId', e);
      return null;
    }
  }

  static Future<void> deleteStatByMealId(String planId, String mealId) async {
    log.finer('Call deleteStatByMealId for plan $planId with meal $mealId');
    try {
      final querySnapshot = await _firestore
          .collection('plans')
          .doc(planId)
          .collection('stats')
          .where('mealId', isEqualTo: mealId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await deleteStat(planId, querySnapshot.docs.first.id);
      } else {
        log.finer(
            'ERR: deleteStatByMealId for plan $planId with meal $mealId. Could not find stat.');
      }
    } catch (e) {
      log.severe('ERR: deleteStatByMealId for plan $planId with $mealId', e);
      return null;
    }
  }

  static Future<void> deleteStat(String planId, String statId) async {
    log.finer('Call deleteStat for plan $planId with stat $statId');
    try {
      await _firestore
          .collection('plans')
          .doc(planId)
          .collection('stats')
          .doc(statId)
          .delete();
    } catch (e) {
      log.severe('ERR: deleteStat for plan $planId with $statId', e);
      return null;
    }
  }
}
