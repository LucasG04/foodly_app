import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:foodly/app_router.gr.dart';
import 'package:foodly/constants.dart';
import 'package:foodly/models/plan_meal.dart';
import 'package:foodly/screens/tab_navigation/plan_view/plan_day_meal_tile.dart';
import 'package:intl/intl.dart';

class PlanDayCard extends StatelessWidget {
  final DateTime date;
  final List<PlanMeal> meals;

  const PlanDayCard({
    Key key,
    @required this.date,
    @required this.meals,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final lunchList = this.meals.where((e) => e.type == MealType.LUNCH);
    final dinnerList = this.meals.where((e) => e.type == MealType.DINNER);

    return Container(
      width: width > 599 ? 600 : width * 0.9,
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  DateFormat('EEEE', 'de_DE').format(date),
                  style: kCardTitle,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  DateFormat('d. MMMM y', 'de_DE').format(date),
                  style: kCardSubtitle,
                ),
              ),
              SizedBox(height: 20.0),
              ...lunchList
                  .map((e) => PlanDayMealTile(e, lunchList.length > 1))
                  .toList(),
              _buildAddButton(context, isLunch: true),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Divider(),
              ),
              ...dinnerList
                  .map((e) => PlanDayMealTile(e, dinnerList.length > 1))
                  .toList(),
              _buildAddButton(context, isLunch: false)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(context, {bool isLunch}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: OutlineButton(
          onPressed: () => ExtendedNavigator.root.push(
            Routes.mealSelectScreen,
            queryParams: {
              'date': date.millisecondsSinceEpoch.toString(),
              'isLunch': isLunch.toString(),
            },
          ),
          child: Text(
            'Hinzufügen',
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          padding: const EdgeInsets.all(15.0),
          borderSide: BorderSide(width: 0.0),
          color: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadius / 2),
          ),
        ),
      ),
    );
  }
}
