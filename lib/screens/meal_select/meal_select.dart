import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:auto_route/auto_route.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';

import '../../constants.dart';
import '../../models/meal.dart';
import '../../models/plan_meal.dart';
import '../../providers/state_providers.dart';
import '../../services/meal_service.dart';
import '../../services/plan_service.dart';
import '../../widgets/page_title.dart';
import '../../widgets/small_circular_progress_indicator.dart';
import 'select_meal_tile.dart';

class MealSelectScreen extends StatelessWidget {
  /// both are strings because the need to be extracted from the url
  /// for better usage this widgets contains two getters: `date` & `isLunch`
  final String dateString;
  final String isLunchString;

  MealSelectScreen({
    @QueryParam('date') this.dateString,
    @QueryParam('isLunch') this.isLunchString,
  });

  @override
  Widget build(BuildContext context) {
    final acitvePlan = context.read(planProvider).state;
    final width = MediaQuery.of(context).size.width;
    final height = 75.0;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: kPadding * 2),
            PageTitle(text: 'Gerichtauswahl', showBackButton: true),
            _buildContainer(
              width,
              height,
              EvaIcons.codeOutline,
              'Platzhalter eintragen',
              () => _showPlaceholderDialog(context),
            ),
            _buildContainer(
              width,
              height,
              EvaIcons.plusOutline,
              'Neues Gericht erstellen',
              () => print('new meal'),
            ),
            FutureBuilder<List<Meal>>(
              future: MealService.getMeals(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data.length,
                    itemBuilder: (context, index) => SelectMealTile(
                      meal: snapshot.data[index],
                      onAddMeal: () => _addMealToPlan(
                        snapshot.data[index].id,
                        acitvePlan.id,
                      ),
                    ),
                  );
                } else {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(kPadding),
                      child: SmallCircularProgressIndicator(),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  DateTime get date =>
      new DateTime.fromMillisecondsSinceEpoch(int.parse(dateString));

  bool get isLunch => isLunchString == 'true';

  Container _buildContainer(double width, double height, IconData iconData,
      String text, Function action) {
    return Container(
      width: width > 599 ? 600 : width * 0.9,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: kPadding / 2),
      decoration: BoxDecoration(
        boxShadow: [kSmallShadow],
        borderRadius: BorderRadius.circular(kRadius),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
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
            height: height / 2,
            width: height / 2,
            margin: const EdgeInsets.only(right: 20.0),
            child: OutlinedButton(
              onPressed: action,
              child: Icon(EvaIcons.arrowIosForwardOutline, color: Colors.black),
              style: ButtonStyle(
                padding: MaterialStateProperty.resolveWith(
                    (states) => const EdgeInsets.all(0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future _showPlaceholderDialog(BuildContext context) async {
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
}
