import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/models/grocery.dart';
import 'package:foodly/screens/tab_navigation/shopping_list_view/animated_shopping_list.dart';

import '../../helpers/test_localizations.dart';

void main() {
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

  Grocery grocery({double? amount}) => Grocery(
        id: 'g1',
        name: 'Hackfleisch',
        amount: amount,
        unit: amount == null ? '' : 'g',
        lastBoughtEdited: DateTime(2026),
      );

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
}
