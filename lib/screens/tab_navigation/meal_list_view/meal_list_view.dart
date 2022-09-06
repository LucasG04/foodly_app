import 'package:concentric_transition/concentric_transition.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_list_view/group_list_view.dart';

import '../../../constants.dart';
import '../../../models/meal.dart';
import '../../../providers/state_providers.dart';
import '../../../services/lunix_api_service.dart';
import '../../../services/meal_service.dart';
import '../../../utils/basic_utils.dart';
import '../../../utils/debouncer.dart';
import '../../../widgets/disposable_widget.dart';
import '../../../widgets/small_circular_progress_indicator.dart';
import '../../../widgets/user_information.dart';
import '../../settings/help_slides/help_slide_share_import.dart';
import 'meal_list_tile.dart';
import 'meal_list_title.dart';

class MealListView extends StatefulWidget {
  const MealListView({Key? key}) : super(key: key);

  @override
  State<MealListView> createState() => _MealListViewState();
}

class _MealListViewState extends State<MealListView>
    with AutomaticKeepAliveClientMixin, DisposableWidget {
  late AutoDisposeStateProvider<bool> _$isLoading;
  late StateProvider<bool> _$isLoadingPagination;
  late StateProvider<bool> _$isSearching;
  late StateProvider<List<Meal>> _$loadedMeals;
  late StateProvider<List<Meal>> _$filteredMeals;

  final ScrollController _scrollController = ScrollController();
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 500);
  bool _paginationAtEnd = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    _$isLoading = StateProvider.autoDispose<bool>((_) => true);
    _$isLoadingPagination = StateProvider<bool>((_) => true);
    _$isSearching = StateProvider<bool>((_) => false);
    _$loadedMeals = StateProvider<List<Meal>>((_) => []);
    _$filteredMeals = StateProvider<List<Meal>>((_) => []);

    _loadNextMeals().then((_) => context.read(_$isLoading).state = false);
    _scrollController.addListener(_scrollListener);
    _listenForMealsChange();
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
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            const SizedBox(height: kPadding),
            MealListTitle(
              onSearch: (query) {
                if (query.length > 2) {
                  _searchDebouncer.run(() => _searchMeal(query));
                }
              },
              onSearchClose: () => context.read(_$isSearching).state = false,
              onRefresh: _refreshMeals,
            ),
            Consumer(
              builder: (context, watch, _) {
                final isLoading = watch(_$isLoading).state;
                final selectedTags = watch(mealTagFilterProvider).state;

                if (isLoading) {
                  return _buildLoadingMealList();
                }

                return selectedTags.isEmpty
                    ? _buildMealList()
                    : _buildGroupedTagList(selectedTags);
              },
            ),
            Consumer(builder: (context, watch, _) {
              final isLoadingPagination = watch(_$isLoadingPagination).state;
              return isLoadingPagination
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: kPadding / 2),
                      child: SmallCircularProgressIndicator(),
                    )
                  : const SizedBox();
            }),
          ],
        ),
      ),
    );
  }

  Padding _buildLoadingMealList() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kPadding / 2),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: List.generate(
          10,
          (_) => const MealListTile(null),
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, String value) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width > 599
            ? 600.0
            : MediaQuery.of(context).size.width * 0.9,
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
    return Consumer(builder: (context, watch, _) {
      final isSearching = watch(_$isSearching).state;
      return isSearching ? _buildSearchedMealList() : _buildPaginatedMealList();
    });
  }

  Consumer _buildSearchedMealList() {
    return Consumer(builder: (context, watch, _) {
      final filteredMeals = watch(_$filteredMeals).state;

      if (filteredMeals.isEmpty) {
        return _buildEmptySearchedMeals();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: kPadding / 2),
        child: ListView.builder(
          itemCount: filteredMeals.length,
          itemBuilder: (_, index) => MealListTile(filteredMeals[index]),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
        ),
      );
    });
  }

  Consumer _buildPaginatedMealList() {
    return Consumer(builder: (context, watch, _) {
      final loadedMeals = watch(_$loadedMeals).state;

      if (loadedMeals.isEmpty) {
        return _buildEmptyMeals();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: kPadding / 2),
        child: ListView.builder(
          itemCount: loadedMeals.length,
          itemBuilder: (_, index) => MealListTile(loadedMeals[index]),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
        ),
      );
    });
  }

  Widget _buildEmptyMeals() {
    return Column(
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
          icon: const Icon(EvaIcons.questionMarkCircleOutline),
          label: const Text('meal_list_help_import').tr(),
        ),
      ],
    );
  }

  Widget _buildEmptySearchedMeals() {
    return Column(
      children: [
        UserInformation(
          assetPath: 'assets/images/undraw_void.png',
          title: 'meal_list_empty_search_title'.tr(),
          message: 'meal_list_empty_search_subtitle'.tr(),
        ),
      ],
    );
  }

  Widget _buildGroupedTagList(List<String> selectedTags) {
    return FutureBuilder<List<Meal>>(
        future: LunixApiService.searchMealsByTags(
          context.read(planProvider).state!.id!,
          selectedTags,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _buildLoadingMealList();
          }

          final groups = _groupMealsByTags(snapshot.data!, selectedTags);

          return GroupListView(
            itemBuilder: (_, item) => MealListTile(
              groups[item.section].meals[item.index],
            ),
            sectionsCount: groups.length,
            groupHeaderBuilder: (_, group) => _buildSubtitle(
              context,
              groups[group].tag,
            ),
            countOfItemInSection: (section) => groups[section].meals.length,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
          );
        });
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
    context.read(_$isLoading).state = true;
    context.read(mealTagFilterProvider).state = [];
    context.read(_$filteredMeals).state = await LunixApiService.searchMeals(
      context.read(planProvider).state!.id!,
      query,
    );

    if (!mounted) {
      return;
    }
    context.read(_$isSearching).state = true;
    context.read(_$isLoading).state = false;
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
    _loadNextMeals();
  }

  Future<void> _loadNextMeals() async {
    context.read(_$isLoadingPagination).state = true;
    const pageSize = 30;
    final currentMeals = context.read(_$loadedMeals).state;

    final nextMeals = await MealService.getMealsPaginated(
      context.read(planProvider).state!.id!,
      lastMealId: currentMeals.isEmpty ? null : currentMeals.last.id,
      amount: pageSize, // ignore: avoid_redundant_argument_values
    );

    _paginationAtEnd = nextMeals.length < pageSize;

    if (!mounted) {
      return;
    }

    context.read(_$loadedMeals).state = [...currentMeals, ...nextMeals];
    context.read(_$isLoadingPagination).state = false;
  }

  bool _paginationActive() {
    return context.read(mealTagFilterProvider).state.isEmpty &&
        !context.read(_$isLoading).state &&
        !context.read(_$isSearching).state &&
        context.read(_$loadedMeals).state.isNotEmpty;
  }

  void _refreshMeals() async {
    context.read(_$isLoading).state = true;
    context.read(_$loadedMeals).state = [];
    context.read(_$filteredMeals).state = [];
    context.read(_$isLoadingPagination).state = false;
    context.read(_$isSearching).state = false;
    context.read(mealTagFilterProvider).state = [];
    await _loadNextMeals();
    if (!mounted) {
      return;
    }
    context.read(_$isLoading).state = false;
  }

  void _listenForMealsChange() {
    BasicUtils.afterBuild(
      () => context
          .read(lastChangedMealProvider)
          .stream
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
