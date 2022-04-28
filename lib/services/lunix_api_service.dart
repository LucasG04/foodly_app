import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

import '../constants.dart';
import '../models/lunix_docx.dart';
import '../models/meal.dart';
import '../models/plan.dart';
import '../models/plan_meal.dart';
import '../utils/secrets.dart';
import 'meal_service.dart';

class LunixApiService {
  LunixApiService._();

  static final log = Logger('LunixApiService');

  static const String _lunixApiEndpoint =
      'https://lunix-api.herokuapp.com/foodly';
  static final Dio _dio = Dio(
    BaseOptions(
      headers: <String, dynamic>{'x-api-key': secretLunixApi},
    ),
  );

  static Future<bool> lunixApiAvailable() async {
    final result = await _dio.get<Map>(_lunixApiEndpoint);
    return result.statusCode == 200;
  }

  static Future<String?> saveDocxForPlan({
    required Plan plan,
    bool vertical = true,
    bool colorful = true,
    required String languageTag,
  }) async {
    final docxData = LunixDocx(
      vertical: vertical,
      colorful: colorful,
      plan: await _getLunixDocxPlan(plan, languageTag),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final planSavePath = '${dir.path}/plan-$timestamp.docx';
      final Response response = await _dio.post<List<int>>(
        '$_lunixApiEndpoint/generate-plan-pdf',
        data: docxData.toJson(),
        options: Options(
          headers: <String, dynamic>{'x-api-key': secretLunixApi},
          responseType: ResponseType.bytes,
        ),
      );

      final File file = File(planSavePath);
      final randomAccessFile = file.openSync(mode: FileMode.write);
      randomAccessFile.writeFromSync(response.data as List<int>);
      await randomAccessFile.close();

      return planSavePath;
    } catch (e) {
      log.severe('ERR in printDocxForPlan()', e);
      return null;
    }
  }

  static Future<LunixDocxPlan> _getLunixDocxPlan(
      Plan plan, String languageTag) async {
    if (plan.meals == null || plan.meals!.isEmpty) {
      return LunixDocxPlan(name: plan.name, meals: []);
    }

    final List<LunixDocxPlanDay> days = [];
    final mealIds = plan.meals!.map((e) => e.meal).toList();
    final meals = await MealService.getMealsByIds(mealIds);
    meals.addAll(_getPlaceholderMeals(mealIds));

    for (final meal in plan.meals!) {
      final dayName = DateFormat('EEEE', languageTag).format(meal.date);
      final dayIndex = days.indexWhere((m) => m.dayName == dayName);
      if (dayIndex == -1) {
        if (meal.type == MealType.LUNCH) {
          days.add(LunixDocxPlanDay(
              dayName: dayName,
              lunch: meals.firstWhere((m) => m.id == meal.meal).name));
        } else {
          days.add(LunixDocxPlanDay(
              dayName: dayName,
              dinner: meals.firstWhere((m) => m.id == meal.meal).name));
        }
      } else {
        if (meal.type == MealType.LUNCH) {
          days[dayIndex].lunch =
              meals.firstWhere((m) => m.id == meal.meal).name;
        } else {
          days[dayIndex].dinner =
              meals.firstWhere((m) => m.id == meal.meal).name;
        }
      }
    }

    return LunixDocxPlan(name: plan.name, meals: days);
  }

  static List<Meal> _getPlaceholderMeals(List<String> ids) {
    return ids
        .where((m) => m.startsWith(kPlaceholderSymbol))
        .map((e) => Meal(id: e, name: e.replaceAll(kPlaceholderSymbol, '')))
        .toList();
  }
}