import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
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
import '../../services/settings_service.dart';
import '../../services/version_service.dart';
import '../../widgets/new_version_modal.dart';
import '../../widgets/small_circular_progress_indicator.dart';
import 'tab_navigation_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Logger _log = Logger('HomeScreen');

  @override
  void initState() {
    _checkForNewFeaturesNotification();
    _checkForUpdate();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, watch, _) {
      final initialUserLoading = watch(initialUserLoadingProvider).state;
      final user = watch(userProvider).state;
      if (initialUserLoading) {
        return const Scaffold(
          body: Center(child: SmallCircularProgressIndicator()),
        );
      } else if (user != null) {
        return const TabNavigationView();
      } else if (SettingsService.isFirstUsage) {
        AutoRouter.of(context).replace(OnboardingScreenRoute());
        return const Scaffold();
      } else {
        AutoRouter.of(context).replace(const AuthenticationScreenRoute());
        return const Scaffold();
      }
    });
  }

  void _checkForNewFeaturesNotification() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String? lastCheckedVersionString = VersionService.lastCheckedVersion;

    _log.fine(
      '_checkForNewFeaturesNotification() with currentVersion: ${packageInfo.version} and lastcheckedversion: $lastCheckedVersionString',
    );

    if (lastCheckedVersionString == null) {
      VersionService.lastCheckedVersion = packageInfo.version;
      return;
    }

    final Version currentVersion = Version.parse(packageInfo.version);
    final Version lastCheckedVersion = Version.parse(lastCheckedVersionString);

    if (lastCheckedVersion >= currentVersion) {
      return;
    }

    if (!mounted) {
      return;
    }
    NewVersionModal.open(context).then((_) {
      VersionService.lastCheckedVersion = packageInfo.version;
    });
  }

  void _checkForUpdate() async {
    if (!_shouldCheckForUpdate()) {
      return;
    }
    VersionService.lastCheckedForUpdate = DateTime.now();

    if (Platform.isAndroid) {
      _checkForUpdateAndroid();
    } else if (Platform.isIOS) {
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
    final availability = await getUpdateAvailability();
    final available =
        availability.foldElse(available: () => true, orElse: () => false);

    _log.fine('_checkForUpdateIOS() resulted in "$available"');

    if (!available) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Column(
          children: <Widget>[
            Text('update_dialog_title'.tr(args: [kAppName])),
          ],
        ),
        content: Column(
          children: [
            const SizedBox(height: kPadding / 2),
            Text('update_dialog_description'.tr()),
            Text('update_dialog_question'.tr()),
          ],
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            isDestructiveAction: true,
            child: Text('update_dialog_action_later'.tr().toUpperCase()),
          ),
          CupertinoDialogAction(
            onPressed: () {
              _openAppStore();
              Navigator.of(context).pop();
            },
            isDefaultAction: true,
            child: Text('update_dialog_action_update'.tr().toUpperCase()),
          ),
        ],
      ),
    );
  }

  void _openAppStore() async {
    final url = Uri.parse('https://apps.apple.com/app/id$kAppBundleId');
    if (await canLaunchUrl(url)) {
      launchUrl(url);
    }
  }
}
