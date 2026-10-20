import 'dart:convert';
import 'dart:io';

// Not exported; loading real translations lets tests read and measure the
// real copy.
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/widgets.dart';

/// Loads `assets/translations/[lang].json` into `Localization.instance`.
void loadTranslations(String lang) {
  final json = File('assets/translations/$lang.json').readAsStringSync();
  Localization.load(
    Locale(lang),
    translations: Translations(jsonDecode(json) as Map<String, dynamic>),
  );
}
