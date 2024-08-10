import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uni_links/uni_links.dart';

import 'app_router.gr.dart';
import 'constants.dart';
import 'models/foodly_user.dart';
import 'models/link_metadata.dart';
import 'models/plan.dart';
import 'primary_colors.dart';
import 'providers/data_provider.dart';
import 'providers/state_providers.dart';
import 'services/app_review_service.dart';
import 'services/authentication_service.dart';
import 'services/foodly_user_service.dart';
import 'services/in_app_purchase_service.dart';
import 'services/link_metadata_service.dart';
import 'services/lunix_api_service.dart';
import 'services/meal_service.dart';
import 'services/plan_service.dart';
import 'services/settings_service.dart';
import 'services/shopping_list_service.dart';
import 'services/version_service.dart';
import 'utils/basic_utils.dart';
import 'utils/convert_util.dart';
import 'widgets/disposable_widget.dart';

Future<void> _configureFirebase() async {
  await Firebase.initializeApp();
  if (foundation.kDebugMode) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  } else {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    await FirebaseAppCheck.instance.activate(
      appleProvider: AppleProvider.appAttestWithDeviceCheckFallback,
    );
    final packageInfo = await PackageInfo.fromPlatform();
    await Future.wait([
      FirebaseAnalytics.instance
          .setDefaultEventParameters({'version': packageInfo.version}),
      FirebaseCrashlytics.instance.setCustomKey('version', packageInfo.version),
      FirebaseCrashlytics.instance
          .setCustomKey('buildNumber', packageInfo.buildNumber),
    ]);
  }
}

void main() {
  runZonedGuarded<void>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await EasyLocalization.ensureInitialized();
      await _configureFirebase();
      await initializeHive();
      runApp(
        Phoenix(
          child: ProviderScope(
            child: EasyLocalization(
              supportedLocales: const [Locale('en'), Locale('de')],
              path: 'assets/translations',
              fallbackLocale: const Locale('en'),
              child: const FoodlyApp(),
            ),
          ),
        ),
      );
    },
    (error, stack) => FirebaseCrashlytics.instance.recordError(
      ConvertUtil.errorDescriptionToString(error),
      stack,
      fatal: true,
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
    AppReviewService.initialize(),
    PlanService.initialize(),
    InAppPurchaseService.initialize(),
    FastCachedImageConfig.init(clearCacheAfter: const Duration(days: 14)),
  ]);
}

class FoodlyApp extends ConsumerStatefulWidget {
  const FoodlyApp({foundation.Key? key}) : super(key: key);

  @override
  _FoodlyAppState createState() => _FoodlyAppState();
}

class _FoodlyAppState extends ConsumerState<FoodlyApp> with DisposableWidget {
  final _log = Logger('FoodlyApp');
  final _appRouter = AppRouter();

  /// Handle the initial uni link only when user is in a plan
  bool _handleInitUniLink = true;

  /// Subscription that handles uni links when the app is in the foreground.
  /// Will be canceled by [cancelSubscriptions] when the app is closed
  // ignore: cancel_subscriptions
  StreamSubscription<String?>? _uniLinkSub;

  @override
  void initState() {
    _initializeLogger();
    _listenForShareIntent();
    _listenForConnectivity();
    super.initState();
    InAppPurchaseService.setRef(ref);
    SettingsService.setRef(ref);
  }

  @override
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthenticationService.authenticationStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active ||
            snapshot.connectionState == ConnectionState.done) {
          Future.wait([
            _loadBaseData(),
            _loadActivePlan(),
            _loadActiveUser(),
          ]).whenComplete(() => afterUserAndPlanLoaded());

          return Consumer(
            builder: (context, ref, _) {
              final plan = ref.watch(planProvider);
              _log.finer('PlanProvider Update: ${plan?.id}');

              if (plan != null) {
                _loadActiveShoppingList();
              } else {
                ref.read(shoppingListIdProvider.notifier).state = null;
              }

              return MaterialApp.router(
                routerDelegate: _appRouter.delegate(),
                routeInformationParser: _appRouter.defaultRouteParser(),
                debugShowCheckedModeBanner: false,
                themeMode: ThemeMode.light,
                localizationsDelegates: [
                  ...context.localizationDelegates,
                  const LocaleNamesLocalizationsDelegate(),
                ],
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                theme: ThemeData(
                  primaryColor: SettingsService.primaryColor,
                  dividerColor: Colors.grey.shade300,
                  scaffoldBackgroundColor: const Color(0xFFFFFFFF),
                  dialogBackgroundColor: const Color(0xFFFFFFFF),
                  cardTheme: const CardTheme(
                    color: Color(0xFFFFFFFF),
                  ),
                  outlinedButtonTheme: OutlinedButtonThemeData(
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kRadius),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        } else {
          return const MaterialApp(home: Scaffold());
        }
      },
    );
  }

  Future<void> _loadActivePlan() async {
    final currentPlan = ref.read(planProvider);
    if (currentPlan == null) {
      final String? planId = await PlanService.getCurrentPlanId();

      if (planId != null && planId.isNotEmpty) {
        FirebaseCrashlytics.instance.setCustomKey('planId', planId);
        final Plan? newPlan = await PlanService.getPlanById(planId);
        if (!mounted) {
          return;
        }
        ref.read(planProvider.notifier).state = newPlan;
      }
    }

    BasicUtils.afterBuild(
      () => ref.read(initialPlanLoadingProvider.notifier).state = false,
    );
  }

  Future<void> _loadActiveUser() async {
    final firebaseUser = AuthenticationService.currentUser;
    if (firebaseUser != null) {
      FirebaseCrashlytics.instance.setUserIdentifier(firebaseUser.uid);
      FirebaseCrashlytics.instance.setCustomKey('userId', firebaseUser.uid);
      final FoodlyUser? user =
          await FoodlyUserService.getUserById(firebaseUser.uid);
      if (!mounted || user == null) {
        return;
      }
      ref.read(userProvider.notifier).state = user;
      await InAppPurchaseService.setUserId(user.id!);
      _checkPremiumStatus();
      _checkUserSubsription();
    } else {
      FirebaseCrashlytics.instance.setUserIdentifier('');
      BasicUtils.afterBuild(() => ref.read(userProvider.notifier).state = null);
      _handleInitUniLink = false;
    }

    BasicUtils.afterBuild(
      () => ref.read(initialUserLoadingProvider.notifier).state = false,
    );
  }

  void _checkPremiumStatus() {
    final user = ref.read(userProvider);
    if (user == null) {
      return;
    }
    if (user.isPremium == true) {
      ref.read(InAppPurchaseService.$userIsSubscribed.notifier).state = true;
      return;
    }
    if (BasicUtils.premiumGiftedActive(user)) {
      ref.read(InAppPurchaseService.$userIsSubscribed.notifier).state = true;
    }
  }

  Future<void> _loadActiveShoppingList() async {
    final planId = ref.read(planProvider)?.id;
    final userId = ref.read(userProvider)?.id;

    if (planId == null || userId == null) {
      return;
    }
    var shoppingList = await ShoppingListService.getShoppingListByPlanId(
      planId,
    );
    while (shoppingList == null) {
      shoppingList = await ShoppingListService.getShoppingListByPlanId(
        planId,
      );
    }
    ref.read(shoppingListIdProvider.notifier).state = shoppingList.id;
  }

  Future<void> _loadBaseData() {
    return Future.wait([
      _loadGroceryGroups(),
      _loadSupportedImportSites(),
    ]);
  }

  Future<void> _loadGroceryGroups() async {
    final langCode = context.locale.languageCode;
    final groups = await LunixApiService.getGroceryGroups(langCode);
    ref.read(dataGroceryGroupsProvider.notifier).state = groups;
  }

  Future<void> _loadSupportedImportSites() async {
    final sites = await LunixApiService.getSupportedImportSites();
    ref.read(dataSupportedImportSitesProvider.notifier).state = sites;
  }

  void _initializeLogger() {
    if (foundation.kDebugMode) {
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        // ignore: avoid_print
        print('${record.level.name}: ${record.loggerName}: ${record.message}');
        if (record.error != null) {
          // ignore: avoid_print
          print(ConvertUtil.errorDescriptionToString(record.error));
        }
      }).canceledBy(this);
    } else {
      Logger.root.level = Level.ALL;
      Logger.root.onRecord
          .where((record) => record.level >= Level.SEVERE)
          .listen((record) {
        final message =
            '${record.loggerName} (${record.level.name}): ${record.message}';
        FirebaseCrashlytics.instance.recordError(
          message,
          record.stackTrace,
          reason: ConvertUtil.errorDescriptionToString(record.error),
        );
      }).canceledBy(this);
    }
  }

  void _listenForShareIntent() {
    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    ReceiveSharingIntent.getTextStream()
        .listen(_handleReceivedMealShare,
            onError: (dynamic err) =>
                _log.severe('ERR in ReceiveSharingIntent.getTextStream()', err))
        .canceledBy(this);

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

  void _checkUserSubsription() async {
    final isSubscribed = ref.read(InAppPurchaseService.$userIsSubscribed);
    if (isSubscribed) {
      return;
    }

    bool shouldRestartApp = false;

    if (SettingsService.primaryColor.value != defaultPrimaryColor.value) {
      await SettingsService.setPrimaryColor(defaultPrimaryColor);
      shouldRestartApp = true;
    }
    if (SettingsService.shoppingListSort != defaultShoppingListSort) {
      await SettingsService.setShoppingListSort(defaultShoppingListSort);
    }

    if (shouldRestartApp && mounted) {
      Phoenix.rebirth(context);
    }
  }

  void _listenForConnectivity() async {
    InternetConnectionChecker().hasConnection.then((result) {
      ref.read(hasConnectionProvider.notifier).state = result;
    });

    Connectivity().onConnectivityChanged.listen((_) async {
      final isDeviceConnected = await InternetConnectionChecker().hasConnection;
      if (!mounted) {
        return;
      }
      ref.read(hasConnectionProvider.notifier).state = isDeviceConnected;
    }).canceledBy(this);
  }

  Future<void> afterUserAndPlanLoaded() async {
    _initUniLinks();
  }

  Future<void> _initUniLinks() async {
    if (_handleInitUniLink) {
      try {
        final initialLink = await getInitialLink();
        _processLink(initialLink);
      } catch (e) {
        _log.finer('Failed to get initial link', e);
      }
    }

    if (_uniLinkSub == null) {
      _uniLinkSub = linkStream.listen(
        _processLink,
        onError: (dynamic e) => _log.finer('ERR in getLinksStream()', e),
      );
      _uniLinkSub!.canceledBy(this);
    }
  }

  Future<void> _processLink(String? link) async {
    if (link == null || link.isEmpty) {
      _log.fine('_processLink: link is null or empty');
      return;
    }

    final userId = ref.read(userProvider)?.id;
    final planId = ref.read(planProvider)?.id;

    if (userId == null || planId == null) {
      _log.fine('_processLink: user or plan not loaded yet');
      return;
    }

    _checkForMealLinkAndNavigate(link);
  }

  Future<void> _checkForMealLinkAndNavigate(String link) async {
    const pattern = '/meal/';
    final indexPattern = link.indexOf(pattern);
    if (indexPattern == -1) {
      return;
    }

    final indexStart = indexPattern + pattern.length;
    var indexEnd = link.indexOf('?');
    if (indexEnd == -1) {
      indexEnd = link.length;
    }

    final mealId = link.substring(indexStart, indexEnd);
    final meal = await MealService.getMealById(mealId);
    if (meal == null || !mounted) {
      return;
    }

    _appRouter.push(MealScreenRoute(id: mealId));
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
