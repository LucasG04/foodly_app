import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/foodly_user.dart';
import '../models/plan.dart';

/// Provides the active plan object.
final planProvider = StateProvider<Plan?>((_) => null);

/// Provides the active foodly user object.
final userProvider = StateProvider<FoodlyUser?>((_) => null);

/// Provides if the top level stream is loading the user
final initialUserLoadingProvider = StateProvider<bool>((_) => true);

/// Provides if the top level stream is loading the plan
final initialPlanLoadingProvider = StateProvider<bool>((_) => true);

/// Provides the active shopping list id.
final shoppingListIdProvider = StateProvider<String?>((_) => null);

/// Provides the current filter for the meal list.
final mealTagFilterProvider = StateProvider<List<String>>((_) => []);

/// Provides the last locally changed meal id
final lastChangedMealProvider = StateProvider<String?>((_) => null);

/// Provides the current initial search for the WebImagePicker
final initSearchWebImagePickerProvider = StateProvider<String>((_) => '');

/// Provides the last time the page index of the pagehistory/home page
/// controller has been changed
final planHistoryPageChanged = StateProvider<int>((_) => 0);

/// controller has been changed
final hasConnectionProvider = StateProvider<bool>((_) => true);
