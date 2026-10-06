import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/screens/meal_create/meal_assistant_sheet.dart';

import '../../helpers/test_localizations.dart';

void main() {
  bool fieldHasFocus(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus;

  testWidgets('camera tap closes the keyboard and the menu does not refocus the field', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        home: Scaffold(body: MealAssistantSheet()),
      ),
    ));
    await tester.pump();
    expect(fieldHasFocus(tester), isTrue); // autofocus

    await tester.tap(find.byIcon(EvaIcons.cameraOutline));
    await tester.pumpAndSettle();
    expect(fieldHasFocus(tester), isFalse);
    expect(find.text('meal_assistant_image_gallery'), findsOneWidget); // menu open

    await tester.tapAt(Offset.zero); // dismiss the menu
    await tester.pumpAndSettle();
    expect(find.text('meal_assistant_image_gallery'), findsNothing);
    expect(fieldHasFocus(tester), isFalse);
  });
}
