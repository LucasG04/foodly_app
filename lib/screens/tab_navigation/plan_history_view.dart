import 'dart:async';

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
  _PlanHistoryViewState createState() => _PlanHistoryViewState();
}

class _PlanHistoryViewState extends ConsumerState<PlanHistoryView> {
  final planHistoryDaysProvider =
      AsyncNotifierProvider<PlanHistoryDaysNotifier, List<PlanDay>>(
    PlanHistoryDaysNotifier.new,
  );

  final ScrollController _scrollController = ScrollController();
  bool initialScrolledDown = false;

  @override
  Widget build(BuildContext context) {
    final planHistoryAsync = ref.watch(planHistoryDaysProvider);

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
                color: Theme.of(context).textTheme.bodyLarge!.color,
              ),
            ),
          ),
        ],
      ),
      body: planHistoryAsync.when(
        loading: () => const Center(child: SmallCircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('try_again_later'.tr()),
        ),
        data: (planDays) {
          if (!initialScrolledDown && planDays.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients &&
                  _scrollController.position.maxScrollExtent > 0) {
                _scrollController
                    .jumpTo(_scrollController.position.maxScrollExtent);
              }
              if (mounted) {
                initialScrolledDown = true;
              }
            });
          }

          return SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                Center(
                  child: SizedBox(
                    width: BasicUtils.contentWidth(context),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: planDays.length,
                      itemBuilder: (context, index) {
                        final day = planDays[index];
                        return PlanDayCard(
                          date: day.date,
                          meals: day.meals,
                          readonly: true,
                        );
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
          );
        },
      ),
    );
  }

  void navigateBack() {
    ref.read(planHistoryPageChanged.notifier).state =
        DateTime.now().millisecondsSinceEpoch;
  }
}

// Notifier class to handle fetching and processing
class PlanHistoryDaysNotifier extends AsyncNotifier<List<PlanDay>> {
  @override
  FutureOr<List<PlanDay>> build() async {
    final plan = ref.watch(planProvider);

    // If there's no active plan, return an empty list or handle appropriately
    if (plan == null || plan.id == null) {
      // TODO: Consider throwing an error or returning an empty list based on requirements
      // throw Exception("No active plan selected.");
      return [];
    }

    final List<PlanMeal> mealHistory =
        await PlanService.getPlanMealHistoryByPlanId(plan.id!);
    return _processPlanMeals(plan, mealHistory);
  }

  List<PlanDay> _processPlanMeals(Plan plan, List<PlanMeal> meals) {
    final List<PlanDay> days = [];
    final List<PlanMeal> updatedMeals = [...meals]; // Create a mutable copy

    final now =
        DateTime.now().toUtc().add(Duration(hours: plan.hourDiffToUtc ?? 0));
    final weekAgo = now.subtract(const Duration(days: 7));

    // Remove meals older than 7 days from the history
    final List<PlanMeal> oldMeals =
        meals.where((meal) => meal.date.isBefore(weekAgo)).toList();
    for (final meal in oldMeals) {
      PlanService.deletePlanMealFromHistroy(plan.id, meal.id);
    }
    // Remove from the list that will be processed
    oldMeals.forEach(updatedMeals.remove);

    // Prepare PlanDay objects for the last 7 days
    for (var i = 0; i < 7; i++) {
      final date = weekAgo.add(Duration(days: i));
      final mealsForDay = updatedMeals
          .where((element) => DateUtils.isSameDay(element.date, date))
          .toList();
      days.add(PlanDay(date, mealsForDay));

      // TODO: Ensure meal dates are consistent (though they should be already)
      // This part might be redundant if PlanService returns correct dates
      // for (final element in mealsForDay) {
      //   element.date = date;
      // }
    }

    // TODO: check if equal check is correct
    // final differentIds = !meals.every(
    //   (meal) => updatedMeals.any((updatedMeal) => updatedMeal.id == meal.id),
    // );
    // if (differentIds) {
    //   for (final meal in updatedMeals) {
    //     PlanService.updateHistoryPlanMealFromPlan(plan.id, meal);
    //   }
    // }

    return days;
  }
}
