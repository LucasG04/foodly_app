import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants.dart';
import '../../models/plan.dart';
import '../../models/plan_meal.dart';
import '../../providers/state_providers.dart';
import '../../services/plan_service.dart';
import '../../utils/basic_utils.dart';
import '../../widgets/main_appbar.dart';
import '../../widgets/small_circular_progress_indicator.dart';
import 'plan_view/plan_day_card.dart';
import 'plan_view/plan_tab_view.dart';

class PlanHistoryView extends ConsumerStatefulWidget {
  const PlanHistoryView({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _PlanHistoryViewState createState() => _PlanHistoryViewState();
}

class _PlanHistoryViewState extends ConsumerState<PlanHistoryView> {
  final ScrollController _scrollController = ScrollController();
  bool initialScrolledDown = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        text: 'plan_history_title'.tr(),
        scrollController: _scrollController,
        showBack: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: kPadding / 2),
            child: IconButton(
              onPressed: navigateBack,
              icon: Icon(
                EvaIcons.close,
                color: Theme.of(context).textTheme.bodyText1!.color,
              ),
            ),
          ),
        ],
      ),
      body: ref.read(planProvider) != null
          ? SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  Center(
                    child: SizedBox(
                      width: BasicUtils.contentWidth(context),
                      child: FutureBuilder<List<PlanMeal>>(
                        future: PlanService.getPlanMealHistoryByPlanId(
                          ref.read(planProvider)!.id!,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            if (!initialScrolledDown) {
                              BasicUtils.afterBuild(
                                () => _scrollController.jumpTo(
                                    _scrollController.position.maxScrollExtent),
                              );
                              initialScrolledDown = true;
                            }
                            return ListView(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              children: _getPlanDays(snapshot.data!)
                                  .map(
                                    (e) => PlanDayCard(
                                      date: e.date,
                                      meals: e.meals,
                                      readonly: true,
                                    ),
                                  )
                                  .toList(),
                            );
                          } else {
                            return SizedBox(
                              height: MediaQuery.of(context).size.height * 0.75,
                              child: const Center(
                                child: SmallCircularProgressIndicator(),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: navigateBack,
                    tooltip: 'plan_history_back_tooltip'.tr(),
                    icon: const Icon(EvaIcons.arrowDownwardOutline),
                  ),
                  const SizedBox(height: kPadding),
                ],
              ),
            )
          : const SizedBox(),
    );
  }

  List<PlanDay> _getPlanDays(List<PlanMeal> meals) {
    final Plan plan = ref.read(planProvider)!;
    final List<PlanDay> days = [];
    final List<PlanMeal> updatedMeals = [...meals];

    final now =
        DateTime.now().toUtc().add(Duration(hours: plan.hourDiffToUtc!));
    final weekAgo = DateTime(now.year, now.month, now.day).subtract(
      const Duration(days: 7),
    );

    // remove old plan days and add to history
    final oldMeals = meals.where((meal) => meal.date.isBefore(weekAgo));
    for (final meal in oldMeals) {
      PlanService.deletePlanMealFromPlan(plan.id, meal.id);
    }
    oldMeals.forEach(updatedMeals.remove);

    // update plan days
    for (var i = 0; i < 7; i++) {
      final date = weekAgo.add(Duration(days: i));
      days.add(
        PlanDay(date,
            updatedMeals.where((element) => element.date == date).toList()),
      );
      updatedMeals.where((element) => element.date == date).forEach((element) {
        element.date = date;
      });
    }

    // apply updates to firebase collection
    if (meals != updatedMeals) {
      for (final meal in updatedMeals) {
        PlanService.updateHistoryPlanMealFromPlan(plan.id, meal);
      }
    }

    return days;
  }

  void navigateBack() {
    ref.read(planHistoryPageChanged.state).state =
        DateTime.now().millisecondsSinceEpoch;
  }
}
