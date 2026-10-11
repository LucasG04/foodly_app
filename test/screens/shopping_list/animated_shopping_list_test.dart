import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/models/grocery.dart';
import 'package:foodly/screens/tab_navigation/shopping_list_view/animated_shopping_list.dart';

import '../../helpers/test_localizations.dart';

void main() {
  const lasagne = GrocerySource(mealId: 'm1', mealName: 'Lasagne');
  const chili = GrocerySource(mealId: 'm2', mealName: 'Chili');

  Future<void> pump(WidgetTester tester, List<Grocery> groceries) =>
      tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: testLocalizationsDelegates,
          home: Scaffold(
            body: AnimatedShoppingList(
              groceries: groceries,
              onTap: (_) {},
              onEdit: (_) {},
              onLongPress: (_) {},
            ),
          ),
        ),
      );

  Grocery grocery({double? amount, List<GrocerySource> sources = const []}) =>
      Grocery(
        id: 'g1',
        name: 'Hackfleisch',
        amount: amount,
        unit: amount == null ? '' : 'g',
        sources: sources,
        lastBoughtEdited: DateTime(2026),
      );

  testWidgets('subtitle shows amount and meals', (tester) async {
    await pump(tester, [
      grocery(amount: 400, sources: [lasagne, chili])
    ]);
    expect(find.text('400 g · Lasagne, Chili'), findsOneWidget);
  });

  testWidgets('subtitle shows only meals when there is no amount',
      (tester) async {
    await pump(tester, [
      grocery(sources: [lasagne])
    ]);
    expect(find.text('Lasagne'), findsOneWidget);
  });

  testWidgets('manual items keep the amount-only subtitle', (tester) async {
    await pump(tester, [grocery(amount: 400)]);
    expect(find.text('400 g'), findsOneWidget);
  });

  testWidgets('tapped item is not re-inserted by an update before its write',
      (tester) async {
    Grocery item(String id) =>
        Grocery(id: id, name: 'Item $id', lastBoughtEdited: DateTime(2026));

    await pump(tester, [item('a'), item('b')]);
    await tester.tap(find.text('Item a'));
    await tester.pump(const Duration(milliseconds: 50));
    // Another item's write arrives while 'a' is still in the stream.
    await pump(tester, [item('a'), item('b')]);
    await tester.pumpAndSettle();

    expect(find.text('Item a'), findsNothing);
  });

  testWidgets('long meal lists stay on one line', (tester) async {
    await pump(tester, [
      grocery(amount: 400, sources: [lasagne, chili])
    ]);
    final subtitle = tester.widget<Text>(find.textContaining('Lasagne'));
    expect(subtitle.maxLines, 1);
    expect(subtitle.overflow, TextOverflow.ellipsis);
  });
}
