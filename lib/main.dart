import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:foodly/models/foodly_user.dart';
import 'package:foodly/services/authentication_service.dart';
import 'package:foodly/services/foodly_user_service.dart';
import 'package:foodly/services/meal_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:async/async.dart';
import 'package:logging/logging.dart';
import 'app_router.gr.dart';
import 'models/meal.dart';
import 'models/plan.dart';
import 'providers/state_providers.dart';
import 'services/plan_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ProviderScope(child: FoodlyApp()));
}

class FoodlyApp extends StatefulWidget {
  @override
  _FoodlyAppState createState() => _FoodlyAppState();
}

class _FoodlyAppState extends State<FoodlyApp> {
  StreamSubscription<List<List<Meal>>> _mealsStream;
  StreamSubscription<LogRecord> _logStream;

  @override
  void initState() {
    initializeDateFormatting();
    Logger.root.level = Level.ALL; // defaults to Level.INFO
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.loggerName}: ${record.message}');
    });

    super.initState();
  }

  @override
  void dispose() {
    _mealsStream.cancel();
    _logStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthenticationService.authenticationStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active ||
            snapshot.connectionState == ConnectionState.done) {
          _loadActivePlan(context);
          _loadActiveUser(context);
          return Consumer(
            builder: (context, watch, _) {
              watch(planProvider);

              if (context.read(planProvider).state != null) {
                _streamMeals();
              }
              return MaterialApp(
                theme: ThemeData(
                  // TODO: Nunito default font?
                  brightness: Brightness.light,
                  // textTheme: MediaQuery.of(context).size.width < 500
                  //     ? kSmallTextTheme
                  //     : kTextTheme,
                ),
                builder: (_, __) => ScrollConfiguration(
                  behavior: ScrollBehaviorModified(),
                  child: ExtendedNavigator<AppRouter>(
                    router: AppRouter(),
                  ),
                ),
              );
            },
          );
        } else {
          return Container();
        }
      },
    );
  }

  Future _loadActivePlan(BuildContext context) async {
    final currentPlan = context.read(planProvider).state;
    if (currentPlan == null) {
      String planId = await PlanService.getCurrentPlanId();

      if (planId != null && planId.isNotEmpty) {
        Plan newPlan = await PlanService.getPlanById(planId);
        context.read(planProvider).state = newPlan;
      }
    }
  }

  Future _loadActiveUser(BuildContext context) async {
    final firebaseUser = AuthenticationService.currentUser;
    if (firebaseUser != null) {
      FoodlyUser user = await FoodlyUserService.getUserById(firebaseUser.uid);
      context.read(userProvider).state = user;
    }
  }

  void _streamMeals() {
    if (_mealsStream == null) {
      _mealsStream = StreamZip([
        MealService.streamPlanMeals(context.read(planProvider).state.id),
        MealService.streamPublicMeals()
      ]).listen((lists) {
        var allSnaps = [...lists[0], ...lists[1]];
        allSnaps = [
          ...{...allSnaps}
        ];
        context.read(allMealsProvider).state = allSnaps;
      });
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
    return const ClampingScrollPhysics();
  }
}
