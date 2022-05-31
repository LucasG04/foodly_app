import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'app_router.gr.dart';
import 'constants.dart';
import 'models/foodly_user.dart';
import 'models/link_metadata.dart';
import 'models/meal.dart';
import 'models/plan.dart';
import 'providers/state_providers.dart';
import 'services/authentication_service.dart';
import 'services/foodly_user_service.dart';
import 'services/link_metadata_service.dart';
import 'services/log_record_service.dart';
import 'services/meal_service.dart';
import 'services/plan_service.dart';
import 'services/settings_service.dart';
import 'services/version_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp();
  await initializeHive();

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('de')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const FoodlyApp(),
      ),
    ),
  );
}

Future<void> initializeHive() async {
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  Hive.registerAdapter(LinkMetadataAdapter());
  await Future.wait<dynamic>([
    SettingsService.initialize(),
    LinkMetadataService.initialize(),
    VersionService.initialize(),
  ]);
}

class FoodlyApp extends StatefulWidget {
  const FoodlyApp({foundation.Key? key}) : super(key: key);

  @override
  _FoodlyAppState createState() => _FoodlyAppState();
}

class _FoodlyAppState extends State<FoodlyApp> {
  late StreamSubscription<String> _intentDataStreamSubscription;
  final Logger _log = Logger('FoodlyApp');
  late StreamSubscription<LogRecord> _logStream;
  // ignore: cancel_subscriptions
  StreamSubscription<List<Meal>>? _privateMealsStream;
  // ignore: cancel_subscriptions
  StreamSubscription<List<Meal>>? _publicMealsStream;

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
    LogRecordService.startPeriodicLogging();
    _listenForShareIntent();
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
              final plan = watch(planProvider).state;
              _log.finer('PlanProvider Update: ${plan?.id}');

              if (plan != null) {
                _preloadAndStreamMeals();
              }

              return MaterialApp.router(
                routerDelegate: _appRouter.delegate(),
                routeInformationParser: _appRouter.defaultRouteParser(),
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  // Nunito default font?
                  brightness: Brightness.light,
                ),
                localizationsDelegates: [
                  ...context.localizationDelegates,
                  const LocaleNamesLocalizationsDelegate(),
                ],
                supportedLocales: context.supportedLocales,
                locale: context.locale,
              );
            },
          );
        } else {
          return const MaterialApp(home: Scaffold());
        }
      },
    );
  }

  Future<void> _loadActivePlan(BuildContext context) async {
    final currentPlan = context.read(planProvider).state;
    if (currentPlan == null) {
      final String? planId = await PlanService.getCurrentPlanId();

      if (planId != null && planId.isNotEmpty) {
        final Plan newPlan = (await PlanService.getPlanById(planId))!;
        if (!mounted) {
          return;
        }
        context.read(planProvider).state = newPlan;
      }
    }
  }

  Future<void> _loadActiveUser(BuildContext context) async {
    final firebaseUser = AuthenticationService.currentUser;
    if (firebaseUser != null) {
      final FoodlyUser user =
          (await FoodlyUserService.getUserById(firebaseUser.uid))!;
      if (!mounted) {
        return;
      }
      context.read(userProvider).state = user;
    }
  }

  void _initializeLogger() {
    if (foundation.kDebugMode) {
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        _addLogToProvider(record);
        // ignore: avoid_print
        print('${record.level.name}: ${record.loggerName}: ${record.message}');
      });
    } else {
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        _addLogToProvider(record);
        if (record.level >= Level.SEVERE) {
          final userId = context.read(userProvider).state?.id;
          final planId = context.read(planProvider).state?.id;
          LogRecordService.saveLog(
            userId: userId,
            planId: planId,
            logRecord: record,
          );
        }
      });
    }
  }

  void _addLogToProvider(LogRecord record) {
    if (kLogViewEnabled) {
      context.read(logsProvider).state = [
        ...context.read(logsProvider).state,
        record
      ];
    }
  }

  void _preloadAndStreamMeals() {
    final planId = context.read(planProvider).state?.id;

    if (planId == null) {
      return;
    }
    _privateMealsStream?.cancel();
    _privateMealsStream = null;
    MealService.getMealsPaginated(planId).then((value) {
      if (context.read(allMealsProvider).state.isEmpty) {
        context.read(allMealsProvider).state = value;
        context.read(initLoadingMealsProvider).state = false;
      }
    });
    _privateMealsStream = MealService.streamPlanMeals(planId).listen((meals) {
      context.read(allMealsProvider).state = meals;
      context.read(initLoadingMealsProvider).state = false;
      _log.finest('Private meals updated: $meals');
    });
  }

  void _listenForShareIntent() {
    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.getTextStream()
        .listen(_handleReceivedMealShare, onError: (dynamic err) {
      _log.severe('ERR in ReceiveSharingIntent.getTextStream()', err);
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then(_handleReceivedMealShare);
  }

  void _handleReceivedMealShare(String? value) {
    if (AuthenticationService.currentUser != null && value != null) {
      if (value.startsWith(kChefkochShareEndpoint)) {
        _appRouter
            .navigate(MealCreateScreenRoute(id: Uri.encodeComponent(value)));
      } else if (value.contains(kChefkochShareEndpoint)) {
        final startIndex = value.indexOf(kChefkochShareEndpoint);
        final extractedLink =
            value.substring(startIndex, value.length).split(' ')[0];
        _appRouter.navigate(
            MealCreateScreenRoute(id: Uri.encodeComponent(extractedLink)));
      }
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
