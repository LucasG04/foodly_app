import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
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

  static String? getUrlFromString(String input) {
    final RegExp exp =
        RegExp(r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
    final match = exp.firstMatch(input);
    return match != null ? input.substring(match.start, match.end) : null;
  }

  static bool isValidUri(String uri) {
    return Uri.tryParse(uri)?.isAbsolute ?? false;
  }

  static List<DateTime> getPlanDateTimes(int hourDiffToUtc, {int amount = 8}) {
    final now = DateTime.now().toUtc().add(Duration(hours: hourDiffToUtc));
    final today = DateTime(now.year, now.month, now.day);

    return List.generate(amount, (i) => today.add(Duration(days: i)));
  }

  static void emitMealsChanged(BuildContext context, [String id = '']) {
    context.read(lastChangedMealProvider).state = id;
  }

  static void afterBuild(void Function() callback) {
    return WidgetsBinding.instance.addPostFrameCallback((_) => callback());
  }

  /// Retuns the current language (e.g., "en").
  /// If the in-app language is not "en" it will be returned.
  /// If the in-app language is "en" the platform language will be retuned.
  ///
  /// Helps to improve the results of the image search.
  static String getActiveLanguage(BuildContext context) {
    return context.locale.languageCode == 'en'
        ? Platform.localeName.split('_')[0]
        : context.locale.languageCode;
  }
}
