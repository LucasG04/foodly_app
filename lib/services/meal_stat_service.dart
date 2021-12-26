import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../constants.dart';
import '../models/meal.dart';
import '../models/meal_stat.dart';
import 'meal_service.dart';

class MealStatService {
  static final log = Logger('MealStatService');

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MealStatService._();

  static Future<List<MealStat>> getStatsOfPlan(String planId) async {
    log.finer('Call getStatsOfPlan from $planId');
    final querySnapshot = await _firestore
        .collection('plans')
        .doc(planId)
        .collection('stats')
        .get();

    return querySnapshot.docs
        .map((e) => MealStat.fromMap(e.id, e.data()))
        .toList();
  }

  static Future<List<Meal>> getMealRecommendations(String planId) async {
    log.finer('Call getMealRecommendations for $planId');
    try {
      final stats = await Future.wait(
          [getLeastPlanned(planId), getLongestNotPlanned(planId)]);
      List<String> mealIds = stats.isNotEmpty
          ? stats.expand((i) => i).map((i) => i.mealId).toList()
          : [];
      mealIds = [
        ...{...mealIds}
      ];
      log.finest('getMealRecommendations mealIds: $mealIds');

      final meals = await MealService.getMealsByIds(mealIds);

      return meals.isNotEmpty
          ? meals.where((meal) => mealIds.contains(meal.id)).toList()
          : [];
    } catch (e) {
      log.severe('Failed getMealRecommendations for $planId', e);
      return [];
    }
  }

  static Future<List<MealStat>> getLeastPlanned(String? planId,
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

  static Future<List<MealStat>> getLongestNotPlanned(String? planId,
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
      {bool? bumpCount, bool? bumpLastPlanned}) async {
    log.finer('Call bumpStat for plan $planId');
    if (planId.startsWith(kPlaceholderSymbol)) {
      log.finer(
          'bumpStat for plan $planId tried with placeholder: $mealId. Abort bump.');
      return;
    }
    try {
      final querySnapshot = await _firestore
          .collection('plans')
          .doc(planId)
          .collection('stats')
          .where('mealId', isEqualTo: mealId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        final stat = MealStat(
            mealId: mealId, lastTimePlanned: DateTime.now(), plannedCount: 1);
        await _firestore
            .collection('plans')
            .doc(planId)
            .collection('stats')
            .add(stat.toMap());
      } else {
        final stat = MealStat.fromMap(
            querySnapshot.docs.first.id, querySnapshot.docs.first.data());
        if (bumpCount!) {
          stat.plannedCount = (stat.plannedCount ?? 0) + 1;
        }
        if (bumpLastPlanned!) {
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
      return;
    }
  }

  static Future<void> deleteStatByMealId(String? planId, String? mealId) async {
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
      return;
    }
  }

  static Future<void> deleteStat(String? planId, String statId) async {
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
      return;
    }
  }
}
