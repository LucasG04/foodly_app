import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/models/meal_generation_event.dart';

void main() {
  group('MealGenerationEvent.fromJson', () {
    test('parses meal.field (string value)', () {
      final event = MealGenerationEvent.fromJson(<String, dynamic>{
        'type': 'meal.field',
        'field': 'name',
        'value': 'Spaghetti Carbonara',
      });
      expect(event, isA<MealFieldEvent>());
      final field = event as MealFieldEvent;
      expect(field.field, 'name');
      expect(field.value, 'Spaghetti Carbonara');
    });

    test('parses meal.field (numeric value)', () {
      final event = MealGenerationEvent.fromJson(<String, dynamic>{
        'type': 'meal.field',
        'field': 'servings',
        'value': 4,
      });
      final field = event as MealFieldEvent;
      expect(field.value, 4);
    });

    test('parses meal.ingredient into an Ingredient', () {
      final event = MealGenerationEvent.fromJson(<String, dynamic>{
        'type': 'meal.ingredient',
        'index': 2,
        'value': <String, dynamic>{
          'name': 'eggs',
          'amount': 3,
          'unit': '',
          'sortKey': 10,
        },
      });
      expect(event, isA<MealIngredientEvent>());
      final ing = event as MealIngredientEvent;
      expect(ing.index, 2);
      expect(ing.ingredient.name, 'eggs');
      expect(ing.ingredient.amount, 3.0);
      expect(ing.ingredient.sortKey, 10);
      // productGroup is not part of this event; arrives later via enrichment.
      expect(ing.ingredient.productGroup, isNull);
    });

    test('does not mutate the caller-provided ingredient map', () {
      final value = <String, dynamic>{'name': 'eggs', 'amount': 3};
      MealGenerationEvent.fromJson(<String, dynamic>{
        'type': 'meal.ingredient',
        'index': 0,
        'value': value,
      });
      // Ingredient.fromMap mutates its argument in place; we wrap in a copy so
      // the original stays intact.
      expect(value['amount'], 3);
    });

    test('parses phase', () {
      final event = MealGenerationEvent.fromJson(<String, dynamic>{
        'type': 'phase',
        'value': 'enriching',
      });
      expect(event, isA<PhaseEvent>());
      expect((event as PhaseEvent).value, 'enriching');
    });

    test('parses enrichment.productGroup', () {
      final event = MealGenerationEvent.fromJson(<String, dynamic>{
        'type': 'enrichment.productGroup',
        'index': 1,
        'productGroup': 'Dairy',
      });
      expect(event, isA<ProductGroupEvent>());
      final group = event as ProductGroupEvent;
      expect(group.index, 1);
      expect(group.productGroup, 'Dairy');
    });

    test('parses enrichment.group', () {
      final event = MealGenerationEvent.fromJson(<String, dynamic>{
        'type': 'enrichment.group',
        'index': 0,
        'group': 'Sauce',
      });
      expect(event, isA<GroupEvent>());
      final e = event as GroupEvent;
      expect(e.index, 0);
      expect(e.group, 'Sauce');
    });

    test('parses enrichment.image with url', () {
      final event = MealGenerationEvent.fromJson(<String, dynamic>{
        'type': 'enrichment.image',
        'imageUrl': 'https://example.com/a.jpg',
      });
      expect(event, isA<ImageEvent>());
      expect((event as ImageEvent).imageUrl, 'https://example.com/a.jpg');
    });

    test('parses enrichment.image with null url', () {
      final event = MealGenerationEvent.fromJson(<String, dynamic>{
        'type': 'enrichment.image',
        'imageUrl': null,
      });
      expect(event, isA<ImageEvent>());
      expect((event as ImageEvent).imageUrl, isNull);
    });

    test('parses done', () {
      final event = MealGenerationEvent.fromJson(<String, dynamic>{'type': 'done'});
      expect(event, isA<DoneEvent>());
    });

    test('parses error with a known code', () {
      final event = MealGenerationEvent.fromJson(<String, dynamic>{
        'type': 'error',
        'code': 'INSTAGRAM_FETCH_FAILED',
      });
      expect(event, isA<ErrorEvent>());
      expect(
        (event as ErrorEvent).code,
        MealGenerationErrorCode.instagramFetchFailed,
      );
    });

    test('maps an unrecognized error code to unknown', () {
      final event = MealGenerationEvent.fromJson(<String, dynamic>{
        'type': 'error',
        'code': 'SOME_CODE',
      });
      expect((event as ErrorEvent).code, MealGenerationErrorCode.unknown);
    });

    test('error defaults code to unknown when missing', () {
      final event =
          MealGenerationEvent.fromJson(<String, dynamic>{'type': 'error'});
      expect((event as ErrorEvent).code, MealGenerationErrorCode.unknown);
    });

    test('maps unknown type to MealGenerationUnknownEvent (forward compat)', () {
      final event = MealGenerationEvent.fromJson(<String, dynamic>{
        'type': 'something.new',
      });
      expect(event, isA<MealGenerationUnknownEvent>());
      expect((event as MealGenerationUnknownEvent).rawType, 'something.new');
    });
  });
}
