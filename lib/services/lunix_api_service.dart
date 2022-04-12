import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
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

  static const String _lunixApiEndpoint =
      'https://lunix-api.herokuapp.com/foodly';
  static final Dio _dio = Dio();

  static Future<String?> printDocxForPlan({
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
      final planDownloadPath = '${dir.path}/plan-$timestamp.pdf';
      await _dio.download(
        '$_lunixApiEndpoint/generate-plan-pdf',
        planDownloadPath,
        data: docxData,
        options: Options(
          headers: <String, dynamic>{'x-api-key': secretLunixApi},
        ),
        onReceiveProgress: (received, total) {
          final progress = (received / total) * 100;
          print('Rec: $received , Total: $total, $progress%');
        },
      );

      return planDownloadPath;
    } catch (e) {
      return null;
    }
  }

  static Future<LunixDocxPlan> _getLunixDocxPlan(
      Plan plan, String languageTag) async {
    final List<LunixDocxPlanDay> days = [];
    if (plan.meals != null) {
      final mealIds = plan.meals!.map((e) => e.meal).toList();
      final meals = await MealService.getMealsByIds(mealIds);
      // meals.addAll(_getPlaceholderMeals(mealIds));
      print(plan.meals);
      // print(meals);

      for (final meal in plan.meals!) {
        final dayName = DateFormat('EEEE', languageTag).format(meal.date);
        final dayIndex = days.indexWhere((m) => m.dayName == dayName);
        print(meal.id);
        print(dayName);
        if (dayIndex == -1) {
          if (meal.type == MealType.LUNCH) {
            days.add(LunixDocxPlanDay(
                dayName: dayName,
                lunch: meals.firstWhere((m) => m.id == meal.id).name));
          } else {
            days.add(LunixDocxPlanDay(
                dayName: dayName,
                dinner: meals.firstWhere((m) => m.id == meal.id).name));
          }
        } else {
          if (meal.type == MealType.LUNCH) {
            days[dayIndex].lunch =
                meals.firstWhere((m) => m.id == meal.id).name;
          } else {
            days[dayIndex].dinner =
                meals.firstWhere((m) => m.id == meal.id).name;
          }
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
