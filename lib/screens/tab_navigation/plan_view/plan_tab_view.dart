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
import '../../../services/app_review_service.dart';
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
import 'review_request_container.dart';

class PlanTabView extends ConsumerStatefulWidget {
  const PlanTabView({super.key});
  @override
  PlanTabViewState createState() => PlanTabViewState();
}

class PlanTabViewState extends ConsumerState<PlanTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final AutoDisposeStreamProvider<List<PlanMeal>> planMealsStreamProvider =
      StreamProvider.autoDispose<List<PlanMeal>>((ref) {
    final activePlan = ref.watch(planProvider);
    return PlanService.streamPlanMealsByPlanId(activePlan!.id);
  });

  // TODO: initState to listen on plan meal changes; create providers for all days or one that can be used with select for individual days

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final livePlanMeals = ref.watch(planMealsStreamProvider);
    final plan = ref.read(planProvider);

    ref.listen<AsyncValue<List<PlanMeal>>>(planMealsStreamProvider, (_, next) {
      next.whenData(_archiveOldMeals);
    });

    return plan != null
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
                          onPressed: () => _showOptionsSheet(plan),
                          icon: const Icon(EvaIcons.moreHorizontalOutline),
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<bool>(
                    stream: AppReviewService.shouldRequestReview(),
                    builder: (context, snapshot) {
                      if (snapshot.data == null || !snapshot.data!) {
                        return const SizedBox();
                      }
                      return SizedBox(
                        width: BasicUtils.contentWidth(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 5.0),
                          child: ReviewRequestContainer(),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    width: BasicUtils.contentWidth(context),
                    child: livePlanMeals.when(
                      data: (planMeals) => Column(
                        children: _getDaysByMeals(planMeals)
                            .map(
                              (e) => PlanDayCard(
                                date: e.date,
                                meals: e.meals,
                              ),
                            )
                            .toList(),
                      ),
                      error: (_, __) => const LoadingLogout(),
                      loading: () => const Center(
                        child: SmallCircularProgressIndicator(),
                      ),
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

  /// Builds the 8-day display list from the current stream snapshot.
  List<PlanDay> _getDaysByMeals(List<PlanMeal> planMeals) {
    final plan = ref.read(planProvider)!;
    final now = DateTime.now().toUtc().add(Duration(hours: plan.hourDiffToUtc!));
    final today = DateTime(now.year, now.month, now.day);
    final currentMeals = planMeals.where((m) => !m.date.isBefore(today));
    return List.generate(8, (i) {
      final date = today.add(Duration(days: i));
      return PlanDay(
        date,
        currentMeals.where((m) => DateUtils.isSameDay(m.date, date)).toList(),
      );
    });
  }

  /// Moves past meals into the plan history and deletes them from the active
  /// plan. Runs as side effect via [ref.listen] on [planMealsStreamProvider].
  void _archiveOldMeals(List<PlanMeal> planMeals) {
    final plan = ref.read(planProvider)!;
    final now = DateTime.now().toUtc().add(Duration(hours: plan.hourDiffToUtc!));
    final today = DateTime(now.year, now.month, now.day);
    final oldMeals = planMeals.where((m) => m.date.isBefore(today));
    for (final meal in oldMeals) {
      PlanService.addPlanMealToPlanHistory(plan.id!, meal);
      PlanService.deletePlanMealFromPlan(plan.id, meal.id);
    }
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
