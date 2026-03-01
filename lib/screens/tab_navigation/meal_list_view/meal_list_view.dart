import 'package:concentric_transition/concentric_transition.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../models/meal.dart';
import '../../../providers/state_providers.dart';
import '../../../services/lunix_api_service.dart';
import '../../../services/meal_service.dart';
import '../../../utils/basic_utils.dart';
import '../../../utils/debouncer.dart';
import '../../../utils/of_context_mixin.dart';
import '../../../widgets/disposable_widget.dart';
import '../../../widgets/small_circular_progress_indicator.dart';
import '../../../widgets/user_information.dart';
import '../../settings/help_slides/help_slide_share_import.dart';
import 'meal_list_tile.dart';
import 'meal_list_title.dart';

class MealListView extends ConsumerStatefulWidget {
  const MealListView({super.key});

  @override
  _MealListViewState createState() => _MealListViewState();
}

class _MealListViewState extends ConsumerState<MealListView>
    with AutomaticKeepAliveClientMixin, DisposableWidget, OfContextMixin {
  late AutoDisposeStateProvider<bool> _$isLoading;
  late StateProvider<bool> _$isLoadingPagination;
  late StateProvider<bool> _$isSearching;
  late StateProvider<List<Meal>> _$loadedMeals;
  late StateProvider<List<Meal>> _$filteredMeals;

  final ScrollController _scrollController = ScrollController();
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 500);
  final Debouncer _scrollDepouncer = Debouncer(milliseconds: 50);
  bool _paginationAtEnd = false;
  Future<List<Meal>>? _tagSearchFuture;
  List<String> _lastTagSearch = const [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    _$isLoading = StateProvider.autoDispose<bool>((_) => true);
    _$isLoadingPagination = StateProvider<bool>((_) => true);
    _$isSearching = StateProvider<bool>((_) => false);
    _$loadedMeals = StateProvider<List<Meal>>((_) => []);
    _$filteredMeals = StateProvider<List<Meal>>((_) => []);

    _loadNextMeals(ref)
        .then((_) => ref.read(_$isLoading.notifier).state = false);
    _scrollController.addListener(() => _scrollDepouncer.run(_scrollListener));
    _listenForMealsChange(ref);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    cancelSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: kPadding)),
          SliverToBoxAdapter(
            child: MealListTitle(
              onSearch: (query) {
                if (query.length > 2) {
                  _searchDebouncer.run(() => _searchMeal(query));
                }
              },
              onSearchClose: () =>
                  ref.read(_$isSearching.notifier).state = false,
              onRefresh: _refreshMeals,
            ),
          ),
          Consumer(
            builder: (context, ref, _) {
              final isLoading = ref.watch(_$isLoading);
              final selectedTags = ref.watch(mealTagFilterProvider);

              if (isLoading) {
                return _buildLoadingMealList();
              }

              return selectedTags.isEmpty
                  ? _buildMealList()
                  : _buildGroupedTagList(selectedTags);
            },
          ),
          Consumer(builder: (context, ref, _) {
            final isLoadingPagination = ref.watch(_$isLoadingPagination);
            return SliverToBoxAdapter(
              child: isLoadingPagination
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: kPadding / 2),
                      child: SmallCircularProgressIndicator(),
                    )
                  : const SizedBox(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLoadingMealList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: kPadding / 2),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const MealListTile(null),
          childCount: 10,
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, String value) {
    return Center(
      child: Container(
        width: media.size.width > 599 ? 600.0 : media.size.width * 0.9,
        margin: const EdgeInsets.only(top: kPadding),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildMealList() {
    return Consumer(builder: (context, ref, _) {
      final isSearching = ref.watch(_$isSearching);
      return isSearching ? _buildSearchedMealList() : _buildPaginatedMealList();
    });
  }

  Widget _buildSearchedMealList() {
    return Consumer(builder: (context, ref, _) {
      final filteredMeals = ref.watch(_$filteredMeals);

      if (filteredMeals.isEmpty) {
        return _buildEmptySearchedMeals();
      }

      return SliverPadding(
        padding: const EdgeInsets.symmetric(vertical: kPadding / 2),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, index) => MealListTile(filteredMeals[index]),
            childCount: filteredMeals.length,
          ),
        ),
      );
    });
  }

  Widget _buildPaginatedMealList() {
    return Consumer(builder: (context, ref, _) {
      final loadedMeals = ref.watch(_$loadedMeals);

      if (loadedMeals.isEmpty) {
        return _buildEmptyMeals();
      }

      return SliverPadding(
        padding: const EdgeInsets.symmetric(vertical: kPadding / 2),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, index) => MealListTile(loadedMeals[index]),
            childCount: loadedMeals.length,
          ),
        ),
      );
    });
  }

  Widget _buildEmptyMeals() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          UserInformation(
            assetPath: 'assets/images/undraw_empty.png',
            title: 'meal_list_empty_title'.tr(),
            message: 'meal_list_empty_subtitle'.tr(),
          ),
          const SizedBox(height: kPadding),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              ConcentricPageRoute<HelpSlideShareImport>(
                builder: (_) => HelpSlideShareImport(),
              ),
            ),
            icon: Icon(
              EvaIcons.questionMarkCircleOutline,
              color: theme.primaryColor,
            ),
            label: Text(
              'meal_list_help_import',
              style: TextStyle(color: theme.primaryColor),
            ).tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchedMeals() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          UserInformation(
            assetPath: 'assets/images/undraw_void.png',
            title: 'meal_list_empty_search_title'.tr(),
            message: 'meal_list_empty_search_subtitle'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedTagList(List<String> selectedTags) {
    return FutureBuilder<List<Meal>>(
        future: _searchMealsByTagsCached(selectedTags),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _buildLoadingMealList();
          }

          final groups = _groupMealsByTags(snapshot.data!, selectedTags);
          final rows = _buildGroupRows(groups);

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, index) {
                final row = rows[index];

                if (row.isHeader) {
                  return _buildSubtitle(context, row.tag!);
                }

                return MealListTile(row.meal);
              },
              childCount: rows.length,
            ),
          );
        });
  }

  Future<List<Meal>> _searchMealsByTagsCached(List<String> selectedTags) {
    if (_tagSearchFuture != null && listEquals(_lastTagSearch, selectedTags)) {
      return _tagSearchFuture!;
    }

    _lastTagSearch = List<String>.from(selectedTags);
    _tagSearchFuture = LunixApiService.searchMealsByTags(
        ref.read(planProvider)!.id!, selectedTags);

    return _tagSearchFuture!;
  }

  List<_GroupRow> _buildGroupRows(List<TagGroup> groups) {
    final rows = <_GroupRow>[];

    for (final group in groups) {
      rows.add(_GroupRow.header(group.tag));
      for (final meal in group.meals) {
        rows.add(_GroupRow.meal(meal));
      }
    }

    return rows;
  }

  List<TagGroup> _groupMealsByTags(List<Meal> meals, List<String> tags) {
    final List<TagGroup> tagList =
        tags.map((tag) => TagGroup(tag, [])).toList();

    for (final group in tagList) {
      group.meals =
          meals.where((element) => element.tags!.contains(group.tag)).toList();
    }

    return tagList;
  }

  Future<void> _searchMeal(String query) async {
    if (query.isEmpty) {
      return;
    }
    ref.read(_$isLoading.notifier).state = true;
    ref.read(mealTagFilterProvider.notifier).state = [];
    ref.read(_$filteredMeals.notifier).state =
        await LunixApiService.searchMeals(
      ref.read(planProvider)!.id!,
      query,
    );

    if (!mounted) {
      return;
    }
    ref.read(_$isSearching.notifier).state = true;
    ref.read(_$isLoading.notifier).state = false;
    FirebaseAnalytics.instance.logEvent(
      name: 'search_meal_list',
      parameters: {'query': query},
    );
  }

  void _scrollListener() {
    if (!_paginationActive() || _paginationAtEnd) {
      return;
    }
    final loadNew = _scrollController.offset >=
        _scrollController.position.maxScrollExtent * 0.7;

    if (!loadNew) {
      return;
    }
    _loadNextMeals(ref);
  }

  Future<void> _loadNextMeals(WidgetRef ref) async {
    final refIsLoadingPagination = ref.read(_$isLoadingPagination.notifier);
    refIsLoadingPagination.state = true;
    const pageSize = 30;
    final refMeals = ref.read(_$loadedMeals.notifier);

    final nextMeals = await MealService.getMealsPaginated(
      ref.read(planProvider)!.id!,
      lastMealId: refMeals.state.isEmpty ? null : refMeals.state.last.id,
      amount: pageSize, // ignore: avoid_redundant_argument_values
    );

    _paginationAtEnd = nextMeals.length < pageSize;

    if (!mounted) {
      return;
    }

    refMeals.state = [...refMeals.state, ...nextMeals];
    refIsLoadingPagination.state = false;
  }

  bool _paginationActive() {
    return ref.read(mealTagFilterProvider).isEmpty &&
        !ref.read(_$isLoading) &&
        !ref.read(_$isLoadingPagination) &&
        !ref.read(_$isSearching) &&
        ref.read(_$loadedMeals).isNotEmpty;
  }

  void _refreshMeals() async {
    final refIsLoading = ref.read(_$isLoading.notifier);
    refIsLoading.state = true;
    ref.read(_$loadedMeals.notifier).state = [];
    ref.read(_$filteredMeals.notifier).state = [];
    ref.read(_$isLoadingPagination.notifier).state = false;
    ref.read(_$isSearching.notifier).state = false;
    ref.read(mealTagFilterProvider.notifier).state = [];
    await _loadNextMeals(ref);
    if (!mounted) {
      return;
    }
    refIsLoading.state = false;
  }

  void _listenForMealsChange(WidgetRef ref) {
    final stream = ref.read(lastChangedMealProvider.notifier).stream;
    BasicUtils.afterBuild(
      () => stream
          .where((mealId) => mealId != null)
          .listen((_) => _refreshMeals())
          .canceledBy(this),
    );
  }
}

class TagGroup {
  List<Meal> meals;
  String tag;

  TagGroup(this.tag, this.meals);
}

class _GroupRow {
  final String? tag;
  final Meal? meal;
  final bool isHeader;

  const _GroupRow._(
      {required this.tag, required this.meal, required this.isHeader});

  factory _GroupRow.header(String tag) {
    return _GroupRow._(tag: tag, meal: null, isHeader: true);
  }

  factory _GroupRow.meal(Meal meal) {
    return _GroupRow._(tag: null, meal: meal, isHeader: false);
  }
}
