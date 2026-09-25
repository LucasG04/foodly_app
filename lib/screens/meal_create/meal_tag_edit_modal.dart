import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../utils/of_context_mixin.dart';
import '../../utils/tag_candidates.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/user_information.dart';
import 'ai_tag_suggestions.dart';

/// Tag picker sheet: search/create field, then sticky AI suggestions (hidden
/// while searching), above a tag cloud where tapping toggles. Done pops the
/// selection; swipe-dismiss leaves the caller's tags untouched.
class MealTagEditModal extends StatefulWidget {
  final List<String> selectedContent;
  final List<String> allContent;
  final Future<List<String>>? suggestions;

  const MealTagEditModal({
    required this.selectedContent,
    required this.allContent,
    this.suggestions,
    super.key,
  });

  @override
  State<MealTagEditModal> createState() => _MealTagEditModalState();
}

class _MealTagEditModalState extends State<MealTagEditModal>
    with OfContextMixin {
  // Copies: the caller's list must stay untouched until Done.
  late final List<String> _selected = [...widget.selectedContent];
  late final List<String> _all = [...widget.allContent];

  final _queryController = TextEditingController();
  final _contentKey = GlobalKey();
  // Sheet height before searching, keyboard excluded. Held while searching so
  // filtering never makes the sheet jump.
  double _restHeight = 0;
  // Resolved AI suggestions: own row when idle, searchable while searching.
  List<String> _suggestions = const [];

  String get _query => _queryController.text.trim();

  @override
  void initState() {
    super.initState();
    _queryController.addListener(() => setState(() {}));
    widget.suggestions?.then((tags) {
      if (mounted) {
        setState(() => _suggestions = tags);
      }
    }).ignore(); // failures just mean no suggestion row
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = mediaSize.width > 599 ? 580.0 : mediaSize.width * 0.9;
    final inset = mediaViewInsets.bottom;
    final key = normalizeTag(_query);
    if (key.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final height = _contentKey.currentContext?.size?.height;
        if (height != null) {
          _restHeight = height - inset;
        }
      });
    }
    final suggested = _suggestions.map(normalizeTag).toSet();
    // While searching the AI row is hidden, so its tags join the results.
    final pool = [
      ..._all,
      ..._suggestions.where((s) => !_all.any((t) => _same(t, s))),
    ];
    final visible = _sorted(
      key.isEmpty
          ? _all.where((t) => !suggested.contains(normalizeTag(t)))
          : pool.where((t) => normalizeTag(t).contains(key)),
    );
    final canCreate = key.isNotEmpty && !pool.any((t) => _same(t, key));

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (mediaSize.width - width) / 2,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: key.isEmpty ? 0 : _restHeight + inset,
        ),
        child: Column(
          key: _contentKey,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHeader(),
            MainTextField(
              controller: _queryController,
              placeholder: 'meal_tag_search_hint'.tr(),
              textCapitalization: TextCapitalization.sentences,
              onSubmit: _submitQuery,
            ),
            AiTagSuggestions(
              suggestions: widget.suggestions,
              hidden: _query.isNotEmpty,
              selected: _selected,
              onToggle: _toggle,
              semanticsLabel: 'meal_tag_ai_suggestions_semantics'.tr(),
            ),
            const SizedBox(height: kPadding / 2),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom:
                      kPadding + mediaPadding.bottom + mediaViewInsets.bottom,
                ),
                child: pool.isEmpty && !canCreate
                    ? UserInformation(
                        key: const ValueKey('tags-empty'),
                        assetPath: 'assets/images/undraw_empty.png',
                        title: 'meal_create_edit_tags_no_results'.tr(),
                        message: 'meal_create_edit_tags_no_results_msg'.tr(),
                      )
                    : Wrap(
                        spacing: kPadding / 2,
                        runSpacing: kPadding / 2,
                        children: [
                          if (canCreate)
                            TagChip(
                              key: const ValueKey('tag-create'),
                              label: 'meal_tag_create'.tr(args: [_query]),
                              style: TagChipStyle.create,
                              onTap: _submitQuery,
                            ),
                          for (final tag in visible)
                            TagChip(
                              key: ValueKey('tag-$tag'),
                              label: tag,
                              selected: _isSelected(tag),
                              onTap: () => _onCloudTap(tag),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: kPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'meal_create_tags_title'.tr().toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: _close,
              style: TextButton.styleFrom(
                foregroundColor: theme.primaryColor,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('done').tr(),
                  const SizedBox(width: 5.0),
                  const Icon(EvaIcons.doneAllOutline),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _same(String a, String b) => normalizeTag(a) == normalizeTag(b);

  /// Selected tags first, then unselected; each alphabetical (umlauts as
  /// their base letter, so "Äpfel" sorts under A).
  List<String> _sorted(Iterable<String> tags) {
    int byName(String a, String b) => _sortKey(a).compareTo(_sortKey(b));
    return [
      ...tags.where(_isSelected).toList()..sort(byName),
      ...tags.where((t) => !_isSelected(t)).toList()..sort(byName),
    ];
  }

  static String _sortKey(String tag) => normalizeTag(tag)
      .replaceAll('ä', 'a')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ß', 'ss');

  bool _isSelected(String tag) => _selected.any((t) => _same(t, tag));

  void _toggle(String value) {
    if (normalizeTag(value).isEmpty) {
      return;
    }
    setState(() {
      if (_isSelected(value)) {
        _selected.removeWhere((t) => _same(t, value));
        return;
      }
      // Reuse an existing or suggested spelling so "vegan" doesn't duplicate
      // "Vegan".
      final existing = [..._all, ..._suggestions].firstWhere(
        (t) => _same(t, value),
        orElse: () => value.trim(),
      );
      if (!_all.contains(existing)) {
        _all.add(existing);
      }
      _selected.add(existing);
    });
  }

  void _onCloudTap(String tag) {
    final selecting = !_isSelected(tag);
    _toggle(tag);
    // Picking a search result: the search is done.
    if (selecting && _query.isNotEmpty) {
      _queryController.clear();
    }
  }

  /// Keyboard "done" and the create chip: select the typed tag (reusing an
  /// existing spelling or creating it), then clear the query.
  void _submitQuery() {
    final query = _query;
    if (query.isEmpty) {
      return;
    }
    if (!_isSelected(query)) {
      _toggle(query);
    }
    _queryController.clear();
  }

  void _close() {
    Navigator.of(context).pop(_selected);
  }
}
