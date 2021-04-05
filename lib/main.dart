import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' as Foundation;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logging/logging.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'app_router.gr.dart';
import 'constants.dart';
import 'models/foodly_user.dart';
import 'models/meal.dart';
import 'models/plan.dart';
import 'providers/state_providers.dart';
import 'services/authentication_service.dart';
import 'services/foodly_user_service.dart';
import 'services/meal_service.dart';
import 'services/plan_service.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SettingsService.initialize();
  runApp(ProviderScope(child: FoodlyApp()));
}

class FoodlyApp extends StatefulWidget {
  @override
  _FoodlyAppState createState() => _FoodlyAppState();
}

class _FoodlyAppState extends State<FoodlyApp> {
  StreamSubscription<String> _intentDataStreamSubscription;
  Logger _log = new Logger('FoodlyApp');
  StreamSubscription<LogRecord> _logStream;
  StreamSubscription<List<Meal>> _privateMealsStream;
  List<Meal> _privateMealsStreamValue;
  StreamSubscription<List<Meal>> _publicMealsStream;
  List<Meal> _publicMealsStreamValue;

  @override
  void dispose() {
    _privateMealsStream.cancel();
    _publicMealsStream.cancel();
    _logStream.cancel();
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    initializeDateFormatting();

    _initializeLogger();

    _privateMealsStreamValue = [];
    _publicMealsStreamValue = [];

    _listenForShareIntent();
    _checkForUpdate();

    super.initState();
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
              _log.finer(
                  'PlanProvider Update', context.read(planProvider).state?.id);

              if (context.read(planProvider).state != null) {
                _streamMeals();
              }
              return MaterialApp(
                debugShowCheckedModeBanner: false,
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
          return MaterialApp(home: Scaffold());
        }
      },
    );
  }

  Future<void> _loadActivePlan(BuildContext context) async {
    final currentPlan = context.read(planProvider).state;
    if (currentPlan == null) {
      String planId = await PlanService.getCurrentPlanId();

      if (planId != null && planId.isNotEmpty) {
        Plan newPlan = await PlanService.getPlanById(planId);
        context.read(planProvider).state = newPlan;
      }
    }
  }

  Future<void> _loadActiveUser(BuildContext context) async {
    final firebaseUser = AuthenticationService.currentUser;
    if (firebaseUser != null) {
      FoodlyUser user = await FoodlyUserService.getUserById(firebaseUser.uid);
      context.read(userProvider).state = user;
    }
  }

  void _initializeLogger() {
    if (Foundation.kDebugMode) {
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        print('${record.level.name}: ${record.loggerName}: ${record.message}');
      });
    } else {
      Logger.root.level = Level.OFF;
    }
  }

  void _streamMeals() {
    if (_privateMealsStream == null && _publicMealsStream == null) {
      _privateMealsStream =
          MealService.streamPlanMeals(context.read(planProvider).state.id)
              .listen((meals) {
        _privateMealsStreamValue = meals;
        mergeMealsIntoProvider();
      });
      _publicMealsStream = MealService.streamPublicMeals().listen((meals) {
        _publicMealsStreamValue = meals;
        mergeMealsIntoProvider();
      });
    }
  }

  void mergeMealsIntoProvider() {
    _log.finer('Call mergeMealsIntoProvider');

    var updatedMeals = [
      ..._privateMealsStreamValue,
      ..._publicMealsStreamValue
    ];
    updatedMeals = [
      ...{...updatedMeals}
    ];
    context.read(allMealsProvider).state = updatedMeals;
  }

  void _listenForShareIntent() {
    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
      if (AuthenticationService.currentUser != null &&
          value != null &&
          value.startsWith(kChefkochShareEndpoint)) {
        ExtendedNavigator.root
            .push(Routes.mealCreateScreen(id: Uri.encodeComponent(value)));
      }
    }, onError: (err) {
      _log.severe('ERR in ReceiveSharingIntent.getTextStream()', err);
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String value) {
      if (AuthenticationService.currentUser != null &&
          value != null &&
          value.startsWith(kChefkochShareEndpoint)) {
        ExtendedNavigator.root
            .push(Routes.mealCreateScreen(id: Uri.encodeComponent(value)));
      }
    });
  }

  void _checkForUpdate() async {
    final updateInfo = await InAppUpdate.checkForUpdate().catchError((err) {
      _log.severe('ERR in InAppUpdate.checkForUpdate()', err);
    });

    if (updateInfo?.updateAvailability == UpdateAvailability.updateAvailable) {
      InAppUpdate.startFlexibleUpdate().then((_) {
        InAppUpdate.completeFlexibleUpdate().catchError((err) {
          _log.severe('ERR in InAppUpdate.completeFlexibleUpdate()', err);
        });
      }).catchError((err) {
        _log.severe('ERR in InAppUpdate.startFlexibleUpdate()', err);
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
