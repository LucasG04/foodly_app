import 'package:auto_route/auto_route.dart';
import 'package:badges/badges.dart' as badges;
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_router.gr.dart';
import '../../constants.dart';
import '../../models/library_meal.dart';
import '../../providers/state_providers.dart';
import '../../services/lunix_api_service.dart';
import '../../utils/analytics.dart';
import '../../utils/basic_utils.dart';
import '../../utils/main_snackbar.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/main_appbar.dart';
import '../../widgets/progress_button.dart';
import '../../widgets/small_circular_progress_indicator.dart';
import '../../widgets/tag_chip.dart';
import '../../widgets/user_information.dart';
import '../meal_select/search_bar.dart' as foodly_search_bar;
import '../tab_navigation/meal_list_view/meal_list_tile.dart';
import 'library_import.dart';
import 'library_intent_sheet.dart';
import 'library_meal_tile.dart';
import 'library_starter_sheet.dart';

/// The meal library: search, tag filter, multi-select import. Opens with the
/// intent sheet unless [query], [tags] or [starter] answers are given; with
/// [starter], the first [starterPicks] dishes come preselected.
class LibraryScreen extends ConsumerStatefulWidget {
  final String? query;
  final List<String>? tags;
  final StarterAnswers? starter;

  /// Where the library was opened (analytics).
  final String entry;

  const LibraryScreen({
    this.query,
    this.tags,
    this.starter,
    this.entry = 'header',
    super.key,
  });

  static const starterPicks = 15;

  /// lunix-api accepts at most this many dishes per import (`MAX_IMPORT`).
  static const maxImport = 50;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _scroll = ScrollController();
  late final _search = TextEditingController(text: widget.query);

  late LibraryFilter _filter = LibraryFilter(
    tags: widget.tags ?? const [],
    query: widget.query ?? '',
  );
  List<LibraryMeal> _items = [];
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _failed = false;
  // Drops responses of superseded searches.
  int _request = 0;
  final Set<String> _selected = {};

  /// Added in this session; hidden even before the server's plan cache knows.
  final Set<String> _importedIds = {};

  /// The questionnaire's picks are preselected once, not after every search.
  bool _preselected = false;
  ButtonState _importState = ButtonState.normal;

  String get _lang => libraryLang(context.locale.languageCode);

  @override
  void initState() {
    super.initState();
    logEvent(AnalyticsEvent.libraryOpen, {'entry': widget.entry});
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) {
        _loadMore();
      }
    });
    BasicUtils.afterBuild(() {
      if (widget.starter != null) {
        _filter = widget.starter!.toFilter(_lang);
      }
      _load();
      if (widget.starter == null && _filter.isEmpty) {
        _openIntentSheet();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        text: context.tr(widget.starter != null
            ? 'library_starter_result_title'
            : 'library_title'),
        scrollController: _scroll,
      ),
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          ..._buildList(),
          // Room for the floating button over the last tile.
          const SliverSafeArea(
            top: false,
            sliver: SliverToBoxAdapter(child: SizedBox(height: 88)),
          ),
        ],
      ),
      floatingActionButton: _selected.isEmpty ? null : _buildImportButton(),
    );
  }

  /// Import FAB with the number of selected dishes as badge; a spinner while
  /// importing.
  Widget _buildImportButton() {
    final theme = Theme.of(context);
    final importing = _importState == ButtonState.inProgress;
    return badges.Badge(
      showBadge: !importing,
      badgeStyle: badges.BadgeStyle(
        badgeColor: Colors.white,
        borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
      ),
      position: badges.BadgePosition.topEnd(top: -6, end: -4),
      badgeAnimation: const badges.BadgeAnimation.scale(
        animationDuration: Duration(milliseconds: 250),
      ),
      badgeContent: Text(
        '${_selected.length}',
        style: TextStyle(
          color: theme.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      child: FloatingActionButton(
        heroTag: null,
        backgroundColor: theme.primaryColor,
        tooltip: context.plural('library_import_n', _selected.length),
        onPressed: importing ? null : _importSelected,
        child: importing
            ? const SmallCircularProgressIndicator(color: Colors.white)
            : const Icon(EvaIcons.downloadOutline, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: SizedBox(
        width: BasicUtils.contentWidth(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: kPadding / 2),
            // Same search bar as the plan's meal picker (debounces itself).
            foodly_search_bar.SearchBar(
              controller: _search,
              hintText: context.tr('library_search_placeholder'),
              onSearch: (text) => _setFilter(_filter.copyWith(query: text)),
            ),
            const SizedBox(height: kPadding / 2),
            Wrap(
              spacing: kPadding / 2,
              runSpacing: kPadding / 2,
              children: [
                TagChip(
                  label: context.tr('library_filter'),
                  style: TagChipStyle.create,
                  onTap: _openIntentSheet,
                ),
                for (final tag in _filter.tags)
                  TagChip(
                    label: tag,
                    selected: true,
                    onTap: () => _setFilter(_filter.copyWith(
                      tags: _filter.tags.where((t) => t != tag).toList(),
                    )),
                  ),
                // From the questionnaire: one of these kinds, none of these.
                if (_filter.anyTags.isNotEmpty)
                  TagChip(
                    label: _filter.anyTags.join(' / '),
                    selected: true,
                    onTap: () =>
                        _setFilter(_filter.copyWith(anyTags: const [])),
                  ),
                for (final tag in _filter.excludeTags)
                  TagChip(
                    label: context.tr('library_without', args: [tag]),
                    selected: true,
                    onTap: () => _setFilter(_filter.copyWith(
                      excludeTags:
                          _filter.excludeTags.where((t) => t != tag).toList(),
                    )),
                  ),
              ],
            ),
            if (!_loading && !_failed && _total > 0)
              Padding(
                padding: const EdgeInsets.only(top: kPadding / 2),
                child: Text(
                  context.plural('library_count', _total),
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
          ],
        ),
      ),
    );
  }

  List<Widget> _buildList() {
    if (_loading) {
      return [
        SliverList.builder(
          itemCount: 6,
          itemBuilder: (_, __) => const MealListTile(null),
        ),
      ];
    }
    if (_failed || _items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Column(
            children: [
              UserInformation(
                assetPath: 'assets/images/undraw_void.png',
                title: context.tr(
                    _failed ? 'library_error_title' : 'library_empty_title'),
                message: context.tr(_failed
                    ? 'library_error_message'
                    : 'library_empty_message'),
              ),
              if (_failed)
                TextButton(
                  onPressed: _load,
                  child: Text(context.tr('library_retry')),
                ),
            ],
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(vertical: kPadding / 2),
        sliver: SliverList.builder(
          itemCount: _items.length,
          itemBuilder: (_, index) {
            final meal = _items[index];
            return LibraryMealTile(
              key: ValueKey(meal.id),
              meal: meal,
              selected: _selected.contains(meal.id),
              onToggle: () => _toggle(meal.id),
              onTap: () => AutoRouter.of(context).push(LibraryMealScreenRoute(
                id: meal.id,
                entry: widget.entry,
                onImported: _markImported,
              )),
            );
          },
        ),
      ),
      if (_loadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(kPadding / 2),
            child: Center(child: SmallCircularProgressIndicator()),
          ),
        ),
    ];
  }

  void _setFilter(LibraryFilter filter) {
    _filter = filter;
    _load();
  }

  Future<void> _openIntentSheet() async {
    final filter = await WidgetUtils.showFoodlyBottomSheet<LibraryFilter>(
      context: context,
      builder: (_) => LibraryIntentSheet(initial: _filter),
    );
    if (filter == null || !mounted) {
      return;
    }
    _search.text = filter.query;
    _setFilter(filter);
  }

  /// Dishes the plan already has are never listed.
  Future<LibraryPage?> _fetchPage({int offset = 0}) {
    return LunixApiService.searchLibrary(
      lang: _lang,
      planId: ref.read(planProvider)?.id,
      filter: _filter,
      hideImported: true,
      offset: offset,
    );
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _failed = false;
    });
    final page = await _fetchPage();
    if (!mounted || request != _request) {
      return;
    }
    setState(() {
      _loading = false;
      _failed = page == null;
      _items = page?.items ?? [];
      _total = page?.total ?? 0;
      if (widget.starter != null && page != null && !_preselected) {
        _preselected = true;
        _selected
            .addAll(_items.take(LibraryScreen.starterPicks).map((m) => m.id));
      }
    });
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _items.length >= _total) {
      return;
    }
    final request = _request;
    setState(() => _loadingMore = true);
    final page = await _fetchPage(offset: _items.length);
    if (!mounted || request != _request) {
      return;
    }
    final loaded = _items.map((m) => m.id).toSet();
    final added = page?.items
            .where(
                (m) => !loaded.contains(m.id) && !_importedIds.contains(m.id))
            .toList() ??
        [];
    setState(() {
      _loadingMore = false;
      if (page != null) {
        _items = [..._items, ...added];
        _total = page.total;
      }
    });
    if (added.isNotEmpty) {
      _fillIfShort();
    }
  }

  /// After imports removed dishes, load more so the list doesn't look empty
  /// (a short list can't be scrolled to trigger paging).
  void _fillIfShort() {
    if (_items.length < 10) {
      _loadMore();
    }
  }

  void _toggle(String id) {
    if (!_selected.contains(id) &&
        _selected.length >= LibraryScreen.maxImport) {
      MainSnackbar(
        message: context.tr('library_select_max', args: [
          '${LibraryScreen.maxImport}',
        ]),
      ).show(context);
      return;
    }
    setState(() {
      _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    });
  }

  /// The dish leaves the list (as on the server, so paging offsets still
  /// match).
  void _markImported(String libraryId, String _) {
    if (!mounted) {
      return;
    }
    _importedIds.add(libraryId);
    setState(() {
      _selected.remove(libraryId);
      final before = _items.length;
      _items = _items.where((m) => m.id != libraryId).toList();
      _total -= before - _items.length;
    });
    _fillIfShort();
  }

  Future<void> _importSelected() async {
    if (_importState == ButtonState.inProgress) {
      return;
    }
    setState(() => _importState = ButtonState.inProgress);
    final ids = _selected.toList();
    final result = await importFromLibrary(
      context,
      ids,
      entry: widget.entry,
    );
    if (!mounted) {
      return;
    }
    setState(() => _importState = ButtonState.normal);
    if (result == null) {
      return;
    }
    for (final meal in result.meals) {
      if (meal.libraryId != null) {
        _markImported(meal.libraryId!, meal.id!);
      }
    }
    setState(_selected.clear);
    // Dishes the plan already had (or that left the library) aren't counted.
    if (result.created > 0) {
      // Stays when this screen pops back to the meal list.
      MainSnackbar(
        message: context.plural('library_imported_n', result.created),
        isSuccess: true,
      ).show(context);
    }
    if (widget.starter != null) {
      AutoRouter.of(context).pop();
    }
  }
}
