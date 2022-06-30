import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../app_router.gr.dart';
import '../../constants.dart';
import '../../models/meal.dart';
import '../../models/plan_meal.dart';
import '../../providers/state_providers.dart';
import '../../services/lunix_api_service.dart';
import '../../services/meal_service.dart';
import '../../services/meal_stat_service.dart';
import '../../services/plan_service.dart';
import '../../services/settings_service.dart';
import '../../utils/main_snackbar.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/main_appbar.dart';
import '../../widgets/meal_pagination.dart';
import '../../widgets/user_information.dart';
import '../tab_navigation/meal_list_view/meal_list_tile.dart';
import 'search_bar.dart';
import 'select_meal_tile.dart';

class MealSelectScreen extends StatefulWidget {
  final DateTime date;
  final bool isLunch;

  const MealSelectScreen({required this.date, required this.isLunch, Key? key})
      : super(key: key);

  @override
  State<MealSelectScreen> createState() => _MealSelectScreenState();
}

class _MealSelectScreenState extends State<MealSelectScreen> {
  late AutoDisposeStateProvider<bool> _$isSearching;

  final ScrollController _scrollController = ScrollController();

  List<Meal> searchedMeals = [];

  @override
  void initState() {
    _$isSearching = StateProvider.autoDispose<bool>((_) => false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final activePlan = context.read(planProvider).state!;

    return Scaffold(
      appBar: MainAppBar(
        text: 'meal_select_title'.tr(),
        scrollController: _scrollController,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            SearchBar(
              onSearch: _onSearchEvent,
            ),
            Consumer(builder: (context, watch, _) {
              final isSearching = watch(_$isSearching).state;

              if (isSearching) {
                return _buildLoader();
              }

              return ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: kPadding),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: searchedMeals.isEmpty
                    ? 3 // there could be a max amount of 3 items if none is found
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

  Widget _buildLoader() {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: kPadding),
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(6, (_) => const MealListTile(null)),
    );
  }

  Widget _buildNoResultsForIndex(int index, String planId) {
    return (index == 0)
        ? _buildContainer(
            EvaIcons.code,
            'meal_select_placeholder'.tr(),
            () => _showPlaceholderDialog(),
          )
        : (index == 1)
            ? _buildContainer(
                EvaIcons.plus,
                'meal_select_new'.tr(),
                () => _createNewMeal(),
              )
            : context.read(_$isSearching).state
                ? UserInformation(
                    assetPath: 'assets/images/undraw_empty.png',
                    title: 'meal_select_no_results'.tr(),
                    message: 'meal_select_no_results_msg'.tr(),
                  )
                : SettingsService.showSuggestions
                    ? _buildPreviewMeals()
                    : _buildPaginatedMealList();
  }

  Widget _buildPreviewMeals() {
    final planId = context.read(planProvider).state!.id!;
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
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kPadding,
                  vertical: kPadding / 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'meal_select_recommendations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ).tr(),
                    IconButton(
                      onPressed: _showRecommendationsInfo,
                      icon: Icon(
                        EvaIcons.infoOutline,
                        color: Theme.of(context).textTheme.bodyText1?.color ??
                            Theme.of(context).primaryColor,
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
    final planId = context.read(planProvider).state!.id!;
    return MealPagination(
      loadNextMeals: (lastMealId) => MealService.getMealsPaginated(
        planId,
        lastMealId: lastMealId,
      ),
      buildMeal: (meal) => SelectMealTile(
        meal: meal,
        onAddMeal: () => _addMealToPlan(meal.id!, planId),
      ),
      scrollController: _scrollController,
    );
  }

  Widget _buildContainer(IconData iconData, String text, Function action) {
    const double height = 75.0;
    final double width = MediaQuery.of(context).size.width * 0.9;
    return Align(
      // ignore: avoid_redundant_argument_values
      alignment: Alignment.center,
      child: Container(
        width: width > 599 ? 600 : width,
        height: height,
        margin: const EdgeInsets.symmetric(vertical: kPadding / 2),
        decoration: BoxDecoration(
          boxShadow: const [kSmallShadow],
          borderRadius: BorderRadius.circular(kRadius),
          color: Colors.white,
        ),
        child: Row(
          children: [
            SizedBox(
              height: height,
              width: height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(kRadius),
                child: Icon(iconData),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: height / 2,
              width: height / 2,
              margin: const EdgeInsets.only(right: 20.0),
              child: OutlinedButton(
                onPressed: action as void Function()?,
                style: ButtonStyle(
                  padding: MaterialStateProperty.resolveWith(
                      (states) => EdgeInsets.zero),
                ),
                child: const Icon(EvaIcons.arrowIosForwardOutline,
                    color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchEvent(String query) async {
    if (query.isNotEmpty && query.length > 2) {
      context.read(_$isSearching).state = true;
      searchedMeals = await _searchMeal(query);
      if (!mounted) {
        return;
      }
      context.read(_$isSearching).state = false;
    } else {
      if (context.read(_$isSearching).state) {}
      searchedMeals = [];
      context.read(_$isSearching).state = false;
      setState(() {});
    }
  }

  Future<void> _showPlaceholderDialog() async {
    final planId = context.read(planProvider).state!.id!;
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

  Future<void> _createNewMeal() async {
    final planId = context.read(planProvider).state!.id!;
    final meal =
        await AutoRouter.of(context).push(MealCreateScreenRoute(id: 'create'));

    if (meal != null && meal is Meal) {
      await _addMealToPlan(meal.id!, planId);
      if (!mounted) {
        return;
      }
      AutoRouter.of(context).pop();
    }
  }

  Future<void> _addMealToPlan(String mealId, String planId) {
    return PlanService.addPlanMealToPlan(
      planId,
      PlanMeal(
        date: widget.date,
        meal: mealId,
        type: widget.isLunch ? MealType.LUNCH : MealType.DINNER,
        upvotes: [],
        downvotes: [],
      ),
    );
  }

  Future<List<Meal>> _searchMeal(String query) {
    return LunixApiService.searchMeals(
      context.read(planProvider).state!.id!,
      query,
    );
  }

  Future<dynamic> _showRecommendationsInfo() {
    return MainSnackbar(
      message: 'meal_select_recommendations_info'.tr(),
      infinite: true,
    ).show(context);
  }
}
