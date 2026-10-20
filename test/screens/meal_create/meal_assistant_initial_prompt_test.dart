import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/screens/meal_create/meal_assistant_sheet.dart';

import '../../helpers/test_localizations.dart';

void main() {
  testWidgets('initial prompt prefills the field and sends it', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        home: Scaffold(body: MealAssistantSheet(initialPrompt: 'Lasagne')),
      ),
    ));
    // The send itself needs EasyLocalization and the API, neither of which
    // exists here; it fails after the sheet switched to sending.
    expect(tester.takeException(), isNotNull);
    await tester.pump();
    expect(find.text('meal_assistant_status_thinking'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Lasagne',
    );
    // Sent right away, so the keyboard must not pop up first.
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).autofocus,
      isFalse,
    );
  });
}
