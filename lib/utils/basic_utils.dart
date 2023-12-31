import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/foodly_user.dart';
import '../models/grocery_group.dart';
import '../providers/state_providers.dart';

// ignore: avoid_classes_with_only_static_members
class BasicUtils {
  /// Clears all state providers.
  static void clearAllProvider(WidgetRef ref) {
    ref.read(planProvider.notifier).state = null;
    ref.read(userProvider.notifier).state = null;
    ref.read(shoppingListIdProvider.notifier).state = null;
  }

  /// Returns if the given image url/string is a image from Firebase Storage
  static bool isStorageMealImage(String? image) {
    if (image == null || image.isEmpty) {
      return false;
    }
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

  static void emitMealsChanged(WidgetRef ref, [String id = '']) {
    ref.read(lastChangedMealProvider.notifier).state = id;
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

  static List<GroceryGroup> sortGroceryGroups(
    List<GroceryGroup> groups,
    List<String> sort,
  ) {
    final List<GroceryGroup> sorted = [];
    for (final id in sort) {
      final group = groups.firstWhere((element) => element.id == id);
      sorted.add(group);
    }
    final List<GroceryGroup> unSorted =
        groups.where((element) => !sort.contains(element.id)).toList();
    return [...sorted, ...unSorted];
  }

  static bool premiumGiftedActive(FoodlyUser user) {
    if (user.premiumGiftedAt == null ||
        user.premiumGiftedMonths == null ||
        user.premiumGiftedMonths == 0) {
      return false;
    }

    final giftedDateIsValid = user.premiumGiftedAt!.isAfter(
      DateTime.now().subtract(Duration(days: user.premiumGiftedMonths! * 30)),
    );
    return user.isPremiumGifted == true && giftedDateIsValid;
  }

  static TextCapitalization getTextCapitalizationByLanguage(
      BuildContext context) {
    final languageCode = context.locale.languageCode;
    if (languageCode == 'de') {
      return TextCapitalization.sentences;
    } else {
      return TextCapitalization.none;
    }
  }
}
