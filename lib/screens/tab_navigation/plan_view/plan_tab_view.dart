import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:foodly/models/plan.dart';

import '../../../constants.dart';
import '../../../models/plan_meal.dart';
import '../../../providers/state_providers.dart';
import '../../../services/plan_service.dart';
import '../../../widgets/page_title.dart';
import '../../../widgets/small_circular_progress_indicator.dart';
import 'plan_day_card.dart';

class PlanTabView extends StatefulWidget {
  @override
  _PlanTabViewState createState() => _PlanTabViewState();
}

class _PlanTabViewState extends State<PlanTabView>
    with AutomaticKeepAliveClientMixin {
  List<PlanDay> _planDays = [];
  StreamSubscription<List<PlanMeal>> _planMealsStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _planMealsStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer(
      builder: (context, watch, _) {
        final activePlan = watch(planProvider).state;

        if (_planMealsStream == null && activePlan != null) {
          _planMealsStream = PlanService.streamPlanMealsByPlanId(activePlan.id)
              .listen(_updatePlanMeals);
        }

        return (activePlan != null ||
                (_planMealsStream != null && !_planMealsStream.isPaused))
            ? SingleChildScrollView(
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
                        ..._planDays
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
              )
            : Center(child: SmallCircularProgressIndicator());
      },
    );
  }

  void _updatePlanMeals(List<PlanMeal> meals) async {
    _planMealsStream.pause();
    _planDays = await _updateMealsForDays(meals);
    _planMealsStream.resume();

    final currentPlan = context.read(planProvider).state;
    currentPlan.meals = meals;
    context.read(planProvider).state = currentPlan;
  }

  Future<List<PlanDay>> _updateMealsForDays(List<PlanMeal> planMeals) async {
    final Plan plan = context.read(planProvider).state;
    final List<PlanDay> days = [];
    final List<PlanMeal> updatedMeals = [...planMeals];

    final now =
        new DateTime.now().toUtc().add(Duration(days: plan.hourDiffToUtc));
    final today = new DateTime(now.year, now.month, now.day - 1);

    // remove old plan days
    final oldMeals = planMeals.where((meal) => meal.date.isBefore(today));
    await Future.wait(
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
      await Future.wait(
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
