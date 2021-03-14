import 'package:dio/dio.dart';
import 'package:foodly/models/ingredient.dart';
import 'package:foodly/models/meal.dart';

class ChefkochService {
  ChefkochService._();

  static String _chefkochRecipeEndpoint = 'https://api.chefkoch.de/v2/recipes';
  static Dio _dio = new Dio();

  static Future<Meal> getMealFromChefkochUrl(String url) async {
    final recipeId = _extractRecipeIdFromChefkochUrl(url);
    final response = await _dio.get('$_chefkochRecipeEndpoint/$recipeId');

    if (response.data != null) {
      Meal meal = Meal();
      meal.name = response.data['title'];
      meal.source = 'Chefkoch';
      meal.instructions = response.data['instructions'].replaceAll('\n', ' ');
      // meal.tags = (response.data['tags'] as List<String>)
      //     .where((tag) => tag.isNotEmpty)
      //     .toList();
      meal.duration = response.data['totalTime'];
      meal.ingredients = _filterIngredientsFromChefkochIngredientGroups(
          response.data['ingredientGroups'][0]);
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
      Map<String, dynamic> ingredientGroups) {
    return List<Map<String, dynamic>>.from(ingredientGroups['ingredients'])
        .map((Map<String, dynamic> e) => Ingredient(
              name: e['name'],
              amount: e['amount'],
              unit: e['unit'],
              productGroup: e['productGroup'],
            ))
        .toList();
  }

  static Future<String> _getImageUrlByRecipeId(String recipeId) async {
    try {
      final imagesResponse =
          await _dio.get('$_chefkochRecipeEndpoint/$recipeId/images');

      final imageId = imagesResponse.data['results'][0]['id'];

      final imageResponse =
          await _dio.get('$_chefkochRecipeEndpoint/$recipeId/images/$imageId');

      return imageResponse.data['urls'].entries.first.value['cdn'];
    } catch (e) {
      return '';
    }
  }
}
