import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/services/settings_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory dir;

  setUpAll(() async {
    dir = Directory.systemTemp.createTempSync('settings_test');
    Hive.init(dir.path);
    await SettingsService.initialize();
  });

  tearDownAll(() async {
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  test('week goal is remembered per plan', () async {
    expect(SettingsService.weekGoalReached('plan-a'), isFalse);
    await SettingsService.setWeekGoalReached('plan-a');
    expect(SettingsService.weekGoalReached('plan-a'), isTrue);
    // A new plan on the same device starts without the goal reached.
    expect(SettingsService.weekGoalReached('plan-b'), isFalse);
  });
}
