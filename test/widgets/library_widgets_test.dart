import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/models/library_meal.dart';
import 'package:foodly/models/meal.dart';
import 'package:foodly/screens/library/library_intent_sheet.dart';
import 'package:foodly/screens/library/library_meal_tile.dart';
import 'package:foodly/screens/library/library_starter_sheet.dart';
import 'package:foodly/screens/meal_select/select_meal_tile.dart';

import '../helpers/test_localizations.dart';

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: testLocalizationsDelegates,
      home: Scaffold(body: child),
    );

const _dish = LibraryMeal(
  id: 'de-gulasch',
  name: 'Gulasch',
  imageUrl: '',
  duration: 90,
  servings: 4,
  tags: ['Hauptgericht'],
);

void main() {
  group('LibraryMealTile', () {
    testWidgets('toggles selection with the circle, opens with a tap',
        (tester) async {
      var toggled = 0;
      var opened = 0;
      await tester.pumpWidget(_app(LibraryMealTile(
        meal: _dish,
        selected: false,
        onTap: () => opened++,
        onToggle: () => toggled++,
      )));
      await tester.tap(find.byIcon(EvaIcons.radioButtonOffOutline));
      await tester.tap(find.text('Gulasch'));
      expect(toggled, 1);
      expect(opened, 1);
    });
  });

  testWidgets('starter sheet walks through 4 questions and pops the answers',
      (tester) async {
    StarterAnswers? result;
    await tester.pumpWidget(_app(Builder(
      builder: (context) => TextButton(
        onPressed: () async => result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const LibraryStarterSheet(),
        ),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('library_starter_diet_vegan'));
    await tester.tap(find.text('library_starter_next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Soup'));
    await tester.tap(find.text('library_starter_next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('library_starter_time_quick'));
    await tester.tap(find.text('library_starter_next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('library_starter_show'));
    await tester.pumpAndSettle();

    expect(result!.diet, StarterDiet.vegan);
    expect(result!.kinds, {LibraryTag.soup});
    expect(result!.quick, isTrue);
    expect(result!.cuisine, StarterCuisine.both);
  });

  testWidgets('intent sheet keeps the questionnaire filters it does not show',
      (tester) async {
    LibraryFilter? result;
    // MainTextField reads providers.
    await tester.pumpWidget(ProviderScope(
        child: _app(Builder(
      builder: (context) => TextButton(
        onPressed: () async => result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const LibraryIntentSheet(
            initial: LibraryFilter(
              anyTags: ['Soup', 'Salad'],
              excludeTags: ['Meat'],
            ),
          ),
        ),
        child: const Text('open'),
      ),
    ))));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Quick'));
    await tester.tap(find.text('Quick'));
    await tester.ensureVisible(find.text('library_show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('library_show'));
    await tester.pumpAndSettle();

    expect(result!.tags, ['Quick']);
    expect(result!.anyTags, ['Soup', 'Salad']);
    expect(result!.excludeTags, ['Meat']);
  });

  testWidgets('SelectMealTile stays open and resets when adding fails',
      (tester) async {
    await tester.pumpWidget(_app(SelectMealTile(
      meal: Meal(id: 'x', name: 'Gulasch', imageUrl: ''),
      onAddMeal: () async => false,
    )));
    await tester.tap(find.byIcon(EvaIcons.plus));
    await tester.pumpAndSettle();
    expect(find.byIcon(EvaIcons.plus), findsOneWidget);
    expect(find.byIcon(EvaIcons.checkmark), findsNothing);
  });
}
