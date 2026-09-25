import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/models/image_credit.dart';
import 'package:foodly/models/meal.dart';
import 'package:foodly/models/meal_generation_event.dart';

void main() {
  const creditMap = <String, dynamic>{
    'source': 'Pixabay',
    'name': 'Jane',
    'link': 'https://pixabay.com/p/1',
  };

  test('tryParse returns null for missing or incomplete credit', () {
    expect(ImageCredit.tryParse(null), isNull);
    expect(ImageCredit.tryParse('x'), isNull);
    expect(ImageCredit.tryParse(<String, dynamic>{'source': 'Pexels'}), isNull);
  });

  test('tryParse keeps null name', () {
    final credit = ImageCredit.tryParse(
      <String, dynamic>{'source': 'Pexels', 'name': null, 'link': 'https://x'},
    );
    expect(credit?.name, isNull);
    expect(credit?.source, 'Pexels');
  });

  test('Meal round-trips imageCredit and tolerates its absence', () {
    final meal = Meal.fromMap(null, <String, dynamic>{
      'name': 'Pasta',
      'imageCredit': creditMap,
    });
    expect(Meal.fromMap(null, meal.toMap()).imageCredit?.name, 'Jane');
    expect(Meal.fromMap(null, <String, dynamic>{'name': 'Pasta'}).imageCredit,
        isNull);
  });

  test('ImageEvent parses credit, defaults to null', () {
    final withCredit = MealGenerationEvent.fromJson(<String, dynamic>{
      'type': 'enrichment.image',
      'imageUrl': 'https://x/a.jpg',
      'imageCredit': creditMap,
    }) as ImageEvent;
    expect(withCredit.imageCredit?.source, 'Pixabay');

    final without = MealGenerationEvent.fromJson(<String, dynamic>{
      'type': 'enrichment.image',
      'imageUrl': 'https://x/a.jpg',
    }) as ImageEvent;
    expect(without.imageCredit, isNull);
  });
}
