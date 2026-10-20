import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/utils/share_tip.dart';

void main() {
  test('manual dish shows the tip', () {
    expect(shareTipAfterSave(mealSource: 'manual', seen: false), ShareTip.show);
  });
  test('link from the add-dish sheet shows the tip', () {
    expect(shareTipAfterSave(mealSource: 'sheet_link', seen: false),
        ShareTip.show);
  });
  test('dish shared from another app marks the tip as seen', () {
    expect(shareTipAfterSave(mealSource: 'share_link', seen: false),
        ShareTip.markSeen);
  });
  test('tip shows only once', () {
    expect(shareTipAfterSave(mealSource: 'manual', seen: true), ShareTip.none);
  });
  test('tip names the platform app (Foodster on iOS, Foodly on Android)', () {
    for (final lang in ['en', 'de']) {
      final json =
          jsonDecode(File('assets/translations/$lang.json').readAsStringSync())
              as Map<String, dynamic>;
      final tip = json['share_tip'] as String;
      expect(tip, contains('{}'), reason: lang);
      expect(tip, isNot(contains('Foodster')), reason: lang);
    }
  });
}
