import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import 'models/shopping_list_sort.dart';

/// General constants
final kAppName = Platform.isIOS || Platform.isMacOS ? 'Foodster' : 'Foodly';
const kPlaceholderSymbol = 'p--';
const kChefkochShareEndpoint = 'https://www.chefkoch.de/rezepte';
const kAppDownloadUrl = 'https://golenia.dev';
final kAppPrivacyUrl = Platform.isIOS || Platform.isMacOS
    ? 'https://golenia.dev/privacy/foodster.html'
    : 'https://golenia.dev/privacy/foodly.html';
final kAppTermsOfUseUrl = Platform.isIOS || Platform.isMacOS
    ? 'https://golenia.dev/eula/foodster.html'
    : 'https://golenia.dev/eula/foodly.html';

/// Styling
const kPadding = 20.0;
const kRadius = 5.0;
const kIconHeight = 24.0; // default icon height in flutter

/// Theme
const kBackgroundColor = Color(0xFFFAFAFA);
const kPrimaryColor = Color(0xFF161616);
const kAccentColor = Color(0xFFF9A826);
const kSuccessColor = Color.fromRGBO(67, 222, 12, 0.4);
const kWarningColor = Color.fromRGBO(222, 12, 12, 0.4);

const kWhiteColor = Color.fromRGBO(255, 255, 255, 0.5);

const kHeadlineColor = Color(0xFF161616);
const kLightTextColor = Color(0xFF828282);
const kLightAccentColor = Color.fromRGBO(252, 163, 17, 0.4);
const kPremiumColor = Color.fromRGBO(251, 198, 61, 1);
const kGreyBackgroundColor = Color.fromRGBO(238, 238, 238, 1);

/// Other
/// The shadow for small elements in the app.
const kSmallShadow = BoxShadow(
  offset: Offset(0, 1),
  blurRadius: 12,
  color: Color.fromRGBO(0, 0, 0, .16),
);

/// Font types
const kCardTitle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
);

const kCardSubtitle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  color: kLightTextColor,
);

/// AppStore
const kAppBundleId = '1590739803';

/// If LogView should be available
const kLogViewEnabled = false;

// default ShoppingListSort
ShoppingListSort get defaultShoppingListSort => ShoppingListSort.name;
