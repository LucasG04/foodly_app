import 'package:auto_route/auto_route.dart';
import 'package:concentric_transition/concentric_transition.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import '../../../../constants.dart';

import '../../../../models/page_data.dart';
import '../../../../widgets/page_card.dart';

class HelpSlideShareImport extends StatelessWidget {
  final List<PageData> pages = [
    PageData(
      assetPath: 'assets/onboarding/welcome.png',
      title: 'settings_help_share_one_title'.tr(),
      subtitle: 'settings_help_share_one_subtitle'.tr(),
      background: const Color(0xFFf05945),
    ),
    PageData(
      assetPath: 'assets/help_slide/share-button.png',
      title: 'settings_help_share_two_title'.tr(),
      subtitle: 'settings_help_share_two_subtitle'.tr(),
      background: const Color(0xFF5eaaa8),
    ),
    PageData(
      assetPath: 'assets/help_slide/share-app.png',
      title: 'settings_help_share_three_title'.tr(),
      subtitle: 'settings_help_share_three_subtitle'.tr(args: [kAppName]),
      background: const Color(0xFFffb037),
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
        onFinish: () => AutoRouter.of(context).pop(),
        buttonChild: const Center(
          child: Icon(
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
}
