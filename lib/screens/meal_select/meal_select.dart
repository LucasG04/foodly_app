import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:foodly/services/meal_stat_service.dart';
import 'package:foodly/services/settings_service.dart';

import '../../app_router.gr.dart';
import '../../constants.dart';
import '../../models/meal.dart';
import '../../models/plan_meal.dart';
import '../../providers/state_providers.dart';
import '../../services/plan_service.dart';
import '../../widgets/main_appbar.dart';
import '../../widgets/user_information.dart';
import 'search_bar.dart';
import 'select_meal_tile.dart';

class MealSelectScreen extends StatefulWidget {
  final DateTime date;

  final bool isLunch;

  MealSelectScreen({
    this.date,
    this.isLunch,
  });

  @override
  _MealSelectScreenState createState() => _MealSelectScreenState();
}

class _MealSelectScreenState extends State<MealSelectScreen> {
  List<Meal> searchedMeals;
  bool _isSearching;

  ScrollController _scrollController;
  Key _animationLimiterKey;

  @override
  void initState() {
    searchedMeals = [];
    _isSearching = false;
    _scrollController = new ScrollController();
    _animationLimiterKey = UniqueKey();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final activePlan = context.read(planProvider).state;

    return Scaffold(
      appBar: MainAppBar(text: 'meal_select_title'.tr()),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            SearchBar(
              onSearch: (String query) async {
                if (query.isNotEmpty && query.length > 1) {
                  setState(() {
                    _animationLimiterKey = UniqueKey();
                    _isSearching = true;
                    searchedMeals = _searchForMeal(
                        context.read(allMealsProvider).state, query);
                  });
                } else {
                  setState(() {
                    if (_isSearching == true) {
                      _animationLimiterKey = UniqueKey();
                    }
                    _isSearching = false;
                    searchedMeals = [];
                  });
                }
              },
            ),
            AnimationLimiter(
              key: _animationLimiterKey,
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: kPadding),
                physics: NeverScrollableScrollPhysics(),
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
                            ? _buildNoResultsForIndex(index, activePlan.id)
                            : SelectMealTile(
                                meal: searchedMeals[index],
                                onAddMeal: () => _addMealToPlan(
                                  searchedMeals[index].id,
                                  activePlan.id,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsForIndex(int index, String planId) {
    return (index == 0)
        ? _buildContainer(
            EvaIcons.codeOutline,
            'meal_select_placeholder'.tr(),
            () => _showPlaceholderDialog(),
          )
        : (index == 1)
            ? _buildContainer(
                EvaIcons.plusOutline,
                'meal_select_new'.tr(),
                () => _createNewMeal(),
              )
            : _isSearching
                ? UserInformation(
                    'assets/images/undraw_empty.png',
                    'meal_select_no_results'.tr(),
                    'meal_select_no_results_msg'.tr(),
                  )
                : SettingsService.showSuggestions
                    ? _buildPreviewMeals(planId)
                    : SizedBox();
  }

  Widget _buildPreviewMeals(String planId) {
    return FutureBuilder<List<Meal>>(
      future: MealStatService.getMealRecommendations(planId),
      builder: (context, snapshot) {
        final meals = snapshot.hasData ? snapshot.data : [];

        return AnimationLimiter(
          key: _animationLimiterKey,
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: kPadding),
            physics: NeverScrollableScrollPhysics(),
            itemCount: meals.length == 0
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
                  child: Text(
                    'meal_select_recommondations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.start,
                  ).tr(),
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
                      onAddMeal: () => _addMealToPlan(meals[index].id, planId),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildContainer(IconData iconData, String text, Function action) {
    double _height = 75.0;
    double _width = MediaQuery.of(context).size.width * 0.9;
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: _width > 599 ? 600 : _width,
        height: _height,
        margin: const EdgeInsets.symmetric(vertical: kPadding / 2),
        decoration: BoxDecoration(
          boxShadow: [kSmallShadow],
          borderRadius: BorderRadius.circular(kRadius),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              height: _height,
              width: _height,
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
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: _height / 2,
              width: _height / 2,
              margin: const EdgeInsets.only(right: 20.0),
              child: OutlinedButton(
                onPressed: action,
                child:
                    Icon(EvaIcons.arrowIosForwardOutline, color: Colors.black),
                style: ButtonStyle(
                  padding: MaterialStateProperty.resolveWith(
                      (states) => const EdgeInsets.all(0)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future _showPlaceholderDialog() async {
    final texts = await showTextInputDialog(
      context: context,
      textFields: [
        DialogTextField(
          validator: (value) => value.isEmpty
              ? 'meal_select_placeholder_dialog_placeholder'.tr()
              : null,
        ),
      ],
      title: 'meal_select_placeholder_dialog_title'.tr(),
      cancelLabel: 'meal_select_placeholder_dialog_cancel'.tr(),
    );

    if (texts != null && texts.isNotEmpty) {
      await _addMealToPlan(
        kPlaceholderSymbol + texts.first,
        context.read(planProvider).state.id,
      );
      context.router.pop();
    }
  }

  Future _createNewMeal() async {
    final meal = await context.router.push(MealCreateScreenRoute(id: 'create'));

    if (meal != null && meal is Meal) {
      await _addMealToPlan(meal.id, context.read(planProvider).state.id);
      context.router.pop();
    }
  }

  Future _addMealToPlan(String mealId, String planId) {
    return PlanService.addPlanMealToPlan(
      planId,
      new PlanMeal(
        date: widget.date,
        meal: mealId,
        type: widget.isLunch ? MealType.LUNCH : MealType.DINNER,
        upvotes: [],
        downvotes: [],
      ),
    );
  }

  List<Meal> _searchForMeal(List<Meal> meals, String query) {
    return meals
        .where(
          (meal) =>
              meal.name.toLowerCase().contains(query.toLowerCase()) ||
              meal.tags
                  .any((t) => t.toLowerCase().contains(query.toLowerCase())),
        )
        .toList();
  }
}
