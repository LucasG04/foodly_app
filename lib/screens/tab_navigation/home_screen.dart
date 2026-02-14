import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:update_available/update_available.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import '../../app_router.gr.dart';
import '../../constants.dart';
import '../../providers/state_providers.dart';
import '../../services/foodly_user_service.dart';
import '../../services/in_app_purchase_service.dart';
import '../../services/plan_service.dart';
import '../../services/settings_service.dart';
import '../../services/version_service.dart';
import '../../utils/basic_utils.dart';
import '../../utils/main_snackbar.dart';
import '../../widgets/disposable_widget.dart';
import '../../widgets/new_version_modal.dart';
import '../../widgets/small_circular_progress_indicator.dart';
import 'home_screen_dialogs.dart';
import 'plan_history_view.dart';
import 'tab_navigation_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with DisposableWidget {
  final Logger _log = Logger('HomeScreen');
  final PageController _pageController = PageController(initialPage: 1);

  @override
  void initState() {
    _showAlerts();
    super.initState();
    ref
        .read(planHistoryPageChanged.notifier)
        .stream
        .listen((_) => _changePage())
        .canceledBy(this);

    Future.delayed(const Duration(seconds: 1), () {
      _checkPremiumGiftedStatusAndMessage();
    });
  }

  @override
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext _) {
    return Consumer(builder: (context, ref, _) {
      final initialUserLoading = ref.watch(initialUserLoadingProvider);
      final initialPlanLoading = ref.watch(initialPlanLoadingProvider);
      final user = ref.watch(userProvider);

      if (SettingsService.isFirstUsage) {
        AutoRouter.of(context).replace(const OnboardingScreenRoute());
        return const Scaffold();
      } else if (!initialUserLoading && user == null) {
        AutoRouter.of(context).replace(const AuthenticationScreenRoute());
        return const Scaffold();
      } else if (!initialUserLoading && !initialPlanLoading && user != null) {
        return _buildNavigationView();
      } else {
        return const Scaffold(
          body: Center(child: SmallCircularProgressIndicator()),
        );
      }
    });
  }

  Widget _buildNavigationView() {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.vertical,
      children: const [PlanHistoryView(), TabNavigationView()],
    );
  }

  void _changePage() {
    if (!_pageController.hasClients || _pageController.page == null) {
      return;
    }
    _pageController.animateToPage(
      _pageController.page == 0 ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.ease,
    );
  }

  Future<bool> _checkForNewFeaturesNotification() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String? lastCheckedVersionString = VersionService.lastCheckedVersion;

    _log.fine(
      '_checkForNewFeaturesNotification() with currentVersion: ${packageInfo.version} and lastcheckedversion: $lastCheckedVersionString',
    );

    if (lastCheckedVersionString == null) {
      await VersionService.setLastCheckedVersion(packageInfo.version);
      return false;
    }

    final Version currentVersion = Version.parse(packageInfo.version);
    final Version lastCheckedVersion = Version.parse(lastCheckedVersionString);

    if (lastCheckedVersion >= currentVersion) {
      return false;
    }

    if (!mounted) {
      return false;
    }
    NewVersionModal.open(context).then((_) {
      unawaited(VersionService.setLastCheckedVersion(packageInfo.version));
    });
    return true;
  }

  void _checkForUpdate() async {
    if (!_shouldCheckForUpdate()) {
      return;
    }
    await VersionService.setLastCheckedForUpdate(DateTime.now());

    if (Platform.isAndroid) {
      _checkForUpdateAndroid();
    } else if (Platform.isIOS || Platform.isMacOS) {
      _checkForUpdateIOS();
    }
  }

  bool _shouldCheckForUpdate() {
    if (foundation.kDebugMode) {
      return false;
    }
    final lastChecked = VersionService.lastCheckedForUpdate;
    if (lastChecked == null) {
      return true;
    }
    return DateTime.now().difference(lastChecked).inHours > 1;
  }

  void _checkForUpdateAndroid() async {
    AppUpdateInfo? updateInfo;

    try {
      updateInfo = await InAppUpdate.checkForUpdate();
    } catch (e) {
      _log.severe('ERR in InAppUpdate.checkForUpdate()', e);
    }

    if (updateInfo != null &&
        updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
      InAppUpdate.startFlexibleUpdate().then((_) {
        InAppUpdate.completeFlexibleUpdate().catchError((dynamic err) {
          _log.severe('ERR in InAppUpdate.completeFlexibleUpdate()', err);
        });
      }).catchError((dynamic err) {
        _log.severe('ERR in InAppUpdate.startFlexibleUpdate()', err);
      });
    }
  }

  void _checkForUpdateIOS() async {
    bool? available;

    try {
      final availability = await getUpdateAvailability();
      available = switch (availability) {
        UpdateAvailable() => true,
        NoUpdateAvailable() => false,
        UnknownAvailability() => false,
      };
    } catch (e) {
      _log.severe(
        'ERR in _checkForUpdateIOS() for getUpdateAvailability() or foldElse()',
        e,
      );
    }

    _log.fine('_checkForUpdateIOS() resulted in "$available"');

    if (available == null || !available) {
      return;
    }

    _showIOSUpdateDialog();
  }

  Future<void> _showIOSUpdateDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) => HomeScreenDialogs.updateDialogCupertino(
        context,
        onUpdate: () {
          Navigator.of(context).pop();
          _openAppStore();
        },
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _openAppStore() async {
    final url = Uri.parse('https://apps.apple.com/app/id$kAppBundleId');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  bool _checkUserShouldLockPlan() {
    if (!mounted) {
      return false;
    }
    final plan = ref.read(planProvider);
    if (plan == null) {
      return false;
    }
    final planIsLocked = plan.locked != null && plan.locked!;
    final lastUserJoinedIsFiveDaysAgo = plan.lastUserJoined != null &&
        plan.lastUserJoined!.difference(DateTime.now()).inDays.abs() > 5;
    final lastLockedChecked = PlanService.lastLockedChecked();
    final lastLockCheck2WeeksAgo = lastLockedChecked != null &&
        lastLockedChecked.difference(DateTime.now()).inDays.abs() > 14;

    if (planIsLocked ||
        !lastUserJoinedIsFiveDaysAgo ||
        !lastLockCheck2WeeksAgo) {
      return false;
    }
    PlanService.setLastLockedCheck();

    if (!mounted) {
      return false;
    }
    _showLockPlanAlert();
    return true;
  }

  void _showLockPlanAlert() {
    void onLock() {
      Navigator.of(context).pop();
      PlanService.lockPlan(ref.read(planProvider)!.id!);
    }

    void onDismiss() => Navigator.of(context).pop();

    showDialog<void>(
      context: context,
      builder: (context) => Platform.isIOS || Platform.isMacOS
          ? HomeScreenDialogs.lockPlanCupertino(
              context,
              onLock: onLock,
              onDismiss: onDismiss,
            )
          : HomeScreenDialogs.lockPlanMaterial(
              onLock: onLock,
              onDismiss: onDismiss,
              context: context,
            ),
    );
  }

  void _showAlerts() async {
    final newFeaturesShown = await _checkForNewFeaturesNotification();
    if (newFeaturesShown) {
      return;
    }

    if (_shouldCheckForUpdate()) {
      _checkForUpdate();
      return;
    }

    _checkUserShouldLockPlan();
  }

  Future<void> _checkPremiumGiftedStatusAndMessage() async {
    if (!mounted) {
      return;
    }

    final user = ref.read(userProvider);
    if (user == null || user.id == null) {
      return;
    }

    final userHasBoughtPremium =
        await InAppPurchaseService.getUserIsSubscribed();
    if (userHasBoughtPremium) {
      FoodlyUserService.resetPremiumGifted(user.id!);
      return;
    }

    final showMessage =
        user.isPremiumGifted == true && user.premiumGiftedMessageShown != true;
    if (showMessage && mounted) {
      BasicUtils.afterBuild(
        () => MainSnackbar(
          isSuccess: true,
          duration: 10,
          title: 'premium_gifted_msg_title'.tr(),
          message: 'premium_gifted_msg_message'
              .tr(args: [kAppName, user.premiumGiftedMonths.toString()]),
        ).show(context),
      );
      FoodlyUserService.setPremiumGiftedMessageShown(user.id!);
    }
  }
}
