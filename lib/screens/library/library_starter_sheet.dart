import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/library_meal.dart';
import '../../widgets/choice_tile.dart';
import '../../widgets/main_button.dart';
import '../../widgets/tag_chip.dart';

enum StarterDiet { everything, vegetarian, vegan, noMeat }

/// Answers of the starter questionnaire; [toFilter] turns them into a library
/// search. Questions are AND-combined, the kinds of dishes OR-combined.
class StarterAnswers {
  final StarterDiet diet;
  final Set<LibraryTag> kinds;

  const StarterAnswers({
    this.diet = StarterDiet.everything,
    this.kinds = const {},
  });

  StarterAnswers copyWith({
    StarterDiet? diet,
    Set<LibraryTag>? kinds,
  }) =>
      StarterAnswers(
        diet: diet ?? this.diet,
        kinds: kinds ?? this.kinds,
      );

  LibraryFilter toFilter(String lang) => LibraryFilter(
        tags: [
          if (diet == StarterDiet.vegetarian) LibraryTag.vegetarian.label(lang),
          if (diet == StarterDiet.vegan) LibraryTag.vegan.label(lang),
        ],
        anyTags: [for (final kind in kinds) kind.label(lang)],
        excludeTags: [
          if (diet == StarterDiet.noMeat) LibraryTag.meat.label(lang),
        ],
      );
}

/// The kinds of dishes the questionnaire offers.
const starterKinds = [
  LibraryTag.main,
  LibraryTag.soup,
  LibraryTag.salad,
  LibraryTag.breakfast,
  LibraryTag.side,
];

/// The two starter questions (diet, kinds of dishes), shown inline in the
/// empty meal list. Both default to "everything".
class LibraryStarterQuestions extends StatefulWidget {
  final ValueChanged<StarterAnswers> onSubmit;

  const LibraryStarterQuestions({required this.onSubmit, super.key});

  @override
  State<LibraryStarterQuestions> createState() =>
      _LibraryStarterQuestionsState();
}

class _LibraryStarterQuestionsState extends State<LibraryStarterQuestions> {
  StarterAnswers _answers = const StarterAnswers();

  Color? get _secondaryTextColor =>
      Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6);

  @override
  Widget build(BuildContext context) {
    final lang = libraryLang(Localizations.localeOf(context).languageCode);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('library_starter_q1'),
        ChoiceTileGrid(
          [
            for (final (diet, icon) in [
              (StarterDiet.everything, Icons.restaurant_rounded),
              (StarterDiet.vegetarian, Icons.eco_outlined),
              (StarterDiet.vegan, Icons.spa_outlined),
              (StarterDiet.noMeat, Icons.set_meal_outlined),
            ])
              _tile(
                selected: _answers.diet == diet,
                icon: icon,
                label: 'library_starter_diet_${diet.name}',
                onTap: () =>
                    setState(() => _answers = _answers.copyWith(diet: diet)),
              ),
          ],
          columns: 2,
        ),
        const SizedBox(height: kPadding),
        _label('library_starter_q2'),
        Wrap(
          spacing: kPadding / 2,
          runSpacing: kPadding / 2,
          children: [
            for (final kind in starterKinds)
              TagChip(
                label: kind.label(lang),
                selected: _answers.kinds.contains(kind),
                onTap: () => setState(() {
                  final kinds = {..._answers.kinds};
                  kinds.contains(kind) ? kinds.remove(kind) : kinds.add(kind);
                  _answers = _answers.copyWith(kinds: kinds);
                }),
              ),
          ],
        ),
        const SizedBox(height: kPadding / 2),
        Text(
          context.tr('library_starter_kinds_hint'),
          style: TextStyle(color: _secondaryTextColor),
        ),
        const SizedBox(height: kPadding),
        Center(
          child: MainButton(
            text: context.tr('library_starter_show'),
            onTap: () => widget.onSubmit(_answers),
          ),
        ),
      ],
    );
  }

  Widget _label(String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kPadding / 2),
      child: Text(
        context.tr(key),
        style: TextStyle(
          color: _secondaryTextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _tile({
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ChoiceTile(
      selected: selected,
      onTap: onTap,
      builder: (color) => [
        Icon(icon, color: color),
        const SizedBox(height: kPadding / 4),
        Text(
          context.tr(label),
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
