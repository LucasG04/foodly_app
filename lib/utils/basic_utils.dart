import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/state_providers.dart';

// ignore: avoid_classes_with_only_static_members
class BasicUtils {
  /// Clears all state providers.
  static void clearAllProvider(BuildContext context) {
    context.read(planProvider).state = null;
    context.read(userProvider).state = null;
  }

  /// Clears all state providers.
  static bool isStorageMealImage(String image) {
    try {
      final date = DateTime.fromMicrosecondsSinceEpoch(
          int.parse(image.split('.').first));
      return !Uri.tryParse(image)!.isAbsolute &&
          date.microsecondsSinceEpoch > 0;
    } catch (e) {
      return false;
    }
  }

  static double contentWidth(
    BuildContext context, {
    double smallMultiplier = 0.9,
  }) {
    return MediaQuery.of(context).size.width > 599
        ? 600.0
        : MediaQuery.of(context).size.width * smallMultiplier;
  }

  static String getUrlFromString(String input) {
    final RegExp exp =
        RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
    final match = exp.firstMatch(input)!;
    return input.substring(match.start, match.end);
  }

  static bool isValidUri(String uri) {
    return Uri.tryParse(uri)?.isAbsolute ?? false;
  }

  static List<DateTime> getPlanDateTimes(int hourDiffToUtc) {
    final now = DateTime.now().toUtc().add(Duration(hours: hourDiffToUtc));
    final today = DateTime(now.year, now.month, now.day);

    return List.generate(8, (i) => today.add(Duration(days: i)));
  }

  static void emitMealsChanged(BuildContext context) {
    context.read(mealsChangedProvider).state =
        DateTime.now().millisecondsSinceEpoch;
  }
}
