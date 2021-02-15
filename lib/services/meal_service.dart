import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:foodly/utils/secrets.dart';

import '../models/meal.dart';

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

  static Future<Meal> createMeal(Meal meal) async {
    if (meal.imageUrl == null || meal.imageUrl.isEmpty) {
      meal.imageUrl = (await _getMealPhotos(meal.name))[0] ?? '';
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
    Dio dio = new Dio();
    final response = await dio.get(
      'https://pixabay.com/api/',
      queryParameters: {
        'key': secretPixabay,
        'q': mealName.toString() + ' food',
        'per_page': '3',
        'safesearch': 'true',
      },
    );

    List<String> urls = [];

    if (response.data != null) {
      for (var item in response.data['hits']) {
        urls.add(item['webformatURL']);
      }
    }

    return urls;
  }
}
