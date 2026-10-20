import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/models/meal.dart';
import 'package:foodly/screens/meal_select/select_meal_tile.dart';
import 'package:foodly/widgets/card_list_tile.dart';

import '../../helpers/screen_size.dart';
import '../../helpers/test_localizations.dart';

void main() {
  testWidgets('large text: the tile grows instead of overflowing',
      (tester) async {
    setScreenSize(tester, const Size(402, 874), textScale: 2);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: testLocalizationsDelegates,
      home: Scaffold(
        body: SelectMealTile(
          meal: Meal(
            id: 'x',
            name: 'Ofenkartoffeln mit Kräuterquark und Gurkensalat',
            imageUrl: '',
          ),
          onAddMeal: () async => true,
          secondaryAction: () {},
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(
        tester.getSize(find.byType(CardListTile)).height, greaterThan(75 + 20));
  });

  testWidgets('normal text keeps the 75 pt tile', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: testLocalizationsDelegates,
      home: Scaffold(
        body: SelectMealTile(
          meal: Meal(id: 'x', name: 'Gulasch', imageUrl: ''),
          onAddMeal: () async => true,
        ),
      ),
    ));
    // 75 pt card plus its vertical margins.
    expect(tester.getSize(find.byType(CardListTile)).height, 75 + 20);
  });
}
