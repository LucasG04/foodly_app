import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/models/grocery.dart';

void main() {
  group('Grocery.sources', () {
    test('fromMap reads sources', () {
      final grocery = Grocery.fromMap('g1', <String, dynamic>{
        'name': 'Hackfleisch',
        'sources': [
          {'mealId': 'm1', 'mealName': 'Lasagne'},
        ],
      });
      expect(grocery.sources.single.mealId, 'm1');
      expect(grocery.sources.single.mealName, 'Lasagne');
    });

    test('fromMap defaults to empty when key is absent (backwards compat)', () {
      final grocery = Grocery.fromMap('g1', <String, dynamic>{'name': 'Milch'});
      expect(grocery.sources, isEmpty);
    });

    test('toMap writes sources', () {
      final grocery = Grocery(
        name: 'Hackfleisch',
        sources: const [GrocerySource(mealId: 'm1', mealName: 'Lasagne')],
        lastBoughtEdited: DateTime(2026),
      );
      expect(grocery.toMap()['sources'], [
        {'mealId': 'm1', 'mealName': 'Lasagne'},
      ]);
    });

    test('toMap writes empty sources', () {
      final grocery = Grocery(name: 'Milch', lastBoughtEdited: DateTime(2026));
      expect(grocery.toMap()['sources'], isEmpty);
    });

    test('fromMap skips malformed sources instead of throwing', () {
      final grocery = Grocery.fromMap('g1', <String, dynamic>{
        'name': 'Hackfleisch',
        'sources': [
          {'mealId': 'm1'},
          null,
          'x',
          {'mealId': 'm2', 'mealName': 'Chili'},
        ],
      });
      expect(grocery.sources.single.mealName, 'Chili');
      expect(Grocery.fromMap('g2', {'sources': 'x'}).sources, isEmpty);
    });
  });
}
