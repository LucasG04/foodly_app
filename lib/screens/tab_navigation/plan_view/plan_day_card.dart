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
    final breakfastList = meals.where((e) => e.type == MealType.BREAKFAST);
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
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEEE', context.locale.toLanguageTag())
                          .format(date),
                      style: kCardTitle,
                    ),
                    Text(
                      DateFormat('d. MMMM y', context.locale.toLanguageTag())
                          .format(date),
                      style: kCardSubtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kPadding),
              StreamBuilder<bool>(
                initialData: SettingsService.planWithBreakfast,
                stream: SettingsService.streamPlanWithBreakfast(),
                builder: (context, snapshot) {
                  if (snapshot.data != null && snapshot.data!) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSubtitle('plan_day_breakfast'.tr()),
                        ...breakfastList
                            .map((e) => PlanDayMealTile(
                                  e,
                                  enableVoting: breakfastList.length > 1,
                                ))
                            .toList(),
                        _buildAddButton(
                          context,
                          mealType: MealType.BREAKFAST,
                          mealsAtTime: breakfastList.length,
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Divider(),
                        ),
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
              _buildSubtitle('plan_day_lunch'.tr()),
              ...lunchList
                  .map((e) => PlanDayMealTile(
                        e,
                        enableVoting: lunchList.length > 1,
                      ))
                  .toList(),
              _buildAddButton(
                context,
                mealType: MealType.LUNCH,
                mealsAtTime: lunchList.length,
              ),
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
              _buildAddButton(
                context,
                mealType: MealType.DINNER,
                mealsAtTime: dinnerList.length,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(
    BuildContext context, {
    required MealType mealType,
    required int mealsAtTime,
  }) {
    return StreamBuilder<dynamic>(
      stream: SettingsService.streamMultipleMealsPerTime(),
      builder: (context, _) {
        return _showAddButton(context, mealsAtTime)
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: OutlinedButton(
                    onPressed: () => AutoRouter.of(context).push(
                      MealSelectScreenRoute(date: date, mealType: mealType),
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
              )
            : const SizedBox();
      },
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

  bool _showAddButton(BuildContext context, int mealsAtTime) {
    return mealsAtTime < 1 || SettingsService.multipleMealsPerTime;
  }
}
