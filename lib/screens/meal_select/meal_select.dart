import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../app_router.gr.dart';
import '../../constants.dart';
import '../../models/library_meal.dart';
import '../../models/meal.dart';
import '../../models/plan_meal.dart';
import '../../providers/state_providers.dart';
import '../../services/in_app_purchase_service.dart';
import '../../services/lunix_api_service.dart';
import '../../services/meal_service.dart';
import '../../services/meal_stat_service.dart';
import '../../services/plan_service.dart';
import '../../services/settings_service.dart';
import '../../utils/analytics.dart';
import '../../utils/main_snackbar.dart';
import '../../utils/of_context_mixin.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/get_premium_info.dart';
import '../../widgets/get_premium_modal.dart';
import '../../widgets/main_appbar.dart';
import '../../widgets/meal_pagination.dart';
import '../../widgets/user_information.dart';
import '../add_dish/add_dish_sheet.dart';
import '../library/library_import.dart';
import '../library/library_starter_sheet.dart';
import '../tab_navigation/meal_list_view/meal_list_tile.dart';
import 'search_bar.dart' as foodly_search_bar;
import 'select_meal_tile.dart';

class MealSelectScreen extends ConsumerStatefulWidget {
  final DateTime date;
  final MealType mealType;

  const MealSelectScreen(
      {required this.date, required this.mealType, super.key});

  @override
  _MealSelectScreenState createState() => _MealSelectScreenState();
}

class _MealSelectScreenState extends ConsumerState<MealSelectScreen>
    with OfContextMixin {
  final _$isSearching = StateProvider.autoDispose<bool>((_) => false);
  final _$randomMeal = FutureProvider.autoDispose<Meal?>(
      (ref) => LunixApiService.getRandomMeal(ref.read(planProvider)!.id!));

  /// Whether the plan has no dishes yet; it then gets the starter questions
  /// instead of suggestions.
  late final _$cookbookEmpty = FutureProvider.autoDispose<bool>((ref) async {
    // A random dish means there are dishes: no extra read then.
    final randomMeal = ref.watch(_$randomMeal.future);
    if (await randomMeal != null) {
      return false;
    }
    final (meals, _) = await MealService.getMealsPaginated(
      ref.read(planProvider)!.id!,
      amount: 1,
    );
    return meals.isEmpty;
  });

  final ScrollController _scrollController = ScrollController();

  List<Meal> searchedMeals = [];

  /// Library dishes for a search without own results.
  List<LibraryMeal> _libraryMeals = [];

  /// The query of the shown results; empty when not searching.
  String _lastQuery = '';

  // Drops results of older searches.
  int _searchToken = 0;

  double get _containerWidth {
    final width = mediaSize.width * 0.9;
    return width > 599 ? 600 : width;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activePlan = ref.read(planProvider)!;

    return Scaffold(
      appBar: MainAppBar(
        text: context.tr('meal_select_title'),
        scrollController: _scrollController,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            foodly_search_bar.SearchBar(
              onSearch: _onSearchEvent,
              hintText: context.tr('meal_select_search_hint'),
            ),
            if (searchedMeals.isEmpty && _libraryMeals.isNotEmpty)
              _buildLibraryMeals(activePlan.id!),
            if (searchedMeals.isEmpty && _lastQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: kPadding / 2),
                child: TextButton.icon(
                  onPressed: _createFromSheet,
                  icon: Icon(Icons.auto_awesome, color: theme.primaryColor),
                  label: Text(
                    context.tr('search_create_ai', args: [_lastQuery]),
                    style: TextStyle(color: theme.primaryColor),
                  ),
                ),
              ),
            Consumer(builder: (context, ref, _) {
              final isSearching = ref.watch(_$isSearching);

              if (isSearching) {
                return _buildLoader();
              }

              return ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: kPadding),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: searchedMeals.isEmpty
                    ? 4 // there could be a max amount of 4 items if none is found
                    : searchedMeals.length,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: searchedMeals.isEmpty
                            ? _buildNoResultsForIndex(index, activePlan.id!)
                            : SelectMealTile(
                                meal: searchedMeals[index],
                                onAddMeal: () => _addMealToPlan(
                                  searchedMeals[index].id!,
                                  activePlan.id!,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryMeals(String planId) {
    return Column(
      children: [
        _buildSizeWrapper(
          padding: const EdgeInsets.only(top: kPadding),
          child: Text(
            context.tr('meal_select_from_library'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        for (final dish in _libraryMeals)
          SelectMealTile(
            key: ValueKey('library-${dish.id}'),
            meal: dish.toPreviewMeal(),
            onTap: () => AutoRouter.of(context).push(
              LibraryMealScreenRoute(id: dish.id, entry: 'meal_select'),
            ),
            onAddMeal: () => _addLibraryMealToPlan(dish, planId),
          ),
      ],
    );
  }

  /// Imports the dish (once) and adds the plan's copy to this day. False if
  /// the import failed, so the tile doesn't report success.
  Future<bool> _addLibraryMealToPlan(LibraryMeal dish, String planId) async {
    final mealId = dish.importedMealId ??
        (await importFromLibrary(context, [dish.id], entry: 'meal_select'))
            ?.meals
            .firstOrNull
            ?.id;
    if (mealId == null) {
      return false;
    }
    await _addMealToPlan(mealId, planId);
    return true;
  }

  /// A few library dishes for [query]; empty on failure.
  Future<List<LibraryMeal>> _searchLibrary(String query) async {
    final page = await LunixApiService.searchLibrary(
      lang: libraryLang(context.locale.languageCode),
      planId: ref.read(planProvider)!.id,
      filter: LibraryFilter(query: query),
      limit: 5,
    );
    return page?.items ?? [];
  }

  Widget _buildLoader() {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: kPadding),
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(6, (_) => const MealListTile(null)),
    );
  }

  Widget _buildNoResultsForIndex(int index, String planId) {
    if (index == 0) {
      return _buildContainer(
        Icons.restaurant_outlined,
        context.tr('meal_select_placeholder'),
        () => _showPlaceholderDialog(ref),
      );
    } else if (index == 1) {
      return _buildContainer(
        EvaIcons.plus,
        context.tr('meal_select_new'),
        _createFromSheet,
      );
    } else if (index == 2) {
      return Consumer(builder: (context, ref, _) {
        final AsyncValue<Meal?> randomMeal = ref.watch(_$randomMeal);

        if (randomMeal.isLoading) {
          // handle loading before `when`, because it skips the load state
          // if it has been too fast
          return const SelectMealTile(
            isLoading: true,
          );
        }

        return randomMeal.when(
          data: (value) => value != null
              ? SelectMealTile(
                  meal: value,
                  onAddMeal: () => _addMealToPlan(value.id!, planId),
                  secondaryAction: () => ref.invalidate(_$randomMeal),
                )
              : const SizedBox(),
          error: (_, __) => const SizedBox(),
          loading: () => const SelectMealTile(
            isLoading: true,
          ),
        );
      });
    }
    return ref.read(_$isSearching)
        ? UserInformation(
            assetPath: 'assets/images/undraw_empty.png',
            title: context.tr('meal_select_no_results'),
            message: context.tr('meal_select_no_results_msg'),
          )
        : Consumer(builder: (context, ref, _) {
            final cookbookEmpty = ref.watch(_$cookbookEmpty);
            // Nothing until known, so neither block flashes in first.
            if (!cookbookEmpty.hasValue && !cookbookEmpty.hasError) {
              return const SizedBox.shrink();
            }
            if (cookbookEmpty.valueOrNull ?? false) {
              return _buildStarter();
            }
            final userIsSubscribed =
                ref.watch(InAppPurchaseService.$userIsSubscribed);
            return !userIsSubscribed
                ? _buildGetPremiumInfo()
                : SettingsService.showSuggestions
                    ? _buildPreviewMeals()
                    : _buildPaginatedMealList();
          });
  }

  /// Empty cookbook: the starter questions instead of suggestions, so a new
  /// plan gets dishes before the first one is picked.
  Widget _buildStarter() {
    return _buildSizeWrapper(
      padding: const EdgeInsets.only(top: kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('meal_list_empty_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: kPadding / 2),
          Text(context.tr('meal_list_empty_subtitle')),
          const SizedBox(height: kPadding),
          LibraryStarterQuestions(
            onSubmit: (answers) async {
              await AutoRouter.of(context).push(LibraryScreenRoute(
                starter: answers,
                entry: 'meal_select_empty',
              ));
              if (mounted) {
                ref.invalidate(_$cookbookEmpty);
                ref.invalidate(_$randomMeal);
              }
            },
          ),
          const SizedBox(height: kPadding * 2),
        ],
      ),
    );
  }

  Widget _buildSizeWrapper({required Widget child, EdgeInsets? padding}) {
    return Align(
      child: Container(
        width: _containerWidth,
        padding: padding,
        child: child,
      ),
    );
  }

  Widget _buildPreviewMeals() {
    final planId = ref.read(planProvider)!.id!;
    return FutureBuilder<List<Meal>>(
      future: MealStatService.getMealRecommendations(planId),
      builder: (context, snapshot) {
        final meals = snapshot.hasData ? snapshot.data! : <Meal>[];

        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: kPadding),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: meals.isEmpty
              ? 0
              : meals.length +
                  1, // +1 to make space for title and 0 to not show title
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildSizeWrapper(
                padding: const EdgeInsets.symmetric(
                  vertical: kPadding / 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('meal_select_recommendations'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _showRecommendationsInfo,
                      icon: Icon(
                        EvaIcons.infoOutline,
                        color: theme.textTheme.bodyLarge?.color ??
                            theme.primaryColor,
                      ),
                      splashRadius: 25.0,
                    ),
                  ],
                ),
              );
            }
            index--;
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: SelectMealTile(
                    meal: meals[index],
                    onAddMeal: () => _addMealToPlan(meals[index].id!, planId),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaginatedMealList() {
    final planId = ref.read(planProvider)!.id!;
    return MealPagination(
      loadNextMeals: (lastDoc) => MealService.getMealsPaginated(
        planId,
        lastDocument: lastDoc,
      ),
      buildMeal: (meal) => SelectMealTile(
        meal: meal,
        onAddMeal: () => _addMealToPlan(meal.id!, planId),
      ),
      scrollController: _scrollController,
    );
  }

  Widget _buildGetPremiumInfo() {
    return _buildSizeWrapper(
      padding: const EdgeInsets.symmetric(
        vertical: kPadding / 2,
      ),
      child: GetPremiumInfo(
        title: context.tr('get_premium_modal_2_title'),
        description: context.tr('get_premium_modal_2_description_ad'),
        source: 'meal_suggestions',
        highlight: PremiumFeature.suggestions,
      ),
    );
  }

  Widget _buildContainer(IconData iconData, String text, Function action) {
    const double height = 75.0;
    final onTap = action as void Function()?;
    return Align(
      // ignore: avoid_redundant_argument_values
      alignment: Alignment.center,
      child: Container(
        width: _containerWidth,
        // At least [height]; taller when large text wraps the label.
        constraints: const BoxConstraints(minHeight: height),
        margin: const EdgeInsets.symmetric(vertical: kPadding / 2),
        decoration: BoxDecoration(
          boxShadow: const [kSmallShadow],
          borderRadius: BorderRadius.circular(kRadius),
        ),
        // The whole row is the button, not only the arrow.
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Row(
              children: [
                SizedBox(
                  width: height,
                  child: Icon(iconData),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15.0,
                      vertical: kPadding / 2,
                    ),
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: height / 2,
                  width: height / 2,
                  margin: const EdgeInsets.only(right: 20.0),
                  // The row already is the button for screen readers.
                  child: ExcludeSemantics(
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: ButtonStyle(
                        padding: WidgetStateProperty.resolveWith(
                            (states) => EdgeInsets.zero),
                      ),
                      child: const Icon(
                        EvaIcons.arrowIosForwardOutline,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onSearchEvent(String query) async {
    final token = ++_searchToken;
    if (query.isNotEmpty && query.length > 2) {
      // The old query's "create with AI" button must not stay while loading.
      setState(() => _lastQuery = '');
      ref.read(_$isSearching.notifier).state = true;
      final meals = await _searchMeal(ref, query);
      final libraryMeals = meals.isEmpty && mounted
          ? await _searchLibrary(query)
          : <LibraryMeal>[];
      if (!mounted || token != _searchToken) {
        return;
      }
      // The library section is built outside the isSearching Consumer.
      setState(() {
        searchedMeals = meals;
        _libraryMeals = libraryMeals;
        _lastQuery = query;
      });
      ref.read(_$isSearching.notifier).state = false;
      logEvent(AnalyticsEvent.searchMealSelect, {
        'query_length': '${query.length}',
        'has_results': '${searchedMeals.isNotEmpty}',
      });
    } else {
      searchedMeals = [];
      _libraryMeals = [];
      _lastQuery = '';
      ref.read(_$isSearching.notifier).state = false;
      setState(() {});
    }
  }

  Future<void> _showPlaceholderDialog(WidgetRef ref) async {
    final planId = ref.read(planProvider)!.id!;
    final text = await WidgetUtils.showPlaceholderEditDialog(context);

    if (text == null || text.isEmpty) {
      return;
    }

    await _addMealToPlan(
      kPlaceholderSymbol + text,
      planId,
    );
    if (!mounted) {
      return;
    }
    AutoRouter.of(context).pop();
  }

  /// The add-dish sheet (prefilled with the search query); a dish created
  /// there fills this slot.
  Future<void> _createFromSheet() async {
    final planId = ref.read(planProvider)!.id!;
    final meal = await showAddDishSheet(
      context,
      ref,
      initialText: _lastQuery,
      returnsMeal: true,
    );
    if (meal?.id == null || !mounted) {
      return;
    }
    await _addMealToPlan(meal!.id!, planId);
    if (!mounted) {
      return;
    }
    AutoRouter.of(context).pop();
  }

  Future<void> _addMealToPlan(String mealId, String planId) async {
    await PlanService.addPlanMealToPlan(
      planId,
      PlanMeal(
        date: widget.date,
        meal: mealId,
        type: widget.mealType,
      ),
    );
    _logAnalyticsEvent(mealId.startsWith(kPlaceholderSymbol));
  }

  void _logAnalyticsEvent(bool isPlaceholder) {
    logEvent(AnalyticsEvent.addMealToPlan, {
      'isPlaceholder': isPlaceholder.toString(),
      'source': 'meal_select',
    });
  }

  Future<List<Meal>> _searchMeal(WidgetRef ref, String query) {
    return LunixApiService.searchMeals(
      ref.read(planProvider)!.id!,
      query,
    );
  }

  Future<dynamic> _showRecommendationsInfo() {
    return MainSnackbar(
      message: context.tr('meal_select_recommendations_info'),
      infinite: true,
    ).show(context);
  }
}
