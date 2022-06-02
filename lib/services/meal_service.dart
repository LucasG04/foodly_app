import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../models/meal.dart';
import '../utils/convert_util.dart';
import '../utils/secrets.dart';
import 'meal_stat_service.dart';

class MealService {
  static final _log = Logger('MealService');

  static final CollectionReference<Meal> _firestore =
      FirebaseFirestore.instance.collection('meals').withConverter<Meal>(
            fromFirestore: (snapshot, _) =>
                Meal.fromMap(snapshot.id, snapshot.data()!),
            toFirestore: (model, _) => model.toMap(),
          );

  MealService._();

  static Future<List<Meal>> getMealsByIds(List<String>? ids) async {
    _log.finer('Call getMealsByIds with $ids');
    if (ids == null || ids.isEmpty) {
      return [];
    }

    final List<DocumentSnapshot<Meal>> documents = [];

    for (final idList in ConvertUtil.splitArray(ids)) {
      if (idList.isNotEmpty) {
        final results =
            await _firestore.where(FieldPath.documentId, whereIn: idList).get();
        documents.addAll(results.docs);
      }
    }

    // remove non existing documents
    documents.removeWhere((e) => !e.exists);
    return documents.map((e) => e.data()!).toList();
  }

  static Future<Meal?> getMealById(String mealId) async {
    _log.finer('Call getMeals with $mealId');
    try {
      final doc = await _firestore.doc(mealId).get();

      return doc.exists ? doc.data() : null;
    } catch (e) {
      _log.severe('ERR: getMeals with $mealId', e);
      return null;
    }
  }

  static Future<List<Meal>> getAllMeals(String planId) async {
    _log.finer('Call getAllMeals with $planId');
    final List<Meal> meals = [];
    try {
      final snapsInPlan =
          await _firestore.where('planId', isEqualTo: planId).get();

      final snapsPublic =
          await _firestore.where('isPublic', isEqualTo: true).get();

      var allSnaps = [...snapsInPlan.docs, ...snapsPublic.docs];
      allSnaps = [
        ...{...allSnaps}
      ];

      for (final snap in allSnaps) {
        meals.add(snap.data());
      }
    } catch (e) {
      _log.severe('ERR: getAllMeals with $planId', e);
    }

    return meals;
  }

  static Future<Meal?> createMeal(Meal meal) async {
    _log.finer('Call createMeal with ${meal.toMap()}');
    if (meal.imageUrl == null || meal.imageUrl!.isEmpty) {
      try {
        meal.imageUrl = (await _getMealPhotos(meal.name))[0] ?? '';
        _log.finest('createMeal: Generated image: ${meal.imageUrl}');
      } catch (e) {
        _log.severe('ERR: _getMealPhotos in createMeal with ${meal.name}', e);
      }
    }

    try {
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      await _firestore.doc(id).set(meal);
      meal.id = id;
      await MealStatService.bumpStat(meal.planId!, meal.id!);

      return meal;
    } catch (e) {
      _log.severe('ERR: createMeal with ${meal.toMap()}', e);
      return null;
    }
  }

  static Future<Meal?> updateMeal(Meal meal) async {
    _log.finer('Call updateMeal with ${meal.toMap()}');
    try {
      await _firestore.doc(meal.id).update(meal.toMap());
      return meal;
    } catch (e) {
      _log.severe('ERR: updateMeal with ${meal.toMap()}', e);
      return null;
    }
  }

  static Future<void> deleteMeal(String mealId) async {
    _log.finer('Call deleteMeal with $mealId');
    try {
      await _firestore.doc(mealId).delete();
    } catch (e) {
      _log.severe('ERR: deleteMeal with $mealId', e);
    }
  }

  static Future<void> addMeals(String planId, List<Meal> meals) async {
    _log.finer(
        'Call addMeals with PlanId: $planId | Meals: ${meals.toString()}');
    try {
      for (final meal in meals) {
        meal.planId = planId;
      }
      await Future.wait(
        meals.map((meal) {
          final id = DateTime.now().microsecondsSinceEpoch.toString();
          return _firestore.doc(id).set(meal);
        }),
      );
    } catch (e) {
      _log.severe(
          'ERR: addMeals with PlanId: $planId | Meals: ${meals.toString()}', e);
    }
  }

  static Future<List<String?>> _getMealPhotos(String mealName) async {
    _log.finer('Call _getMealPhotos with $mealName');
    final List<String?> urls = [];
    final Response<dynamic> response = await Dio().get<dynamic>(
      'https://pixabay.com/api/',
      queryParameters: <String, dynamic>{
        'key': secretPixabay,
        'q': '$mealName food',
        'per_page': '3',
        'safesearch': 'true',
        'lang': 'de',
      },
    );

    final Map<String, dynamic> data = response.data as Map<String, dynamic>;
    if (response.data != null && data['totalHits'] != 0) {
      for (final item in data['hits']) {
        urls.add((item as Map<String, dynamic>)['webformatURL'] as String);
      }
    }

    return urls;
  }

  static Future<List<String>> getAllTags(String planId) async {
    _log.finer('Call getAllTags with $planId');
    final meals = await MealService.getAllMeals(planId);
    final tagsSeparated = meals.map((e) => e.tags);
    var tags = tagsSeparated.expand<String>((i) => i!).toList();
    tags = tags.toSet().toList();
    tags.sort((a, b) => a.compareTo(b));
    return tags;
  }

  static Future<List<Meal>> getMealsPaginated(String planId,
      {String? lastMealId, int amount = 30}) async {
    _log.finer('Call getMealsPaginated with $planId, $lastMealId, $amount');
    // Query<Meal> query;
    // if (lastMealId != null) {
    //   final startAfter = await _firestore.doc(lastMealId).get();
    //   query = _firestore
    //       .where('planId', isEqualTo: planId)
    //       .orderBy('name')
    //       .startAfterDocument(startAfter)
    //       .limit(amount);
    // } else {
    //   query = _firestore
    //       .where('planId', isEqualTo: planId)
    //       .orderBy('name')
    //       .limit(amount);
    // }

    // final snaps = await query.get();

    // return snaps.docs.map((e) => e.data()).toList();
    return MealService.getAllMeals(planId);
  }
}
