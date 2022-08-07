import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/plan_meal.dart';
import '../../providers/state_providers.dart';
import '../../services/plan_service.dart';
import '../../widgets/main_appbar.dart';
import '../../widgets/small_circular_progress_indicator.dart';
import 'plan_view/plan_day_card.dart';
import 'plan_view/plan_tab_view.dart';

class PlanHistoryView extends StatefulWidget {
  const PlanHistoryView({Key? key}) : super(key: key);

  @override
  State<PlanHistoryView> createState() => _PlanHistoryViewState();
}

class _PlanHistoryViewState extends State<PlanHistoryView> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        text: 'plan_history_title'.tr(),
        scrollController: _scrollController,
        showBack: false,
        actions: [
          IconButton(
            onPressed: navigateBack,
            icon: const Icon(EvaIcons.close),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            FutureBuilder<List<PlanMeal>>(
              future: PlanService.getPlanMealHistoryByPlanId(
                context.read(planProvider).state!.id!,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _getPlanDays(snapshot.data!)
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
            TextButton(
              onPressed: navigateBack,
              child: Text('plan_history_back'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  List<PlanDay> _getPlanDays(List<PlanMeal> meals) {
    // TODO manage plan history and return plandays
    return [];
  }

  void navigateBack() {
    context.read(planHistoryPageChanged).state =
        DateTime.now().millisecondsSinceEpoch;
  }
}
