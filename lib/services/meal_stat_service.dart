import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../constants.dart';
import '../models/meal.dart';
import '../models/meal_stat.dart';
import 'meal_service.dart';

class MealStatService {
  static final _log = Logger('MealStatService');

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MealStatService._();

  static Future<List<MealStat>> getStatsOfPlan(String planId) async {
    _log.finer('Call getStatsOfPlan from $planId');
    final querySnapshot = await _firestore
        .collection('plans')
        .doc(planId)
        .collection('stats')
        .get();

    return querySnapshot.docs
        .map((e) => MealStat.fromMap(e.id, e.data()))
        .toList();
  }

  static Future<MealStat?> getStat(String planId, String mealId) async {
    _log.finer('Call getStatsOfPlan from $planId');
    final snap = await _firestore
        .collection('plans')
        .doc(planId)
        .collection('stats')
        .where('mealId', isEqualTo: mealId)
        .get();

    if (snap.docs.isEmpty || !snap.docs[0].exists) {
      return null;
    }

    return MealStat.fromMap(snap.docs[0].id, snap.docs[0].data());
  }

  static Future<List<Meal>> getMealRecommendations(String planId) async {
    _log.finer('Call getMealRecommendations for $planId');
    try {
      final stats = await Future.wait(
          [getLeastPlanned(planId), getLongestNotPlanned(planId)]);
      List<String> mealIds = stats.isNotEmpty
          ? stats.expand((i) => i).map((i) => i.mealId).toList()
          : [];
      mealIds = [
        ...{...mealIds}
      ];
      _log.finest('getMealRecommendations mealIds: $mealIds');

      final meals = await MealService.getMealsByIds(mealIds);

      return meals.isNotEmpty
          ? meals.where((meal) => mealIds.contains(meal.id)).toList()
          : [];
    } catch (e) {
      _log.severe('Failed getMealRecommendations for $planId', e);
      return [];
    }
  }

  static Future<List<MealStat>> getLeastPlanned(String? planId,
      [int limit = 5]) async {
    _log.finer('Call getLeastPlanned from $planId');
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
    _log.finer('Call getLongestNotPlanned from $planId');
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
      {bool bumpCount = true, bool? bumpLastPlanned}) async {
    _log.finer('Call bumpStat for plan $planId');
    if (planId.startsWith(kPlaceholderSymbol)) {
      _log.finer(
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
          mealId: mealId,
          lastTimePlanned: DateTime.now(),
          plannedCount: bumpCount ? 1 : 0,
        );
        await _firestore
            .collection('plans')
            .doc(planId)
            .collection('stats')
            .add(stat.toMap());
      } else {
        final stat = MealStat.fromMap(
            querySnapshot.docs.first.id, querySnapshot.docs.first.data());
        if (bumpCount) {
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
      _log.severe('ERR: updateStat for plan $planId with $mealId', e);
      return;
    }
  }

  static Future<void> deleteStatByMealId(String? planId, String? mealId) async {
    _log.finer('Call deleteStatByMealId for plan $planId with meal $mealId');
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
        _log.finer(
            'ERR: deleteStatByMealId for plan $planId with meal $mealId. Could not find stat.');
      }
    } catch (e) {
      _log.severe('ERR: deleteStatByMealId for plan $planId with $mealId', e);
      return;
    }
  }

  static Future<void> deleteStat(String? planId, String statId) async {
    _log.finer('Call deleteStat for plan $planId with stat $statId');
    try {
      await _firestore
          .collection('plans')
          .doc(planId)
          .collection('stats')
          .doc(statId)
          .delete();
    } catch (e) {
      _log.severe('ERR: deleteStat for plan $planId with $statId', e);
      return;
    }
  }
}
