import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/foodly_user.dart';
import '../models/grocery_group.dart';
import '../models/social_platform.dart';
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
    return MediaQuery.sizeOf(context).width > 599
        ? 600.0
        : MediaQuery.sizeOf(context).width * smallMultiplier;
  }

  /// A link candidate: optional scheme, dotted host (letters incl. umlauts)
  /// ending in a 2+ letter TLD, optional port and path. Case-insensitive
  /// because keyboards capitalize "Https://".
  static final RegExp _linkExp = RegExp(
    r'(https?://)?(?:[\p{L}\p{N}_-]+\.)+\p{L}{2,}(?![\p{L}\p{N}_-])'
    r'(?::\d+)?(?:[/?#]\S*)?',
    caseSensitive: false,
    unicode: true,
  );

  /// Ends a sentence or wraps a link (incl. „…“ and »…«), not part of it.
  static const _trailingPunctuation = ').,;:!?\'"]}“”„«»‘’‚›‹';

  /// The first link in [input] as an `https://` URL, or null. Links with a
  /// scheme win over bare ones. A bare link needs `www.` or a lowercase host
  /// with a path: "chefkoch.de", "Spinat.Schnell" or "Oma.Style/vegetarisch"
  /// are more likely part of a sentence.
  static String? extractLink(String input) {
    final matches = _linkExp.allMatches(input).toList();
    for (final withScheme in [true, false]) {
      for (final match in matches) {
        final scheme = match.group(1);
        if ((scheme != null) != withScheme) {
          continue;
        }
        final rest = _trimTrailing(
          match.group(0)!.substring(scheme?.length ?? 0),
        );
        final host = rest.split(RegExp('[/?#:]')).first;
        final isWww = host.toLowerCase().startsWith('www.');
        if (scheme == null &&
            !isWww &&
            !(rest.contains('/') && host == host.toLowerCase())) {
          continue;
        }
        final url = 'https://$rest';
        if (Uri.tryParse(url)?.host.isNotEmpty == true) {
          return url;
        }
      }
    }
    return null;
  }

  /// Drops trailing punctuation; a closing bracket stays when it closes one
  /// inside the link (".../Lasagne_(Gericht)").
  static String _trimTrailing(String link) {
    var result = link;
    while (result.isNotEmpty &&
        _trailingPunctuation.contains(result[result.length - 1])) {
      final last = result[result.length - 1];
      if (last == ')' &&
          '('.allMatches(result).length >= ')'.allMatches(result).length) {
        break;
      }
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  static bool isValidUri(String uri) {
    final parsed = Uri.tryParse(uri);
    return parsed != null && parsed.isAbsolute && parsed.host.isNotEmpty;
  }

  static final Map<SocialPlatform, RegExp> _socialHostExps = {
    SocialPlatform.instagram: RegExp(
      r'^https?:\/\/(www\.)?instagram\.com',
      caseSensitive: false,
    ),
    SocialPlatform.tiktok: RegExp(
      r'^https?:\/\/((www|m|vm|vt)\.)?tiktok\.com(\/|$)',
      caseSensitive: false,
    ),
  };

  /// The platform when [url] is an Instagram or TikTok link to import; the
  /// server checks it is a post.
  static SocialPlatform? socialPlatformOf(String url) {
    final trimmed = url.trim();
    for (final MapEntry(:key, :value) in _socialHostExps.entries) {
      if (value.hasMatch(trimmed)) {
        return key;
      }
    }
    return null;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => callback());
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
    // Saved ids can be stale (group removed or groups not loaded), so skip them.
    final sorted = [for (final id in sort) ...groups.where((g) => g.id == id)];
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
