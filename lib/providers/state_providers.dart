import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/foodly_user.dart';
import '../models/meal.dart';
import '../models/plan.dart';

/// Provides the active plan object.
final planProvider = StateProvider<Plan?>((ref) => null);

/// Provides the active foodly user object.
final userProvider = StateProvider<FoodlyUser?>((ref) => null);

/// Provides the active plan object.
final allMealsProvider = StateProvider<List<Meal>>((ref) => []);

/// Provides the current filter for the meal list.
final mealTagFilterProvider = StateProvider<List<String>>((ref) => []);

/// Provides the current initial search for the WebImagePicker
final initSearchWebImagePickerProvider = StateProvider<String>((ref) => '');
