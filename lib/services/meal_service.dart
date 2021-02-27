import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

import '../models/meal.dart';
import '../utils/secrets.dart';

class MealService {
  MealService._();

  static FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<Meal>> getMeals([int count = 10]) async {
    final docs = await _firestore.collection('meals').limit(count).get();

    List<Meal> meals = [];
    for (var doc in docs.docs) {
      meals.add(Meal.fromMap(doc.id, doc.data()));
    }
    return meals;
  }

  static Future<Meal> getMealById(String mealId) async {
    try {
      final doc = await _firestore.collection('meals').doc(mealId).get();

      return Meal.fromMap(doc.id, doc.data());
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<List<Meal>> getAllMeals(String planId) async {
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
      print(e);
    }

    return meals;
  }

  static Stream<List<Meal>> streamPlanMeals(String planId) {
    return _firestore
        .collection('meals')
        .where('planId', isEqualTo: planId)
        .snapshots()
        .map((event) =>
            event.docs.map((e) => Meal.fromMap(e.id, e.data())).toList());
  }

  static Stream<List<Meal>> streamPublicMeals() {
    return _firestore
        .collection('meals')
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .map((event) =>
            event.docs.map((e) => Meal.fromMap(e.id, e.data())).toList());
  }

  static Future<Meal> createMeal(Meal meal) async {
    if (meal.imageUrl == null || meal.imageUrl.isEmpty) {
      try {
        meal.imageUrl = (await _getMealPhotos(meal.name))[0] ?? '';
      } catch (e) {
        print('Failed to create image:');
        print(e);
      }
    }

    try {
      final doc = await _firestore.collection('meals').add(meal.toMap());
      meal.id = doc.id;

      return meal;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<List<String>> _getMealPhotos(String mealName) async {
    List<String> urls = [];
    Dio dio = new Dio();
    final response = await dio.get(
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
