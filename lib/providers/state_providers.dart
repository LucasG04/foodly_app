import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../models/foodly_user.dart';
import '../models/meal.dart';
import '../models/plan.dart';

/// Provides the active plan object.
final planProvider = StateProvider<Plan?>((_) => null);

/// Provides the active foodly user object.
final userProvider = StateProvider<FoodlyUser?>((_) => null);

/// Provides all meals in plan
final allMealsProvider = StateProvider<List<Meal>>((_) => []);

/// Provides if the meals are still loading after the init
final initLoadingMealsProvider = StateProvider<bool>((_) => true);

/// Provides the current filter for the meal list.
final mealTagFilterProvider = StateProvider<List<String>>((_) => []);

/// Provides the current initial search for the WebImagePicker
final initSearchWebImagePickerProvider = StateProvider<String>((_) => '');

/// Logs for log view
final logsProvider = StateProvider<List<LogRecord>>((_) => []);
