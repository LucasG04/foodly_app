// ignore_for_file: avoid_dynamic_calls

import 'package:dio/dio.dart';

import '../models/ingredient.dart';
import '../models/meal.dart';

class ChefkochService {
  ChefkochService._();

  static const String _chefkochRecipeEndpoint =
      'https://api.chefkoch.de/v2/recipes';
  static final Dio _dio = Dio();

  static String get chefkochRecipeEndpoint => _chefkochRecipeEndpoint;

  static Future<Meal?> getMealFromChefkochUrl(String url) async {
    final recipeId = _extractRecipeIdFromChefkochUrl(url);
    late Response<dynamic> response;

    try {
      response = await _dio.get<Map>('$_chefkochRecipeEndpoint/$recipeId');
    } catch (e) {
      return null;
    }

    if (response.data != null) {
      final Meal meal = Meal(name: (response.data as Map)['title'] as String);
      meal.source = url;
      meal.instructions = (response.data as Map)['instructions'] as String;
      meal.tags = List<String>.from((response.data as Map)['tags'] as List)
          .where((tag) => tag.isNotEmpty)
          .toList();
      meal.tags = meal.tags!.toSet().toList(); // removes duplicates
      meal.duration = (response.data as Map)['totalTime'] as int?;
      meal.ingredients = _filterIngredientsFromChefkochIngredientGroups(
          List<Map<String, dynamic>>.from(
              (response.data as Map)['ingredientGroups'] as List));
      meal.imageUrl = await _getImageUrlByRecipeId(recipeId);

      return meal;
    }

    return null;
  }

  static String _extractRecipeIdFromChefkochUrl(String url) {
    const leadingUrl = 'https://www.chefkoch.de/rezepte/';

    return url.replaceFirst(leadingUrl, '').split('/')[0];
  }

  static List<Ingredient> _filterIngredientsFromChefkochIngredientGroups(
      List<Map<String, dynamic>> ingredientGroups) {
    return ingredientGroups
        .map((group) =>
            List<Map<String, dynamic>>.from(group['ingredients'] as List)
                .map((Map<String, dynamic> e) => Ingredient(
                      name: e['name'] as String? ?? '',
                      amount: e['amount'] as double? ?? 0,
                      unit: e['unit'] as String? ?? '',
                      productGroup: e['productGroup'] as String? ?? '',
                    ))
                .toList())
        .toList()
        .expand((i) => i)
        .toList();
  }

  static Future<String?> _getImageUrlByRecipeId(String recipeId) async {
    try {
      final imagesResponse =
          await _dio.get<Map>('$_chefkochRecipeEndpoint/$recipeId/images');

      final imageId = imagesResponse.data!['results'][0]['id'] as String;

      final imageResponse = await _dio
          .get<Map>('$_chefkochRecipeEndpoint/$recipeId/images/$imageId');

      return imageResponse.data!['urls'].entries.first.value['cdn'] as String;
    } catch (e) {
      return '';
    }
  }
}
