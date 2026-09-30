import 'dart:convert';
import 'dart:io';

// Not exported; loading translations directly avoids a widget tree.
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/services/rate_limit_exception.dart';

void _load(String lang) {
  final json = File('assets/translations/$lang.json').readAsStringSync();
  Localization.load(
    Locale(lang),
    translations: Translations(jsonDecode(json) as Map<String, dynamic>),
  );
}

String _message(int seconds) =>
    RateLimitException(retryAfterSeconds: seconds).message;

void main() {
  group('RateLimitException.message', () {
    test('en: minutes, hours, or both', () {
      _load('en');
      const prefix =
          "Whoa, you're quick! Please give me a breather and try again in";
      expect(_message(59), '$prefix 1 minute.');
      expect(_message(5 * 60), '$prefix 5 minutes.');
      expect(_message(3600), '$prefix 1 hour.');
      expect(_message(3601), '$prefix 1 hour and 1 minute.');
      expect(_message(2 * 3600 + 5 * 60), '$prefix 2 hours and 5 minutes.');
      expect(_message(2 * 3600), '$prefix 2 hours.');
    });

    test('de: dative singular forms', () {
      _load('de');
      String expected(String duration) =>
          'Wow, du bist ja schnell! Gib mir eine Pause und versuche es in '
          '$duration erneut.';
      expect(_message(59), expected('einer Minute'));
      expect(_message(5 * 60), expected('5 Minuten'));
      expect(_message(3600), expected('einer Stunde'));
      expect(_message(3601), expected('einer Stunde und einer Minute'));
      expect(_message(2 * 3600 + 5 * 60), expected('2 Stunden und 5 Minuten'));
    });
  });
}
