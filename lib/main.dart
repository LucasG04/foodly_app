import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_router.gr.dart';
import 'models/plan.dart';
import 'providers/state_providers.dart';
import 'services/plan_service.dart';

void main() {
  runApp(ProviderScope(child: FoodlyApp()));
}

class FoodlyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    initializeDateFormatting();
    _loadActivePlan(watch(planProvider).state, context);

    // TODO: Nunito default font?
    return MaterialApp(
      builder: ExtendedNavigator<AppRouter>(
        router: AppRouter(),
        // builder: (context, extendedNav) => Theme(
        //   data: ThemeData(brightness: Brightness.dark),
        //   child: ScrollConfiguration(
        //     behavior: ScrollBehaviorModified(),
        //     child: extendedNav,
        //   ),
        // ),
      ),
    );
  }

  Future _loadActivePlan(Plan currentPlan, BuildContext context) async {
    if (currentPlan == null) {
      String planId = await PlanService.getCurrentPlanId();
      Plan newPlan = await PlanService.getPlanById(planId);

      context.read(planProvider).state = newPlan;
    }
  }
}

class ScrollBehaviorModified extends ScrollBehavior {
  const ScrollBehaviorModified();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.android:
        return const BouncingScrollPhysics();
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return const ClampingScrollPhysics();
    }
    return null;
  }
}
