import 'package:flutter/material.dart';
import 'dart:io' show Platform;

/// General constants
final kAppName = Platform.isIOS ? 'Foodster' : 'Foodly';
const kPlaceholderSymbol = 'p--';
const kChefkochShareEndpoint = 'https://www.chefkoch.de/rezepte';

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

/// other
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
);
