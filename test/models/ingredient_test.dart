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
}
