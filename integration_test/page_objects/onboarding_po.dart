import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/screens/onboarding/onboarding_keys.dart';

class OnboardingPo {
  const OnboardingPo(this.tester);

  final WidgetTester tester;

  Future<void> skipOnboarding() async {
    final button = find.byKey(OnboardingKeys.buttonNext);
    await tester.ensureVisible(button);
    await tester.press(button);
    for (var i = 0; i < 5; i++) {
      await tester.tap(button);
      sleep(const Duration(seconds: 2));
      // print('tap and sleep');
    }
  }
}
