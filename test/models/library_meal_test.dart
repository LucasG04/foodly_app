import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/models/library_meal.dart';
import 'package:foodly/models/meal.dart';

void main() {
  final detail = <String, dynamic>{
    'id': 'de-gulasch',
    'name': 'Gulasch',
    'imageUrl': 'https://img/gulasch.webp',
    'duration': 90,
    'kcal': 2400,
    'servings': 4,
    'tags': ['Hauptgericht', 'Fleisch'],
    'importedMealId': null,
    'ingredients': [
      {'name': 'Rindfleisch', 'amount': 1, 'unit': 'kg', 'group': null},
      {'name': 'Salz', 'amount': null, 'unit': null, 'group': null},
    ],
    'instructions': '1. Anbraten.',
    'imageCredit': {
      'source': 'wikimedia',
      'name': 'Someone',
      'link': 'https://commons/x'
    },
    'recipeCredit': {
      'source': 'wikibooks',
      'link': 'https://de.wikibooks.org/wiki/Kochbuch/_Gulasch',
      'license': 'CC BY-SA 4.0',
    },
    'source': 'https://de.wikibooks.org/wiki/Kochbuch/_Gulasch',
  };

  group('LibraryMeal.fromMap', () {
    test('reads a list item', () {
      final meal = LibraryMeal.fromMap(<String, dynamic>{
        'id': 'en-dal',
        'name': 'Dal',
        'imageUrl': '',
        'duration': 30,
        'kcal': null,
        'servings': 2,
        'tags': ['Vegan'],
        'importedMealId': 'm-1',
      });
      expect(meal.id, 'en-dal');
      expect(meal.kcal, isNull);
      expect(meal.isImported, isTrue);
      expect(meal.ingredients, isNull);
      expect(meal.recipeCredit, isNull);
    });

    test('reads a detail with ingredients and credits', () {
      final meal = LibraryMeal.fromMap(detail);
      expect(meal.isImported, isFalse);
      expect(meal.ingredients!.map((i) => i.name), ['Rindfleisch', 'Salz']);
      expect(meal.ingredients![0].amount, 1.0);
      expect(meal.imageCredit!.source, 'wikimedia');
      expect(meal.recipeCredit!.license, 'CC BY-SA 4.0');
      expect(meal.recipeCredit!.link, contains('wikibooks'));
    });
  });

  test('toPreviewMeal maps the fields a meal widget shows', () {
    final Meal preview = LibraryMeal.fromMap(detail).toPreviewMeal();
    expect(preview.id, 'de-gulasch');
    expect(preview.name, 'Gulasch');
    expect(preview.imageUrl, 'https://img/gulasch.webp');
    expect(preview.tags, ['Hauptgericht', 'Fleisch']);
    expect(preview.duration, 90);
    expect(preview.servings, 4);
    expect(preview.ingredients, hasLength(2));
  });

  group('LibraryFilter', () {
    test('toMap sends only set fields', () {
      expect(const LibraryFilter().toMap(), <String, dynamic>{});
      expect(
        const LibraryFilter(tags: ['Suppe'], query: ' Linsen ').toMap(),
        {
          'tags': ['Suppe'],
          'query': 'Linsen'
        },
      );
    });

    test('copyWith keeps the fields it does not set', () {
      const filter = LibraryFilter(
        tags: ['Suppe'],
        anyTags: ['Salat'],
        excludeTags: ['Fleisch'],
      );
      final changed = filter.copyWith(tags: [], query: 'Linsen');
      expect(changed.anyTags, ['Salat']);
      expect(changed.excludeTags, ['Fleisch']);
      expect(changed.tags, isEmpty);
      expect(changed.query, 'Linsen');
    });

    test('toMap caps the query at the API limit', () {
      final query = 'a' * (LibraryFilter.maxQueryLength + 20);
      expect(
        (LibraryFilter(query: query).toMap()['query'] as String).length,
        LibraryFilter.maxQueryLength,
      );
    });

    test('isEmpty ignores blank queries', () {
      expect(const LibraryFilter(query: '  ').isEmpty, isTrue);
      expect(const LibraryFilter(excludeTags: ['Fleisch']).isEmpty, isFalse);
    });
  });

  test('LibraryTag labels follow the language, English otherwise', () {
    expect(LibraryTag.vegetarian.label('de'), 'Vegetarisch');
    expect(LibraryTag.vegetarian.label('en'), 'Vegetarian');
    expect(LibraryTag.vegetarian.label('fr'), 'Vegetarian');
    // Mirrors scripts/library/tags.ts, including the rarer kinds.
    expect(LibraryTag.sauce.label('de'), 'Sauce & Dip');
    expect(LibraryTag.baking.label('en'), 'Baking');
    expect(libraryLang('de'), 'de');
    expect(libraryLang('fr'), 'en');
  });

  test('Meal keeps libraryId through toMap/fromMap', () {
    final map = Meal(name: 'Gulasch', libraryId: 'de-gulasch').toMap();
    expect(map['libraryId'], 'de-gulasch');
    expect(Meal.fromMap('m-1', map).libraryId, 'de-gulasch');
    expect(Meal(name: 'Own dish').toMap().containsKey('libraryId'), isFalse);
  });
}
