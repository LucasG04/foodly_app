import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/library_meal.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/keyboard_aware_sheet.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/sheet_header.dart';
import '../../widgets/tag_chip.dart';
import '../tab_navigation/meal_list_view/tag_filter_modal.dart';

/// "What are you looking for?": library tags and a search field. Pops with
/// the [LibraryFilter]; "Show all" pops with an empty one, closing with null.
class LibraryIntentSheet extends StatefulWidget {
  final LibraryFilter initial;

  const LibraryIntentSheet({this.initial = const LibraryFilter(), super.key});

  @override
  State<LibraryIntentSheet> createState() => _LibraryIntentSheetState();
}

class _LibraryIntentSheetState extends State<LibraryIntentSheet> {
  late List<String> _tags = widget.initial.tags;
  late final TextEditingController _query =
      TextEditingController(text: widget.initial.query);

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = libraryLang(Localizations.localeOf(context).languageCode);
    return KeyboardAwareSheet(
      header: SheetHeader(title: context.tr('library_intent_title')),
      children: [
        const SizedBox(height: kPadding / 2),
        MainTextField(
          controller: _query,
          placeholder: context.tr('library_search_placeholder'),
          textInputAction: TextInputAction.search,
          onSubmit: _apply,
        ),
        for (final (label, tags) in _sections) ...[
          const SizedBox(height: kPadding),
          Padding(
            padding: const EdgeInsets.only(bottom: kPadding / 2),
            child: Text(
              context.tr(label),
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Wrap(
            spacing: kPadding / 2,
            runSpacing: kPadding / 2,
            children: [
              for (final tag in tags.map((t) => t.label(lang)))
                TagChip(
                  label: tag,
                  selected: _tags.contains(tag),
                  onTap: () => setState(
                      () => _tags = TagFilterModal.toggleTag(_tags, tag)),
                ),
            ],
          ),
        ],
        const SizedBox(height: kPadding),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: MainButton(
                text: context.tr('library_show_all'),
                isSecondary: true,
                onTap: () =>
                    Navigator.pop(context, const LibraryFilter()),
              ),
            ),
            const SizedBox(width: kPadding / 2),
            Flexible(
              child: MainButton(
                text: context.tr('library_show'),
                onTap: _apply,
              ),
            ),
          ],
        ),
        SizedBox(height: WidgetUtils.sheetBottomPadding(context)),
      ],
    );
  }

  /// Tag groups with their label. No drinks: the library has none (left out
  /// when it was curated).
  static const _sections = [
    (
      'library_intent_kind',
      [
        LibraryTag.main,
        LibraryTag.side,
        LibraryTag.soup,
        LibraryTag.salad,
        LibraryTag.breakfast,
        LibraryTag.snack,
        LibraryTag.dessert,
        LibraryTag.baking,
        LibraryTag.sauce,
      ],
    ),
    (
      'library_intent_diet',
      [
        LibraryTag.vegetarian,
        LibraryTag.vegan,
        LibraryTag.meat,
        LibraryTag.fish
      ],
    ),
    (
      'library_intent_more',
      [LibraryTag.quick, LibraryTag.german, LibraryTag.international],
    ),
  ];

  void _apply() => Navigator.pop(
        context,
        // Keeps the questionnaire's anyTags/excludeTags.
        widget.initial.copyWith(tags: _tags, query: _query.text),
      );
}
