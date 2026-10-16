import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/library_meal.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/choice_tile.dart';
import '../../widgets/main_button.dart';
import '../../widgets/sheet_header.dart';
import '../../widgets/tag_chip.dart';

enum StarterDiet { everything, vegetarian, vegan, noMeat }

enum StarterCuisine { german, international, both }

/// Answers of the starter questionnaire; [toFilter] turns them into a library
/// search. Questions are AND-combined, the kinds of dishes OR-combined.
class StarterAnswers {
  final StarterDiet diet;
  final Set<LibraryTag> kinds;
  final bool quick;
  final StarterCuisine cuisine;

  const StarterAnswers({
    this.diet = StarterDiet.everything,
    this.kinds = const {},
    this.quick = false,
    this.cuisine = StarterCuisine.both,
  });

  StarterAnswers copyWith({
    StarterDiet? diet,
    Set<LibraryTag>? kinds,
    bool? quick,
    StarterCuisine? cuisine,
  }) =>
      StarterAnswers(
        diet: diet ?? this.diet,
        kinds: kinds ?? this.kinds,
        quick: quick ?? this.quick,
        cuisine: cuisine ?? this.cuisine,
      );

  LibraryFilter toFilter(String lang) => LibraryFilter(
        tags: [
          if (diet == StarterDiet.vegetarian) LibraryTag.vegetarian.label(lang),
          if (diet == StarterDiet.vegan) LibraryTag.vegan.label(lang),
          if (quick) LibraryTag.quick.label(lang),
          if (cuisine == StarterCuisine.german) LibraryTag.german.label(lang),
          if (cuisine == StarterCuisine.international)
            LibraryTag.international.label(lang),
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

/// Starter questionnaire for an empty meal list, one question per step.
/// Pops with the [StarterAnswers], or null when closed.
class LibraryStarterSheet extends StatefulWidget {
  const LibraryStarterSheet({super.key});

  @override
  State<LibraryStarterSheet> createState() => _LibraryStarterSheetState();
}

class _LibraryStarterSheetState extends State<LibraryStarterSheet> {
  static const _steps = 4;
  int _step = 0;
  StarterAnswers _answers = const StarterAnswers();

  Color? get _secondaryTextColor =>
      Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6);

  @override
  Widget build(BuildContext context) {
    final lang = libraryLang(Localizations.localeOf(context).languageCode);
    final last = _step == _steps - 1;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final width = screenWidth > 599 ? 580.0 : screenWidth * 0.8;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: (screenWidth - width) / 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(
            title: context.tr('library_starter_title'),
            actions: [
              if (_step > 0)
                IconButton(
                  icon: const Icon(EvaIcons.arrowBackOutline),
                  tooltip: context.tr('library_starter_back'),
                  onPressed: () => setState(() => _step--),
                ),
            ],
          ),
          const SizedBox(height: kPadding / 2),
          Text(
            context.tr('library_starter_step', args: [
              '${_step + 1}',
              '$_steps',
            ]),
            style: TextStyle(
              color: _secondaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kPadding / 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey(_step),
              child: _buildStep(lang),
            ),
          ),
          const SizedBox(height: kPadding),
          Center(
            child: MainButton(
              text: context
                  .tr(last ? 'library_starter_show' : 'library_starter_next'),
              onTap: () => last
                  ? Navigator.pop(context, _answers)
                  : setState(() => _step++),
            ),
          ),
          SizedBox(height: WidgetUtils.sheetBottomPadding(context)),
        ],
      ),
    );
  }

  Widget _buildStep(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('library_starter_q${_step + 1}'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: kPadding),
        switch (_step) {
          0 => ChoiceTileGrid(
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
                    onTap: () => setState(
                        () => _answers = _answers.copyWith(diet: diet)),
                  ),
              ],
              columns: 2,
            ),
          1 => Wrap(
              spacing: kPadding / 2,
              runSpacing: kPadding / 2,
              children: [
                for (final kind in starterKinds)
                  TagChip(
                    label: kind.label(lang),
                    selected: _answers.kinds.contains(kind),
                    onTap: () => setState(() {
                      final kinds = {..._answers.kinds};
                      kinds.contains(kind)
                          ? kinds.remove(kind)
                          : kinds.add(kind);
                      _answers = _answers.copyWith(kinds: kinds);
                    }),
                  ),
              ],
            ),
          2 => ChoiceTileGrid(
              [
                for (final (quick, icon) in [
                  (true, Icons.bolt_rounded),
                  (false, Icons.schedule_rounded),
                ])
                  _tile(
                    selected: _answers.quick == quick,
                    icon: icon,
                    label: 'library_starter_time_${quick ? 'quick' : 'any'}',
                    onTap: () => setState(
                        () => _answers = _answers.copyWith(quick: quick)),
                  ),
              ],
              columns: 2,
            ),
          _ => ChoiceTileGrid(
              [
                for (final (cuisine, icon) in [
                  (StarterCuisine.german, Icons.home_outlined),
                  (StarterCuisine.international, Icons.public_rounded),
                  (StarterCuisine.both, Icons.all_inclusive_rounded),
                ])
                  _tile(
                    selected: _answers.cuisine == cuisine,
                    icon: icon,
                    label: 'library_starter_cuisine_${cuisine.name}',
                    onTap: () => setState(
                        () => _answers = _answers.copyWith(cuisine: cuisine)),
                  ),
              ],
              columns: 3,
            ),
        },
        if (_step == 1) ...[
          const SizedBox(height: kPadding / 2),
          Text(
            context.tr('library_starter_kinds_hint'),
            style: TextStyle(color: _secondaryTextColor),
          ),
        ],
      ],
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
