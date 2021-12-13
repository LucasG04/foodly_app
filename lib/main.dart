import 'dart:async';
import 'dart:io' show Platform;

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' as Foundation;
import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/link_metadata_service.dart';
import 'package:hive/hive.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
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
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp();
  var dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  await SettingsService.initialize();
  await LinkMetadataService.initialize();

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: [Locale('en'), Locale('de')],
        path: 'assets/translations',
        fallbackLocale: Locale('en'),
        child: FoodlyApp(),
      ),
    ),
  );
}

class FoodlyApp extends StatefulWidget {
  @override
  _FoodlyAppState createState() => _FoodlyAppState();
}

class _FoodlyAppState extends State<FoodlyApp> {
  late StreamSubscription<String> _intentDataStreamSubscription;
  Logger _log = new Logger('FoodlyApp');
  late StreamSubscription<LogRecord> _logStream;
  // ignore: cancel_subscriptions
  StreamSubscription<List<Meal>>? _privateMealsStream;
  List<Meal>? _privateMealsStreamValue;
  // ignore: cancel_subscriptions
  StreamSubscription<List<Meal>>? _publicMealsStream;
  List<Meal>? _publicMealsStreamValue;

  final _appRouter = AppRouter();

  @override
  void dispose() {
    _privateMealsStream!.cancel();
    _publicMealsStream!.cancel();
    _logStream.cancel();
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
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

              return MaterialApp.router(
                routerDelegate: _appRouter.delegate(),
                routeInformationParser: _appRouter.defaultRouteParser(),
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  // TODO: Nunito default font?
                  brightness: Brightness.light,
                  // textTheme: MediaQuery.of(context).size.width < 500
                  //     ? kSmallTextTheme
                  //     : kTextTheme,
                ),
                localizationsDelegates: [
                  ...context.localizationDelegates,
                  LocaleNamesLocalizationsDelegate(),
                ],
                supportedLocales: context.supportedLocales,
                locale: context.locale,
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
      String? planId = await PlanService.getCurrentPlanId();

      if (planId != null && planId.isNotEmpty) {
        Plan newPlan = (await PlanService.getPlanById(planId))!;
        context.read(planProvider).state = newPlan;
      }
    }
  }

  Future<void> _loadActiveUser(BuildContext context) async {
    final firebaseUser = AuthenticationService.currentUser;
    if (firebaseUser != null) {
      FoodlyUser user =
          (await FoodlyUserService.getUserById(firebaseUser.uid))!;
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
          MealService.streamPlanMeals(context.read(planProvider).state!.id!)
              .listen((meals) {
        _privateMealsStreamValue = meals;
        mergeMealsIntoProvider();
        _log.finest('Private meals updated: ' + meals.toString());
      });
      _publicMealsStream = MealService.streamPublicMeals().listen((meals) {
        _publicMealsStreamValue = meals;
        mergeMealsIntoProvider();
        _log.finest('Public meals updated: ' + meals.toString());
      });
    }
  }

  void mergeMealsIntoProvider() {
    _log.finer('Call mergeMealsIntoProvider');

    var updatedMeals = [
      ..._privateMealsStreamValue!,
      ..._publicMealsStreamValue!
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
          value.startsWith(kChefkochShareEndpoint)) {
        context.router
            .push(MealCreateScreenRoute(id: Uri.encodeComponent(value)));
      }
    }, onError: (err) {
      _log.severe('ERR in ReceiveSharingIntent.getTextStream()', err);
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String? value) {
      if (AuthenticationService.currentUser != null &&
          value != null &&
          value.startsWith(kChefkochShareEndpoint)) {
        context.router
            .push(MealCreateScreenRoute(id: Uri.encodeComponent(value)));
      }
    });
  }

  void _checkForUpdate() async {
    if (!Platform.isAndroid) {
      return;
    }

    final updateInfo = await InAppUpdate.checkForUpdate().catchError((err) {
      _log.severe('ERR in InAppUpdate.checkForUpdate()', err);
    });

    if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
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
  }
}
