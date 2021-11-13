import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodly/models/meal_stat.dart';
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

  static Future<List<MealStat>> getLeastPlanned(String planId,
      [int limit = 5]) async {
    log.finer('Call getLeastPlanned from $planId');
    final querySnapshot = await _firestore
        .collection('plans')
        .doc(planId)
        .collection('stats')
        .orderBy('plannedCount', descending: true)
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
        .orderBy('lastTimePlanned', descending: true)
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

  static Future<void> updateStat(
    String planId,
    String mealId,
    MealStat stat,
  ) async {
    log.finer('Call updateStat for plan $planId');
    try {
      final querySnapshot = await _firestore
          .collection('plans')
          .doc(planId)
          .collection('stats')
          .where('mealId', isEqualTo: mealId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        await _firestore
            .collection('plans')
            .doc(planId)
            .collection('stats')
            .add(stat.toMap());
      } else {
        final statId = querySnapshot.docs.first.id;
        await _firestore
            .collection('plans')
            .doc(planId)
            .collection('stats')
            .doc(statId)
            .update(stat.toMap());
      }
    } catch (e) {
      log.severe('ERR: updateStat for plan $planId with ${stat.toMap()}', e);
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
