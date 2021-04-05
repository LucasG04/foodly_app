import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app_router.gr.dart';
import '../../../constants.dart';
import '../../../models/plan_meal.dart';
import 'plan_day_meal_tile.dart';

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
          padding: const EdgeInsets.all(kPadding),
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
              SizedBox(height: kPadding),
              _buildSubtitle('Mittag'),
              ...lunchList
                  .map((e) => PlanDayMealTile(e, lunchList.length > 1))
                  .toList(),
              _buildAddButton(context, isLunch: true),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Divider(),
              ),
              _buildSubtitle('Abend'),
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
        child: OutlinedButton(
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
          style: ButtonStyle(
            padding: MaterialStateProperty.resolveWith(
              (_) => const EdgeInsets.all(15.0),
            ),
            side: MaterialStateProperty.resolveWith(
              (_) => BorderSide(width: 0.0),
            ),
            foregroundColor: MaterialStateProperty.resolveWith(
              (_) => Theme.of(context).primaryColor,
            ),
            shape: MaterialStateProperty.resolveWith(
              (_) => RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadius / 2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0, left: kPadding / 2),
      child: Text(
        text.toString().toUpperCase(),
        style: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
