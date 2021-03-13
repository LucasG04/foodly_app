import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:auto_route/auto_route.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:foodly/app_router.gr.dart';
import 'package:foodly/screens/meal_select/search_bar.dart';
import 'package:foodly/screens/meal_select/select_meal_tile.dart';
import 'package:foodly/widgets/main_appbar.dart';
import 'package:foodly/widgets/user_information.dart';
import '../../constants.dart';
import '../../models/meal.dart';
import '../../models/plan_meal.dart';
import '../../providers/state_providers.dart';
import '../../services/plan_service.dart';

class MealSelectScreen extends StatefulWidget {
  /// both are strings because the need to be extracted from the url
  /// for better usage this widgets contains two getters: `date` & `isLunch`
  final String dateString;

  final String isLunchString;

  MealSelectScreen({
    @QueryParam('date') this.dateString,
    @QueryParam('isLunch') this.isLunchString,
  });

  @override
  _MealSelectScreenState createState() => _MealSelectScreenState();
}

class _MealSelectScreenState extends State<MealSelectScreen> {
  List<Meal> searchedMeals;
  bool _isSearching;

  ScrollController _scrollController;

  @override
  void initState() {
    searchedMeals = [];
    _isSearching = false;
    _scrollController = new ScrollController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final activePlan = context.read(planProvider).state;

    return Scaffold(
      appBar: MainAppBar(text: 'Hinzufügen'),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            SearchBar(
              onSearch: (String query) async {
                if (query.isNotEmpty && query.length > 1) {
                  setState(() {
                    _isSearching = true;
                    searchedMeals = _searchForMeal(
                        context.read(allMealsProvider).state, query);
                  });
                } else {
                  setState(() {
                    _isSearching = false;
                    searchedMeals = [];
                  });
                }
              },
            ),
            AnimationLimiter(
              key: UniqueKey(),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: kPadding),
                physics: NeverScrollableScrollPhysics(),
                itemCount: searchedMeals.length == 0 ? 3 : searchedMeals.length,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: (searchedMeals.length == 0)
                            ? _buildNoResultsForIndex(index)
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

  DateTime get date =>
      new DateTime.fromMillisecondsSinceEpoch(int.parse(widget.dateString));

  bool get isLunch => widget.isLunchString == 'true';

  Widget _buildNoResultsForIndex(int index) {
    return (index == 0)
        ? _buildContainer(
            EvaIcons.codeOutline,
            'Platzhalter eintragen',
            () => _showPlaceholderDialog(),
          )
        : (index == 1)
            ? _buildContainer(
                EvaIcons.plusOutline,
                'Neues Gericht erstellen',
                () => _createNewMeal(),
              )
            : _isSearching
                ? UserInformation(
                    'assets/images/undraw_empty.png',
                    'Keine Ergebnisse.',
                    'Wir konnten keine Gerichte für deine Suche finden.',
                  )
                : SizedBox();
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
          validator: (value) =>
              value.isEmpty ? 'Bitte trag einen Platzhalter ein.' : null,
        ),
      ],
      title: 'Platzhalter',
      cancelLabel: 'ABBRECHEN',
    );

    if (texts != null && texts.isNotEmpty) {
      await _addMealToPlan(
        kPlaceholderSymbol + texts.first,
        context.read(planProvider).state.id,
      );
      ExtendedNavigator.root.pop();
    }
  }

  Future _createNewMeal() async {
    final meal = await ExtendedNavigator.root
        .push(Routes.mealCreateScreen(id: 'create'));

    if (meal != null && meal is Meal) {
      await _addMealToPlan(meal.id, context.read(planProvider).state.id);
      ExtendedNavigator.root.pop();
    }
  }

  Future _addMealToPlan(String mealId, String planId) {
    return PlanService.addPlanMealToPlan(
      planId,
      new PlanMeal(
        date: date,
        meal: mealId,
        type: isLunch ? MealType.LUNCH : MealType.DINNER,
        upvotes: [],
        downvotes: [],
      ),
    );
  }

  List<Meal> _searchForMeal(List<Meal> meals, String query) {
    return meals
        .where((meal) => meal.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
