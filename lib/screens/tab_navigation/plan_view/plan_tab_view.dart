import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../constants.dart';
import '../../../models/plan.dart';
import '../../../models/plan_meal.dart';
import '../../../providers/state_providers.dart';
import '../../../services/plan_service.dart';
import '../../../utils/basic_utils.dart';
import '../../../widgets/page_title.dart';
import '../../../widgets/small_circular_progress_indicator.dart';
import 'plan_day_card.dart';

class PlanTabView extends StatefulWidget {
  @override
  _PlanTabViewState createState() => _PlanTabViewState();
}

class _PlanTabViewState extends State<PlanTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer(
      builder: (context, watch, _) {
        final activePlan = watch(planProvider).state;

        return activePlan != null
            ? SingleChildScrollView(
                child: AnimationLimiter(
                  child: Column(
                    children: [
                      SizedBox(height: kPadding),
                      Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: PageTitle(text: 'Essensplan'),
                      ),
                      SizedBox(
                        width: BasicUtils.contentWidth(context),
                        child: StreamBuilder<List<PlanMeal>>(
                          stream: PlanService.streamPlanMealsByPlanId(
                            activePlan.id,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return ListView(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                children: _getDaysByMeals(snapshot.data)
                                    .map(
                                      (e) => PlanDayCard(
                                        date: e.date,
                                        meals: e.meals,
                                      ),
                                    )
                                    .toList(),
                              );
                            } else {
                              return Center(
                                child: SmallCircularProgressIndicator(),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Center(child: SmallCircularProgressIndicator());
      },
    );
  }

  List<PlanDay> _getDaysByMeals(List<PlanMeal> meals) {
    context.read(planProvider).state.meals = meals;
    return _updateMealsForDays(meals);
  }

  List<PlanDay> _updateMealsForDays(List<PlanMeal> planMeals) {
    final Plan plan = context.read(planProvider).state;
    final List<PlanDay> days = [];
    final List<PlanMeal> updatedMeals = [...planMeals];

    final now =
        new DateTime.now().toUtc().add(Duration(days: plan.hourDiffToUtc));
    final today = new DateTime(now.year, now.month, now.day - 1);

    // remove old plan days
    final oldMeals = planMeals.where((meal) => meal.date.isBefore(today));
    Future.wait(
      oldMeals.map(
        (meal) => PlanService.deletePlanMealFromPlan(plan.id, meal.id),
      ),
    );
    oldMeals.forEach(updatedMeals.remove);

    // update days for the meals
    for (var i = 0; i < 8; i++) {
      final date = today.add(Duration(days: i));
      days.add(
        new PlanDay(date,
            updatedMeals.where((element) => element.date == date).toList()),
      );
      updatedMeals.where((element) => element.date == date).forEach((element) {
        element.date = date;
      });
    }

    // apply updates to firebase collection
    // TODO: does this really check deep equality?
    if (planMeals != updatedMeals) {
      Future.wait(
        updatedMeals.map((e) => PlanService.updatePlanMealFromPlan(plan.id, e)),
      );
    }

    return days;
  }
}

class PlanDay {
  DateTime date;
  List<PlanMeal> meals;

  PlanDay(this.date, this.meals);
}
