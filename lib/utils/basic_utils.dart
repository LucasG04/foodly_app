import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/state_providers.dart';

class BasicUtils {
  /// Clears all state providers.
  static void clearAllProvider(BuildContext context) {
    context.read(planProvider).state = null;
    context.read(userProvider).state = null;
    context.read(allMealsProvider).state = [];
  }
}
