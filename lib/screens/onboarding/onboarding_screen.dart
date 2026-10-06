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
import '../../utils/analytics.dart';
import '../../widgets/page_card.dart';
import '../authentication/authentication_screen.dart';
import 'onboarding_keys.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  List<PageData> _pages(BuildContext context) => [
        PageData(
          assetPath: 'assets/onboarding/welcome.png',
          title: context.tr('onboarding_one_title', args: [kAppName]),
          subtitle: context.tr('onboarding_one_subtitle', args: [kAppName]),
          background: const Color(0xFFeb3b5a),
        ),
        PageData(
          assetPath: 'assets/onboarding/scrum.png',
          title: context.tr('onboarding_two_title'),
          subtitle: context.tr('onboarding_two_subtitle'),
          background: const Color(0xFF2d98da),
        ),
        PageData(
          assetPath: 'assets/onboarding/shopping.png',
          title: context.tr('onboarding_three_title'),
          subtitle: context.tr('onboarding_three_subtitle'),
          background: const Color(0xFF0043D0),
        ),
        PageData(
          assetPath: 'assets/onboarding/cooking.png',
          title: context.tr('onboarding_four_title'),
          subtitle: context.tr('onboarding_four_subtitle'),
          background: const Color(0xFFf7b731),
        ),
        PageData(
          assetPath: 'assets/onboarding/rocket.png',
          title: context.tr('onboarding_five_title'),
          subtitle: context.tr('onboarding_five_subtitle', args: [kAppName]),
          background: const Color(0xFF20bf6b),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    const heightMultiplier = 0.75;
    final pages = _pages(context);
    return Scaffold(
      body: ConcentricPageView(
        colors: pages.map((p) => p.background).toList(),
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
            height: MediaQuery.sizeOf(context).height * heightMultiplier,
          );
        },
      ),
    );
  }

  Future<void> _finishOnboarding(BuildContext context) async {
    logEvent(
      AnalyticsEvent.onboardingComplete,
      {'firstUsage': SettingsService.isFirstUsage.toString()},
    );
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
