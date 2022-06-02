import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
import 'models/plan.dart';
import 'providers/state_providers.dart';
import 'services/authentication_service.dart';
import 'services/foodly_user_service.dart';
import 'services/link_metadata_service.dart';
import 'services/plan_service.dart';
import 'services/settings_service.dart';
import 'services/version_service.dart';
import 'utils/basic_utils.dart';

Future<void> main() async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await EasyLocalization.ensureInitialized();
      await Firebase.initializeApp();
      await initializeHive();

      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

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
    },
    (error, stack) =>
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
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
  final Logger _log = Logger('FoodlyApp');
  late StreamSubscription<String>? _intentDataStreamSubscription;

  final _appRouter = AppRouter();

  @override
  void initState() {
    _initializeLogger();
    _listenForShareIntent();
    _configureCrashlytics();
    super.initState();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
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
              final plan = watch(planProvider).state;
              _log.finer('PlanProvider Update: ${plan?.id}');

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
        final Plan? newPlan = await PlanService.getPlanById(planId);
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
      FirebaseCrashlytics.instance.setUserIdentifier(firebaseUser.uid);
      final FoodlyUser user =
          (await FoodlyUserService.getUserById(firebaseUser.uid))!;
      if (!mounted) {
        return;
      }
      context.read(userProvider).state = user;
    } else {
      FirebaseCrashlytics.instance.setUserIdentifier('');
      BasicUtils.afterBuild(() => context.read(userProvider).state = null);
    }

    BasicUtils.afterBuild(
      () => context.read(initialUserLoadingProvider).state = false,
    );
  }

  void _initializeLogger() {
    if (foundation.kDebugMode) {
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        // ignore: avoid_print
        print('${record.level.name}: ${record.loggerName}: ${record.message}');
      });
    } else {
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        if (record.level >= Level.SEVERE) {
          final message =
              '${record.loggerName} (${record.level.name}): ${record.message}';
          FirebaseCrashlytics.instance.recordError(
            message,
            record.stackTrace,
            reason: record.error,
          );
        }
      });
    }
  }

  void _configureCrashlytics() async {
    if (foundation.kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    }
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
    if (AuthenticationService.currentUser == null || value == null) {
      return;
    }

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
