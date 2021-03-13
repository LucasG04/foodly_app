import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../models/meal.dart';
import '../utils/secrets.dart';

class MealService {
  static final log = Logger('MealService');

  static FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MealService._();

  static Future<List<Meal>> getMeals([int count = 10]) async {
    log.finer('Call getMeals with $count');
    final docs = await _firestore.collection('meals').limit(count).get();

    List<Meal> meals = [];
    for (var doc in docs.docs) {
      meals.add(Meal.fromMap(doc.id, doc.data()));
    }
    return meals;
  }

  static Future<Meal> getMealById(String mealId) async {
    log.finer('Call getMeals with $mealId');
    try {
      final doc = await _firestore.collection('meals').doc(mealId).get();

      return Meal.fromMap(doc.id, doc.data());
    } catch (e) {
      log.severe('ERR: getMeals with $mealId', e);
      return null;
    }
  }

  static Future<List<Meal>> getAllMeals(String planId) async {
    log.finer('Call getAllMeals with $planId');
    List<Meal> meals = [];
    try {
      final snapsInPlan = await _firestore
          .collection('meals')
          .where('planId', isEqualTo: planId)
          .get();

      final snapsPublic = await _firestore
          .collection('meals')
          .where('isPublic', isEqualTo: true)
          .get();

      var allSnaps = [...snapsInPlan.docs, ...snapsPublic.docs];
      allSnaps = [
        ...{...allSnaps}
      ];

      for (var snap in allSnaps) {
        meals.add(Meal.fromMap(snap.id, snap.data()));
      }
    } catch (e) {
      log.severe('ERR: getAllMeals with $planId', e);
    }

    return meals;
  }

  static Stream<List<Meal>> streamPlanMeals(String planId) {
    log.finer('Call streamPlanMeals with $planId');
    return _firestore
        .collection('meals')
        .where('planId', isEqualTo: planId)
        .snapshots()
        .map((event) =>
            event.docs.map((e) => Meal.fromMap(e.id, e.data())).toList());
  }

  static Stream<List<Meal>> streamPublicMeals() {
    log.finer('Call streamPublicMeals');
    return _firestore
        .collection('meals')
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .map((event) =>
            event.docs.map((e) => Meal.fromMap(e.id, e.data())).toList());
  }

  static Future<Meal> createMeal(Meal meal) async {
    log.finer('Call createMeal with ${meal.toMap()}');
    if (meal.imageUrl == null || meal.imageUrl.isEmpty) {
      try {
        meal.imageUrl = (await _getMealPhotos(meal.name))[0] ?? '';
        log.finest('createMeal: Generated image: ${meal.imageUrl}');
      } catch (e) {
        log.severe('ERR: _getMealPhotos in createMeal with ${meal.name}', e);
      }
    }

    try {
      final id = new DateTime.now().microsecondsSinceEpoch.toString();
      await _firestore.collection('meals').doc(id).set(meal.toMap());
      meal.id = id;

      return meal;
    } catch (e) {
      log.severe('ERR: createMeal with ${meal.toMap()}', e);
      return null;
    }
  }

  static Future<Meal> updateMeal(Meal meal) async {
    log.finer('Call updateMeal with ${meal.toMap()}');
    try {
      await _firestore.collection('meals').doc(meal.id).update(meal.toMap());
      return meal;
    } catch (e) {
      log.severe('ERR: updateMeal with ${meal.toMap()}', e);
      return null;
    }
  }

  static Future<void> addMeals(String planId, List<Meal> meals) async {
    log.finer(
        'Call addMeals with PlanId: $planId | Meals: ${meals.toString()}');
    try {
      meals.forEach((meal) => meal.planId = planId);
      await Future.wait(
        meals.map((meal) {
          final id = new DateTime.now().microsecondsSinceEpoch.toString();
          return _firestore.collection('meals').doc(id).set(meal.toMap());
        }),
      );
    } catch (e) {
      log.severe(
          'ERR: addMeals with PlanId: $planId | Meals: ${meals.toString()}', e);
    }
  }

  static Future<List<String>> _getMealPhotos(String mealName) async {
    List<String> urls = [];
    final response = await Dio().get(
      'https://pixabay.com/api/',
      queryParameters: {
        'key': secretPixabay,
        'q': mealName.toString() + ' food',
        'per_page': '3',
        'safesearch': 'true',
        'lang': 'de',
      },
    );

    if (response.data != null && response.data['totalHits'] != 0) {
      for (var item in response.data['hits']) {
        urls.add(item['webformatURL']);
      }
    }

    return urls;
  }
}
