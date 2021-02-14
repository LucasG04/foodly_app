import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

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
      'https://contextualwebsearch-websearch-v1.p.rapidapi.com/api/Search/ImageSearchAPI',
      queryParameters: {
        'q': mealName.toString(),
        'pageNumber': '0',
        'pageSize': '5',
        'autoCorrect': 'false',
      },
      options: Options(headers: {
        'x-rapidapi-key': '352371f8c3msh956a7329ca16f9ap1c0f76jsn793ed5446e07',
        'x-rapidapi-host': 'contextualwebsearch-websearch-v1.p.rapidapi.com',
      }),
    );

    List<String> urls = [];

    if (response.data != null) {
      for (var item in response.data['value']) {
        urls.add(item['url']);
      }
    }

    return urls;
  }
}
