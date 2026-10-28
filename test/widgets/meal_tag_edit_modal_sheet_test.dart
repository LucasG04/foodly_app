import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/screens/meal_create/meal_tag_edit_modal.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../helpers/test_localizations.dart';

/// The modal inside a real bar sheet, as the meal create screen shows it.
void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showBarModalBottomSheet<void>(
              context: context,
              builder: (_) => MealTagEditModal(
                selectedContent: const [],
                allContent: [for (var i = 0; i < 80; i++) 'Tag $i'],
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  ScrollPosition cloudPosition(WidgetTester tester) => tester
      .state<ScrollableState>(find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ))
      .position;

  testWidgets('pulling the cloud down moves the sheet, not the cloud',
      (tester) async {
    await open(tester);

    final chip = find.byKey(const ValueKey('tag-Tag 10'));
    final before = tester.getTopLeft(chip).dy;
    final sheetTop = tester.getTopLeft(find.byType(MealTagEditModal)).dy;
    final gesture = await tester.startGesture(tester.getCenter(chip));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    final sheetMoved =
        tester.getTopLeft(find.byType(MealTagEditModal)).dy - sheetTop;
    final chipMoved = tester.getTopLeft(chip).dy - before;
    expect(sheetMoved, greaterThan(50));
    expect(chipMoved, closeTo(sheetMoved, 0.5)); // cloud rides with the sheet
    await gesture.up();
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('a new search starts its results at the top', (tester) async {
    await open(tester);
    await tester.drag(
        find.byKey(const ValueKey('tag-Tag 10')), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(cloudPosition(tester).pixels, greaterThan(0));

    await tester.enterText(find.byType(TextField), 'Tag');
    await tester.pumpAndSettle();

    expect(cloudPosition(tester).pixels, 0);
  });
}
