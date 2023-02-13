import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../app_router.gr.dart';
import '../../../constants.dart';
import '../../../models/plan.dart';
import '../../../models/plan_meal.dart';
import '../../../providers/state_providers.dart';
import '../../../services/plan_service.dart';
import '../../../utils/basic_utils.dart';
import '../../../utils/widget_utils.dart';
import '../../../widgets/loading_logout.dart';
import '../../../widgets/options_modal/options_modal.dart';
import '../../../widgets/options_modal/options_modal_option.dart';
import '../../../widgets/page_title.dart';
import '../../../widgets/small_circular_progress_indicator.dart';
import 'plan_day_card.dart';
import 'plan_download_modal.dart';

class PlanTabView extends ConsumerStatefulWidget {
  const PlanTabView({Key? key}) : super(key: key);
  @override
  PlanTabViewState createState() => PlanTabViewState();
}

class PlanTabViewState extends ConsumerState<PlanTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final activePlan = ref.watch(planProvider);

    return activePlan != null
        ? SingleChildScrollView(
            child: AnimationLimiter(
              child: Column(
                children: [
                  const SizedBox(height: kPadding),
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: PageTitle(
                      text: 'plan_title'.tr(),
                      checkConnectivity: true,
                      actions: [
                        IconButton(
                          onPressed: () => AutoRouter.of(context).push(
                            const SettingsScreenRoute(),
                          ),
                          icon: const Icon(EvaIcons.settings2Outline),
                        ),
                        IconButton(
                          onPressed: () => _showOptionsSheet(activePlan),
                          icon: const Icon(EvaIcons.moreHorizontalOutline),
                        )
                      ],
                    ),
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
                            physics: const NeverScrollableScrollPhysics(),
                            children: _getDaysByMeals(snapshot.data!)
                                .map(
                                  (e) => PlanDayCard(
                                    date: e.date,
                                    meals: e.meals,
                                  ),
                                )
                                .toList(),
                          );
                        } else {
                          return const Center(
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
        : const LoadingLogout();
  }

  void _showOptionsSheet(Plan plan) {
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => OptionsSheet(options: [
        OptionsSheetOptions(
          title: 'plan_history_title'.tr(),
          icon: EvaIcons.clockOutline,
          onTap: () {
            ref.read(planHistoryPageChanged.notifier).state =
                DateTime.now().millisecondsSinceEpoch;
          },
        ),
        OptionsSheetOptions(
          title: 'plan_download_modal_title'.tr(),
          icon: EvaIcons.downloadOutline,
          onTap: () => _openDownloadModal(plan),
        ),
      ]),
    );
  }

  List<PlanDay> _getDaysByMeals(List<PlanMeal> meals) {
    ref.read(planProvider)!.meals = meals;
    return _updateMealsForDays(meals);
  }

  List<PlanDay> _updateMealsForDays(List<PlanMeal> planMeals) {
    final Plan plan = ref.read(planProvider)!;
    final List<PlanDay> days = [];
    final List<PlanMeal> updatedMeals = [...planMeals];

    final now =
        DateTime.now().toUtc().add(Duration(hours: plan.hourDiffToUtc!));
    final today = DateTime(now.year, now.month, now.day);

    // remove old plan days and add to history
    final oldMeals = planMeals.where((meal) => meal.date.isBefore(today));
    for (final meal in oldMeals) {
      PlanService.addPlanMealToPlanHistory(plan.id!, meal);
      PlanService.deletePlanMealFromPlan(plan.id, meal.id);
    }
    oldMeals.forEach(updatedMeals.remove);

    // update plan days
    for (var i = 0; i < 8; i++) {
      final date = today.add(Duration(days: i));
      days.add(
        PlanDay(date,
            updatedMeals.where((element) => element.date == date).toList()),
      );
      updatedMeals.where((element) => element.date == date).forEach((element) {
        element.date = date;
      });
    }

    // apply updates to firebase collection
    if (planMeals != updatedMeals) {
      Future.wait(
        updatedMeals.map((e) => PlanService.updatePlanMealFromPlan(plan.id, e)),
      );
    }

    return days;
  }

  void _openDownloadModal(Plan plan) {
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => PlanDownloadModal(plan: plan),
    );
  }
}

class PlanDay {
  DateTime date;
  List<PlanMeal> meals;

  PlanDay(this.date, this.meals);
}
