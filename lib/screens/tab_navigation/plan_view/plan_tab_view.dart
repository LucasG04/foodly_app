import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../models/meal.dart';

import '../../../constants.dart';
import '../../../models/plan.dart';
import '../../../models/plan_meal.dart';
import '../../../providers/state_providers.dart';
import '../../../services/plan_service.dart';
import '../../../widgets/page_title.dart';
import 'plan_day_card.dart';

class PlanTabView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final activePlan = watch(planProvider).state;

    return activePlan != null
        ? StreamBuilder(
            stream: PlanService.streamPlanById(activePlan.id),
            initialData: activePlan,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final plan = snapshot.data as Plan;
                final days = _getMealsForDays(plan);

                return SingleChildScrollView(
                  child: AnimationLimiter(
                    child: Column(
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 250),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          SizedBox(height: kPadding),
                          Padding(
                            padding: const EdgeInsets.only(left: 5.0),
                            child: PageTitle(text: 'Essensplan'),
                          ),
                          ...days
                              .map(
                                (e) => PlanDayCard(
                                  date: e.date,
                                  meals: e.meals,
                                ),
                              )
                              .toList()
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          )
        : Center(child: CircularProgressIndicator());
  }

  List<PlanDay> _getMealsForDays(Plan plan) {
    final List<PlanDay> result = [];
    final updatedMeals = [...plan.meals];

    final now =
        new DateTime.now().toUtc().add(Duration(days: plan.hourDiffToUtc));
    final today = new DateTime(now.year, now.month, now.day - 1);

    // DateTime firstDate = meals.first.date;

    // remove old plan days
    for (var meal in plan.meals) {
      if (meal.date.isBefore(today)) {
        updatedMeals.remove(meal);
      }
    }

    if (plan.meals != updatedMeals) {
      plan.meals = updatedMeals;
      PlanService.updatePlan(plan);
    }

    for (var i = 0; i < 8; i++) {
      final date = today.add(Duration(days: i));
      result.add(
        PlanDay(date, [
          ...updatedMeals.where((element) => element.date == date).toList()
        ]),
      );
    }

    return result;
  }
}

class PlanDay {
  DateTime date;
  List<PlanMeal> meals;

  PlanDay(this.date, this.meals);
}
