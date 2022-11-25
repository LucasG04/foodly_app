import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

import '../constants.dart';
import '../models/grocery.dart';
import '../models/grocery_group.dart';
import '../models/lunix_docx.dart';
import '../models/lunix_image.dart';
import '../models/meal.dart';
import '../models/plan.dart';
import '../models/plan_meal.dart';
import '../models/upcoming_feature.dart';
import '../utils/basic_utils.dart';
import '../utils/env.dart';
import 'meal_service.dart';

class LunixApiService {
  LunixApiService._();

  static final _log = Logger('LunixApiService');
  static const String _lunixApiEndpoint =
      'https://lunix-api.herokuapp.com/foodly';
  static final Dio _dio = Dio(
    BaseOptions(
      headers: <String, dynamic>{'x-api-key': Env.lunixApiKey},
    ),
  );

  static Future<bool> lunixApiAvailable() async {
    Response? response;
    try {
      response = await _dio.get<Map>(_lunixApiEndpoint);
    } catch (e) {
      _log.severe('ERR in lunixApiAvailable. Response is null', e);
    }
    return response != null && response.statusCode == 200;
  }

  static Future<String?> saveDocxForPlan({
    required Plan plan,
    required String languageTag,
    bool vertical = true,
    bool includeBreakfast = false,
    String type = 'color',
    bool excludeToday = false,
  }) async {
    _log.finer(
      'Call saveDocxForPlan with plan: ${plan.id}, langTag: $languageTag, vertical: $vertical, type: $type, includeBreakfast: $includeBreakfast, excludeToday: $excludeToday',
    );
    final docxPlan = await _getLunixDocxPlan(plan, languageTag, excludeToday);

    final docxData = LunixDocx(
      vertical: vertical,
      type: type,
      fillBreakfast: includeBreakfast,
      breakfastTranslation: 'breakfast'.tr(),
      lunchTranslation: 'lunch'.tr(),
      dinnerTranslation: 'dinner'.tr(),
      plan: docxPlan,
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final todayString = DateTime.now().toIso8601String().split('T')[0];
      final planSavePath = '${dir.path}/plan-$todayString.docx';
      final Response response = await _dio.post<List<int>>(
        '$_lunixApiEndpoint/generate-plan-pdf',
        data: docxData.toJson(),
        options: Options(responseType: ResponseType.bytes),
      );

      final File file = File(planSavePath);
      final randomAccessFile = file.openSync(mode: FileMode.write);
      randomAccessFile.writeFromSync(response.data as List<int>);
      await randomAccessFile.close();

      return planSavePath;
    } catch (e) {
      _log.severe('ERR in printDocxForPlan()', e);
      return null;
    }
  }

  static Future<LunixDocxPlan> _getLunixDocxPlan(
    Plan plan,
    String languageTag,
    bool excludeToday,
  ) async {
    if (plan.meals == null || plan.meals!.isEmpty) {
      return LunixDocxPlan(name: plan.name, meals: []);
    }

    List<DateTime> dates = BasicUtils.getPlanDateTimes(
      plan.hourDiffToUtc ?? 0,
      amount: excludeToday ? 9 : 8,
    );
    if (excludeToday) {
      dates = dates.sublist(1, dates.length);
    }

    final List<LunixDocxPlanDay> templateDays = [];
    List<String> mealIds = plan.meals!.map((e) => e.meal).toList();
    mealIds = mealIds.toSet().toList();
    final meals = await MealService.getMealsByIds(mealIds);
    meals.addAll(_getPlaceholderMeals(mealIds));

    for (var i = 0; i < dates.length; i++) {
      final date = dates[i];
      final dateMeals = plan.meals!
          .where((m) => m.date.difference(date).inDays == 0)
          .toList();
      final dayName = DateFormat('EEEE', languageTag).format(date);
      templateDays.add(LunixDocxPlanDay(dayName: dayName));
      final breakfastNames = <String>[];
      final lunchNames = <String>[];
      final dinnerNames = <String>[];
      for (final meal in dateMeals) {
        if (meal.type == MealType.LUNCH) {
          lunchNames.add(meals.firstWhere((m) => m.id == meal.meal).name);
        } else if (meal.type == MealType.DINNER) {
          dinnerNames.add(meals.firstWhere((m) => m.id == meal.meal).name);
        } else if (meal.type == MealType.BREAKFAST) {
          breakfastNames.add(meals.firstWhere((m) => m.id == meal.meal).name);
        }
      }
      templateDays[i].breakfast = breakfastNames.join(', ');
      templateDays[i].lunch = lunchNames.join(', ');
      templateDays[i].dinner = dinnerNames.join(', ');
    }

    return LunixDocxPlan(name: plan.name, meals: templateDays);
  }

  static List<Meal> _getPlaceholderMeals(List<String> ids) {
    return ids
        .where((m) => m.startsWith(kPlaceholderSymbol))
        .map((e) => Meal(id: e, name: e.replaceAll(kPlaceholderSymbol, '')))
        .toList();
  }

  static Future<LunixImageResponse?> searchImages(
    String text,
    int page,
    String langCode,
  ) async {
    _log.finer('Call searchImages() with $text, $page, $langCode');
    Response? response;
    try {
      response = await _dio.get<Map<String, dynamic>>(
        '$_lunixApiEndpoint/search-image',
        queryParameters: <String, dynamic>{
          'q': text,
          'page': page,
          'hl': langCode,
        },
      );
    } catch (e) {
      _log.severe('ERR in getAllPublishedVersions. Response is null', e);
    }

    if (response == null || response.data == null) {
      return null;
    }

    return LunixImageResponse.fromMap(response.data as Map<String, dynamic>);
  }

  static Future<List<String>> getAllPublishedVersions() async {
    _log.finer('Call getAllPublishedVersions()');
    Response? response;
    try {
      response = await _dio.get<List<dynamic>>(
        '$_lunixApiEndpoint/published-versions',
      );
    } catch (e) {
      _log.severe('ERR in getAllPublishedVersions. Response is null', e);
    }

    if (response == null || response.data == null) {
      return [];
    }

    final List<String> data = (response.data as List<dynamic>)
        .map((dynamic e) => e.toString())
        .toList();

    return response.data != null ? data : [];
  }

  static Future<List<Meal>> searchMeals(String planId, String query) async {
    _log.finer('Call searchMeals() with $planId and "$query"');
    Response? response;

    try {
      response = await _dio.get<List<dynamic>>(
        '$_lunixApiEndpoint/search-meals',
        queryParameters: <String, String>{
          'planId': planId,
          'query': query,
        },
      );
    } catch (e) {
      _log.severe('ERR in searchMeals. Response is null', e);
    }

    if (response == null || response.data == null) {
      return [];
    }

    final List<Meal> data = (response.data as List<dynamic>)
        .map(
          (dynamic e) =>
              // ignore: avoid_dynamic_calls
              Meal.fromMap(e['id'] as String, e as Map<String, dynamic>),
        )
        .toList();

    return data;
  }

  static Future<List<String>> getAllTagsInPlan(String planId) async {
    _log.finer('Call getAllTagsInPlan() for $planId');
    Response? response;
    try {
      response = await _dio.get<List<dynamic>>(
        '$_lunixApiEndpoint/tags-in-plan',
        queryParameters: <String, String>{'planId': planId},
      );
    } catch (e) {
      _log.severe('ERR in getAllTagsInPlan. Response is null', e);
    }

    if (response == null || response.data == null) {
      return [];
    }

    final List<String> data = (response.data as List<dynamic>)
        .map((dynamic e) => e.toString())
        .toList();

    return response.data != null ? data : [];
  }

  static Future<List<Meal>> searchMealsByTags(
    String planId,
    List<String> tags,
  ) async {
    _log.finer('Call searchMealByTags() with $planId and "$tags"');
    Response? response;
    try {
      response = await _dio.post<List<dynamic>>(
        '$_lunixApiEndpoint/search-meal-by-tags',
        data: <String, dynamic>{
          'planId': planId,
          'tags': tags,
        },
      );
    } catch (e) {
      _log.severe('ERR in searchMealsByTags. Response is null', e);
    }

    if (response == null || response.data == null) {
      return [];
    }

    final List<Meal> data = (response.data as List<dynamic>)
        .map((dynamic e) =>
            Meal.fromMap((e as Map<String, dynamic>)['id'] as String, e))
        .toList();

    return data;
  }

  static Future<List<GroceryGroup>> getGroceryGroups(String langCode) async {
    _log.finer('Call getGroceryGroups()');
    Response? response;
    try {
      response = await _dio.get<List<dynamic>>(
        '$_lunixApiEndpoint/grocery-groups',
        queryParameters: <String, dynamic>{'language': langCode},
      );
    } catch (e) {
      _log.severe('ERR in getGroceryGroups. Response is null', e);
    }
    if (response == null || response.data == null) {
      return [];
    }
    final data = (response.data as List<Map<String, dynamic>>)
        .map((Map<String, dynamic> e) => GroceryGroup.fromMap(e))
        .toList();
    return data;
  }

  static Future<List<Grocery>> getGrocerySuggestions(
      String query, String langCode, String planId) async {
    _log.finer('Call getGrocerySuggestions()');
    Response? response;
    try {
      response = await _dio.get<List<dynamic>>(
        '$_lunixApiEndpoint/get-grocery-suggestion',
        queryParameters: <String, dynamic>{
          'language': langCode,
          'query': query,
          'planId': planId,
        },
      );
    } catch (e) {
      _log.severe('ERR in getGrocerySuggestions. Response is null', e);
    }
    if (response == null || response.data == null) {
      return [];
    }
    final data = (response.data as List<dynamic>)
        .map(
            (dynamic e) => Grocery.fromApiSuggestion(e as Map<String, dynamic>))
        .toList();
    return data;
  }

  static Future<List<UpcomingFeature>> getUpcomingFeatures() async {
    _log.finer('Call getUpcomingFeatures()');
    Response? response;
    try {
      response = await _dio.get<List<dynamic>>(
        '$_lunixApiEndpoint/open-issues',
      );
    } catch (e) {
      _log.severe('ERR in getUpcomingFeatures. API Request failed', e);
    }
    if (response == null || response.data == null) {
      return [];
    }
    final data = (response.data as List<dynamic>)
        .map((dynamic e) => UpcomingFeature.fromMap(e as Map<String, dynamic>))
        .toList();
    return data;
  }
}
