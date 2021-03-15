import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer(
      builder: (context, watch, _) {
        final activePlan = watch(planProvider).state;
        return activePlan != null
            ? StreamBuilder<List<PlanMeal>>(
                stream: PlanService.streamPlanMealsByPlanId(activePlan.id),
                initialData: activePlan.meals,
                builder: (context, snapshot) {
                  if (snapshot.data != null) {
                    final planMeals = snapshot.data;
                    context.read(planProvider).state.meals = planMeals;
                    final days = _updateMealsForDays(planMeals);

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
                    return Center(child: SmallCircularProgressIndicator());
                  }
                },
              )
            : Center(child: SmallCircularProgressIndicator());
      },
    );
  }

  List<PlanDay> _updateMealsForDays(List<PlanMeal> planMeals) {
    final List<PlanDay> days = [];
    final updatedMeals = [...planMeals];

    final now = new DateTime.now()
        .toUtc()
        .add(Duration(days: context.read(planProvider).state.hourDiffToUtc));
    final today = new DateTime(now.year, now.month, now.day - 1);

    // DateTime firstDate = meals.first.date;

    // remove old plan days
    for (var meal in planMeals) {
      if (meal.date.isBefore(today)) {
        PlanService.deletePlanMealFromPlan(
            context.read(planProvider).state.id, meal.id);
        updatedMeals.remove(meal);
      }
    }

    for (var i = 0; i < 8; i++) {
      final date = today.add(Duration(days: i));
      days.add(new PlanDay(date,
          updatedMeals.where((element) => element.date == date).toList()));
      updatedMeals.where((element) => element.date == date).forEach((element) {
        element.date = date;
      });
    }

    for (var meal in planMeals) {
      PlanService.updatePlanMealFromPlan(
          context.read(planProvider).state.id, meal);
    }

    return days;
  }
}

class PlanDay {
  DateTime date;
  List<PlanMeal> meals;

  PlanDay(this.date, this.meals);
}
