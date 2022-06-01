import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../models/foodly_user.dart';
import '../models/plan.dart';

/// Provides the active plan object.
final planProvider = StateProvider<Plan?>((_) => null);

/// Provides the active foodly user object.
final userProvider = StateProvider<FoodlyUser?>((_) => null);

/// Provides the current filter for the meal list.
final mealTagFilterProvider = StateProvider<List<String>>((_) => []);

/// Provides the current initial search for the WebImagePicker
final initSearchWebImagePickerProvider = StateProvider<String>((_) => '');

/// Logs for log view
final logsProvider = StateProvider<List<LogRecord>>((_) => []);
