import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/models/library_meal.dart';
import 'package:foodly/screens/library/library_starter_sheet.dart';

void main() {
  test('default answers filter nothing', () {
    expect(const StarterAnswers().toFilter('de').isEmpty, isTrue);
  });

  test('answers map to tags (AND), kinds (OR) and exclusions', () {
    const answers = StarterAnswers(
      diet: StarterDiet.vegetarian,
      kinds: {LibraryTag.soup, LibraryTag.main},
    );
    final filter = answers.toFilter('de');
    expect(filter.tags, ['Vegetarisch']);
    expect(filter.anyTags, unorderedEquals(['Suppe', 'Hauptgericht']));
    expect(filter.excludeTags, isEmpty);
  });

  test('no meat but fish excludes meat; vegan uses the vegan tag', () {
    expect(
      const StarterAnswers(diet: StarterDiet.noMeat).toFilter('en').excludeTags,
      ['Meat'],
    );
    expect(
      const StarterAnswers(diet: StarterDiet.vegan).toFilter('en').tags,
      ['Vegan'],
    );
  });
}
