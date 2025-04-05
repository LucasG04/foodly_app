import 'package:auto_route/auto_route.dart';
import 'package:concentric_transition/concentric_transition.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../app_router.gr.dart';
import '../../constants.dart';
import '../../models/page_data.dart';
import '../../services/authentication_service.dart';
import '../../services/settings_service.dart';
import '../../widgets/page_card.dart';
import '../authentication/authentication_screen.dart';
import 'onboarding_keys.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final List<PageData> pages = [
    PageData(
      assetPath: 'assets/onboarding/welcome.png',
      title: 'onboarding_one_title'.tr(args: [kAppName]),
      subtitle: 'onboarding_one_subtitle'.tr(args: [kAppName]),
      background: const Color(0xFFeb3b5a),
    ),
    PageData(
      assetPath: 'assets/onboarding/scrum.png',
      title: 'onboarding_two_title'.tr(),
      subtitle: 'onboarding_two_subtitle'.tr(),
      background: const Color(0xFF2d98da),
    ),
    PageData(
      assetPath: 'assets/onboarding/shopping.png',
      title: 'onboarding_three_title'.tr(),
      subtitle: 'onboarding_three_subtitle'.tr(),
      background: const Color(0xFF0043D0),
    ),
    PageData(
      assetPath: 'assets/onboarding/cooking.png',
      title: 'onboarding_four_title'.tr(),
      subtitle: 'onboarding_four_subtitle'.tr(),
      background: const Color(0xFFf7b731),
    ),
    PageData(
      assetPath: 'assets/onboarding/rocket.png',
      title: 'onboarding_five_title'.tr(),
      subtitle: 'onboarding_five_subtitle'.tr(args: [kAppName]),
      background: const Color(0xFF20bf6b),
    ),
  ];

  List<Color> get _colors => pages.map((p) => p.background).toList();

  @override
  Widget build(BuildContext context) {
    const heightMultiplier = 0.75;
    return Scaffold(
      body: ConcentricPageView(
        colors: _colors,
        radius: 30,
        curve: Curves.ease,
        duration: const Duration(seconds: 1),
        // ignore: avoid_redundant_argument_values
        verticalPosition: heightMultiplier,
        onFinish: () => _finishOnboarding(context),
        buttonChild: Center(
          key: OnboardingKeys.buttonNext,
          child: const Icon(
            EvaIcons.arrowForwardOutline,
            color: Colors.white,
          ),
        ),
        itemCount: pages.length,
        itemBuilder: (index, value) {
          return PageCard(
            page: pages[index],
            height: MediaQuery.of(context).size.height * heightMultiplier,
          );
        },
      ),
    );
  }

  Future<void> _finishOnboarding(BuildContext context) async {
    if (SettingsService.isFirstUsage) {
      SettingsService.setFirstUsageFalse();
    }

    if (AuthenticationService.currentUser == null) {
      Navigator.push(
        context,
        ConcentricPageRoute<AuthenticationScreen>(
          builder: (_) => const AuthenticationScreen(),
        ),
      );
    } else {
      final popSucceeded = await AutoRouter.of(context).pop();
      if (!popSucceeded && context.mounted) {
        AutoRouter.of(context).replace(const HomeScreenRoute());
      }
    }
  }
}
