import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/widgets/ai_consent_sheet.dart';

import '../helpers/load_translations.dart';
import '../helpers/screen_size.dart';
import '../helpers/test_localizations.dart';

void main() {
  testWidgets('large text: the decision stays reachable', (tester) async {
    loadTranslations('de');
    setScreenSize(tester, const Size(402, 874), textScale: 2);

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: AiConsentSheet(),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);

    // Both answers are on screen without scrolling.
    for (final label in ['Erlauben', 'Nicht jetzt']) {
      final rect = tester.getRect(find.text(label));
      expect(rect.bottom, lessThanOrEqualTo(874), reason: label);
    }
  });
}
