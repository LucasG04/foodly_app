import 'image_credit.dart';
import 'ingredient.dart';
import 'meal.dart';

/// Library language: German for a German app, English otherwise.
String libraryLang(String languageCode) => languageCode == 'de' ? 'de' : 'en';

/// The library's fixed tag set (lunix-api `scripts/library/tags.ts`).
enum LibraryTag {
  main('Hauptgericht', 'Main dish'),
  side('Beilage', 'Side dish'),
  soup('Suppe', 'Soup'),
  salad('Salat', 'Salad'),
  breakfast('Frühstück', 'Breakfast'),
  snack('Snack', 'Snack'),
  dessert('Dessert', 'Dessert'),
  baking('Backen', 'Baking'),
  drink('Getränk', 'Drink'),
  sauce('Sauce & Dip', 'Sauce & dip'),
  vegetarian('Vegetarisch', 'Vegetarian'),
  vegan('Vegan', 'Vegan'),
  meat('Fleisch', 'Meat'),
  fish('Fisch', 'Fish'),
  quick('Schnell', 'Quick'),
  german('Deutsch', 'German'),
  international('International', 'International');

  const LibraryTag(this.de, this.en);
  final String de;
  final String en;

  String label(String lang) => libraryLang(lang) == 'de' ? de : en;
}

/// Credit for a library recipe's text (e.g. Wikibooks, CC BY-SA 4.0). Shown
/// in the library only; not copied into the user's meal.
class RecipeCredit {
  final String source;
  final String link;
  final String license;

  const RecipeCredit({
    required this.source,
    required this.link,
    required this.license,
  });

  static RecipeCredit? tryParse(Object? value) {
    if (value is! Map) {
      return null;
    }
    final source = value['source'];
    final link = value['link'];
    final license = value['license'];
    if (source is! String || link is! String || license is! String) {
      return null;
    }
    return RecipeCredit(source: source, link: link, license: license);
  }
}

/// A dish from the meal library (lunix-api `/library`). List items carry the
/// summary; the detail adds ingredients, instructions and credits.
class LibraryMeal {
  final String id;
  final String name;
  final String imageUrl;
  final int duration;
  final int? kcal;
  final int servings;
  final List<String> tags;

  /// Id of the plan's copy, if the plan already has this dish.
  final String? importedMealId;

  final List<Ingredient>? ingredients;
  final String? instructions;
  final ImageCredit? imageCredit;
  final RecipeCredit? recipeCredit;
  final String? source;

  const LibraryMeal({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.duration,
    required this.servings,
    required this.tags,
    this.kcal,
    this.importedMealId,
    this.ingredients,
    this.instructions,
    this.imageCredit,
    this.recipeCredit,
    this.source,
  });

  bool get isImported => importedMealId != null;

  /// This dish after the plan copied it as [mealId].
  LibraryMeal withImported(String mealId) => LibraryMeal(
        id: id,
        name: name,
        imageUrl: imageUrl,
        duration: duration,
        servings: servings,
        tags: tags,
        kcal: kcal,
        importedMealId: mealId,
        ingredients: ingredients,
        instructions: instructions,
        imageCredit: imageCredit,
        recipeCredit: recipeCredit,
        source: source,
      );

  factory LibraryMeal.fromMap(Map<String, dynamic> map) {
    final ingredients = map['ingredients'] as List<dynamic>?;
    return LibraryMeal(
      id: map['id'] as String,
      name: map['name'] as String,
      imageUrl: (map['imageUrl'] as String?) ?? '',
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      kcal: (map['kcal'] as num?)?.toInt(),
      servings: (map['servings'] as num?)?.toInt() ?? 1,
      tags: List<String>.from((map['tags'] as List<dynamic>?) ?? <String>[]),
      importedMealId: map['importedMealId'] as String?,
      ingredients: ingredients
          ?.map((dynamic i) =>
              Ingredient.fromMap(Map<String, dynamic>.from(i as Map)))
          .toList(),
      instructions: map['instructions'] as String?,
      imageCredit: ImageCredit.tryParse(map['imageCredit']),
      recipeCredit: RecipeCredit.tryParse(map['recipeCredit']),
      source: map['source'] as String?,
    );
  }

  /// For widgets that show a [Meal]; never saved.
  Meal toPreviewMeal() => Meal(
        id: id,
        name: name,
        imageUrl: imageUrl,
        tags: tags,
        duration: duration,
        servings: servings,
        kcal: kcal,
        ingredients: ingredients,
        instructions: instructions,
        imageCredit: imageCredit,
        source: source,
      );
}

/// Result of a library import: the plan's meals for the requested dishes and
/// how many of them were copied now (the rest were already in the plan).
typedef LibraryImport = ({List<Meal> meals, int created});

/// A page of library search results.
class LibraryPage {
  final List<LibraryMeal> items;
  final int total;

  const LibraryPage(this.items, this.total);
}

/// Library search filter (lunix-api `POST /library/search`).
class LibraryFilter {
  /// All of these tags.
  final List<String> tags;

  /// At least one of these tags.
  final List<String> anyTags;

  /// None of these tags.
  final List<String> excludeTags;

  /// Name or ingredient.
  final String query;

  /// lunix-api rejects longer queries.
  static const maxQueryLength = 100;

  const LibraryFilter({
    this.tags = const [],
    this.anyTags = const [],
    this.excludeTags = const [],
    this.query = '',
  });

  bool get isEmpty =>
      tags.isEmpty &&
      anyTags.isEmpty &&
      excludeTags.isEmpty &&
      query.trim().isEmpty;

  LibraryFilter copyWith({
    List<String>? tags,
    List<String>? anyTags,
    List<String>? excludeTags,
    String? query,
  }) =>
      LibraryFilter(
        tags: tags ?? this.tags,
        anyTags: anyTags ?? this.anyTags,
        excludeTags: excludeTags ?? this.excludeTags,
        query: query ?? this.query,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        if (tags.isNotEmpty) 'tags': tags,
        if (anyTags.isNotEmpty) 'anyTags': anyTags,
        if (excludeTags.isNotEmpty) 'excludeTags': excludeTags,
        if (query.trim().isNotEmpty)
          'query': query.trim().length > maxQueryLength
              ? query.trim().substring(0, maxQueryLength)
              : query.trim(),
      };
}
