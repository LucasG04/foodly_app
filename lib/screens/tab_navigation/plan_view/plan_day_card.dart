import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../app_router.gr.dart';

import '../../../constants.dart';
import '../../../models/plan_meal.dart';
import '../../../services/settings_service.dart';
import 'plan_day_meal_tile.dart';

class PlanDayCard extends StatelessWidget {
  final DateTime date;
  final List<PlanMeal> meals;

  const PlanDayCard({
    Key? key,
    required this.date,
    required this.meals,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final lunchList = meals.where((e) => e.type == MealType.LUNCH);
    final dinnerList = meals.where((e) => e.type == MealType.DINNER);

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
                  DateFormat('EEEE', context.locale.toLanguageTag())
                      .format(date),
                  style: kCardTitle,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  DateFormat('d. MMMM y', context.locale.toLanguageTag())
                      .format(date),
                  style: kCardSubtitle,
                ),
              ),
              const SizedBox(height: kPadding),
              _buildSubtitle('plan_day_lunch'.tr()),
              ...lunchList
                  .map((e) => PlanDayMealTile(
                        e,
                        enableVoting: lunchList.length > 1,
                      ))
                  .toList(),
              if (_showAddButton(context, lunchList))
                _buildAddButton(context, isLunch: true)
              else
                const SizedBox(),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Divider(),
              ),
              _buildSubtitle('plan_day_dinner'.tr()),
              ...dinnerList
                  .map((e) => PlanDayMealTile(
                        e,
                        enableVoting: dinnerList.length > 1,
                      ))
                  .toList(),
              if (_showAddButton(context, dinnerList))
                _buildAddButton(context, isLunch: false)
              else
                const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }

  bool _showAddButton(BuildContext context, Iterable<dynamic> meals) {
    return meals.isEmpty || SettingsService.multipleMealsPerTime;
  }

  Widget _buildAddButton(BuildContext context, {required bool isLunch}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: OutlinedButton(
          onPressed: () => AutoRouter.of(context).push(
            MealSelectScreenRoute(date: date, isLunch: isLunch),
          ),
          style: ButtonStyle(
            padding: MaterialStateProperty.resolveWith(
              (_) => const EdgeInsets.all(15.0),
            ),
            side: MaterialStateProperty.resolveWith(
              (_) => const BorderSide(width: 0.0),
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
          child: const Text(
            'add',
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ).tr(),
        ),
      ),
    );
  }

  Widget _buildSubtitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0, left: kPadding / 2),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
