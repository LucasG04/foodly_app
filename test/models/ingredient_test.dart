import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/models/ingredient.dart';

void main() {
  group('Ingredient.group', () {
    test('toMap includes group field', () {
      final ingredient = Ingredient(
        name: 'flour',
        amount: 200,
        unit: 'g',
        group: 'For the dough',
      );
      final map = ingredient.toMap();
      expect(map['group'], 'For the dough');
    });

    test('fromMap reads group field', () {
      final map = <String, dynamic>{
        'name': 'flour',
        'amount': 200.0,
        'unit': 'g',
        'productGroup': '',
        'group': 'For the dough',
      };
      final ingredient = Ingredient.fromMap(map);
      expect(ingredient.group, 'For the dough');
    });

    test('fromMap defaults group to null when key is absent (backwards compat)', () {
      final map = <String, dynamic>{
        'name': 'flour',
        'amount': 200.0,
        'unit': 'g',
        'productGroup': '',
        // 'group' key absent — old Firestore document
      };
      final ingredient = Ingredient.fromMap(map);
      expect(ingredient.group, isNull);
    });

    test('toMap round-trips through fromMap preserving group', () {
      final original = Ingredient(
        name: 'salt',
        amount: 1,
        unit: 'tsp',
        group: 'For the sauce',
      );
      final copy = Ingredient.fromMap(original.toMap());
      expect(copy.group, 'For the sauce');
    });

    test('toMap omits group key when group is null', () {
      final ingredient = Ingredient(name: 'salt', amount: 1, unit: 'tsp');
      expect(ingredient.toMap().containsKey('group'), isFalse);
    });
  });

  group('Ingredient.sortKey', () {
    test('toMap includes sortKey when set', () {
      final ingredient = Ingredient(name: 'flour', sortKey: 2);
      expect(ingredient.toMap()['sortKey'], 2);
    });

    test('toMap omits sortKey when null', () {
      final ingredient = Ingredient(name: 'flour');
      expect(ingredient.toMap().containsKey('sortKey'), isFalse);
    });

    test('fromMap reads sortKey', () {
      final map = <String, dynamic>{
        'name': 'flour',
        'amount': 100.0,
        'unit': 'g',
        'productGroup': '',
        'sortKey': 3,
      };
      expect(Ingredient.fromMap(map).sortKey, 3);
    });

    test('fromMap defaults sortKey to null when key absent (backwards compat)', () {
      final map = <String, dynamic>{
        'name': 'flour',
        'amount': 100.0,
        'unit': 'g',
        'productGroup': '',
      };
      expect(Ingredient.fromMap(map).sortKey, isNull);
    });

    test('round-trips sortKey through toMap/fromMap', () {
      final original = Ingredient(name: 'salt', sortKey: 5);
      final copy = Ingredient.fromMap(original.toMap());
      expect(copy.sortKey, 5);
    });

    test('toMap includes sortKey when value is 0', () {
      final ingredient = Ingredient(name: 'flour', sortKey: 0);
      expect(ingredient.toMap().containsKey('sortKey'), isTrue);
      expect(ingredient.toMap()['sortKey'], 0);
    });
  });

  group('Ingredient.orderedGroupsSorted', () {
    test('returns [null] when no ingredients', () {
      expect(Ingredient.orderedGroupsSorted([], null), [null]);
    });

    test('always puts null group first', () {
      final ingredients = [
        Ingredient(name: 'a', group: 'Sauce'),
        Ingredient(name: 'b', group: null),
      ];
      final groups = Ingredient.orderedGroupsSorted(ingredients, null);
      expect(groups.first, isNull);
    });

    test('respects explicit groupOrder', () {
      final ingredients = [
        Ingredient(name: 'a', group: 'Spices'),
        Ingredient(name: 'b', group: 'Sauce'),
      ];
      final groups =
          Ingredient.orderedGroupsSorted(ingredients, ['Sauce', 'Spices']);
      expect(groups, [null, 'Sauce', 'Spices']);
    });

    test('appends groups not in groupOrder in first-appearance order', () {
      final ingredients = [
        Ingredient(name: 'a', group: 'Extra'),
        Ingredient(name: 'b', group: 'Sauce'),
      ];
      final groups =
          Ingredient.orderedGroupsSorted(ingredients, ['Sauce']);
      expect(groups, [null, 'Sauce', 'Extra']);
    });

    test('falls back to first-appearance order when groupOrder is null', () {
      final ingredients = [
        Ingredient(name: 'a', group: 'B'),
        Ingredient(name: 'b', group: 'A'),
      ];
      final groups = Ingredient.orderedGroupsSorted(ingredients, null);
      expect(groups, [null, 'B', 'A']);
    });

    test('omits groups with no ingredients', () {
      final ingredients = [Ingredient(name: 'a', group: null)];
      final groups =
          Ingredient.orderedGroupsSorted(ingredients, ['Ghost']);
      // 'Ghost' is in groupOrder but no ingredient belongs to it
      expect(groups.contains('Ghost'), isFalse);
    });

    test('inserts null group first even when all ingredients have a named group', () {
      final ingredients = [
        Ingredient(name: 'a', group: 'Sauce'),
        Ingredient(name: 'b', group: 'Spices'),
      ];
      final groups = Ingredient.orderedGroupsSorted(ingredients, null);
      expect(groups.first, isNull);
      expect(groups.length, 3); // null, Sauce, Spices
    });
  });

  group('Ingredient.copyWith', () {
    test('copies all fields when no overrides given', () {
      final original = Ingredient(
          name: 'flour', amount: 200, unit: 'g', group: 'dough', sortKey: 1);
      final copy = original.copyWith();
      expect(copy.name, 'flour');
      expect(copy.amount, 200);
      expect(copy.unit, 'g');
      expect(copy.group, 'dough');
      expect(copy.sortKey, 1);
    });

    test('overrides only the specified field', () {
      final original = Ingredient(name: 'flour', sortKey: 1);
      final copy = original.copyWith(sortKey: 3);
      expect(copy.sortKey, 3);
      expect(copy.name, 'flour'); // unchanged
    });

    test('returns a new instance', () {
      final original = Ingredient(name: 'flour', sortKey: 1);
      final copy = original.copyWith(sortKey: 2);
      expect(identical(original, copy), isFalse);
    });

    test('copyWith(sortKey: 0) correctly sets sortKey to 0', () {
      final original = Ingredient(name: 'flour', sortKey: 5);
      final copy = original.copyWith(sortKey: 0);
      expect(copy.sortKey, 0);
    });
  });
}
