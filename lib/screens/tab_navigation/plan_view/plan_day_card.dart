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
  final bool readonly;

  const PlanDayCard({
    super.key,
    required this.date,
    required this.meals,
    this.readonly = false,
  });

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
        surfaceTintColor: Colors.white,
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
                    const SizedBox(width: kPadding / 2),
                    Flexible(
                      child: Text(
                        DateFormat(
                          'd. MMMM y',
                          context.locale.toLanguageTag(),
                        ).format(date),
                        style: kCardSubtitle,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kPadding),
              _buildMealView(
                title: 'plan_day_breakfast'.tr(),
                mealType: MealType.BREAKFAST,
                list: breakfastList,
                context: context,
              ),
              _buildMealView(
                title: 'plan_day_lunch'.tr(),
                mealType: MealType.LUNCH,
                list: lunchList,
                context: context,
              ),
              _buildMealView(
                title: 'plan_day_dinner'.tr(),
                mealType: MealType.DINNER,
                list: dinnerList,
                context: context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealView({
    required String title,
    required MealType mealType,
    required Iterable<PlanMeal> list,
    required BuildContext context,
  }) {
    return StreamBuilder<List<MealType>>(
      initialData: SettingsService.activeMealTypes,
      stream: SettingsService.streamActiveMealTypes(),
      builder: (context, snapshot) {
        final isActive = snapshot.data?.contains(mealType) ?? false;
        if (!_showMealView(isActive, list.isEmpty)) {
          return const SizedBox();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSubtitle(title),
            ...list
                .map(
                  (e) => PlanDayMealTile(
                    e,
                    readonly: readonly,
                    enableVoting: list.length > 1 && !readonly,
                  ),
                )
                ,
            _buildAddButton(
              context,
              mealType: mealType,
              mealsAtTime: list.length,
            ),
            if (_shouldAddDivider(mealType))
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Divider(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAddButton(
    BuildContext context, {
    required MealType mealType,
    required int mealsAtTime,
  }) {
    if (readonly) {
      return mealsAtTime > 0
          ? const SizedBox()
          : const Center(
              child: Text(
                '-',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            );
    }
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
                      padding: WidgetStateProperty.resolveWith(
                        (_) => const EdgeInsets.all(15.0),
                      ),
                      side: WidgetStateProperty.resolveWith(
                        (_) => const BorderSide(width: 0.0),
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (_) => Theme.of(context).primaryColor,
                      ),
                      shape: WidgetStateProperty.resolveWith(
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

  bool _showMealView(bool? settingEnabled, bool listIsEmpty) {
    return (readonly && !listIsEmpty) ||
        (!readonly && settingEnabled != null && settingEnabled);
  }

  bool _shouldAddDivider(MealType mealType) {
    final currentTypes = SettingsService.activeMealTypes;
    final forBreakfast = mealType == MealType.BREAKFAST &&
        (currentTypes.contains(MealType.LUNCH) ||
            currentTypes.contains(MealType.DINNER));
    final forLunch =
        mealType == MealType.LUNCH && currentTypes.contains(MealType.DINNER);
    return forBreakfast || forLunch;
  }
}
