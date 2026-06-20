import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/models/meal.dart';

void main() {
  group('Meal.kcal', () {
    test('toMap includes kcal when set', () {
      final meal = Meal(name: 'Pasta', kcal: 600);
      expect(meal.toMap()['kcal'], 600);
    });

    test('toMap includes kcal as null when not set', () {
      final meal = Meal(name: 'Pasta');
      expect(meal.toMap()['kcal'], isNull);
    });

    test('fromMap reads kcal when present', () {
      final map = <String, dynamic>{
        'name': 'Pasta',
        'servings': 4,
        'ingredients': <dynamic>[],
        'tags': <dynamic>[],
        'imageUrl': '',
        'isPublic': false,
        'kcal': 800,
      };
      expect(Meal.fromMap(null, map).kcal, 800);
    });

    test('fromMap returns null kcal when key is absent (backwards compat)', () {
      final map = <String, dynamic>{
        'name': 'Pasta',
        'servings': 4,
        'ingredients': <dynamic>[],
        'tags': <dynamic>[],
        'imageUrl': '',
        'isPublic': false,
      };
      expect(Meal.fromMap(null, map).kcal, isNull);
    });

    test('fromMap returns null kcal when value is null', () {
      final map = <String, dynamic>{
        'name': 'Pasta',
        'servings': 4,
        'ingredients': <dynamic>[],
        'tags': <dynamic>[],
        'imageUrl': '',
        'isPublic': false,
        'kcal': null,
      };
      expect(Meal.fromMap(null, map).kcal, isNull);
    });

    test('round-trips kcal through toMap/fromMap', () {
      final original = Meal(name: 'Salad', servings: 2, kcal: 350);
      final copy = Meal.fromMap('id1', original.toMap());
      expect(copy.kcal, 350);
    });
  });
}
