import 'package:auto_route/auto_route.dart';
import 'package:concentric_transition/concentric_transition.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodly/services/authentication_service.dart';
import 'package:foodly/services/settings_service.dart';

import '../authentication/authentication_screen.dart';
import '../../widgets/page_card.dart';
import '../../models/page_data.dart';

class OnboardingScreen extends StatelessWidget {
  final List<PageData> pages = [
    PageData(
      assetPath: 'assets/onboarding/welcome.png',
      title: 'Danke, dass du Foodly verwendest.',
      subtitle:
          'Foodly verbindet für dich deinen Essensplan, Einkaufsliste und Kochbuch.',
      background: Color(0xFFeb3b5a),
    ),
    PageData(
      assetPath: 'assets/onboarding/scrum.png',
      title: 'Essensplan',
      subtitle:
          'Plane & organisiere dein Essen für die nächste Woche. So sparst du Zeit und Geld.',
      background: Color(0xFF2d98da),
    ),
    PageData(
      assetPath: 'assets/onboarding/shopping.png',
      title: 'Einkaufsliste',
      subtitle:
          'Nutze gemeinsam mit deinen Mitbewohnern eine Liste und bleib so immer organisiert.',
      background: Color(0xFF0043D0),
    ),
    PageData(
      assetPath: 'assets/onboarding/cooking.png',
      title: 'Kochbuch',
      subtitle:
          'Hab alle deine Lieblingsgerichte an einem Ort, verwende öffentliche aus der Community und importiere sie von bekannten Webseiten.',
      background: Color(0xFFf7b731),
    ),
    PageData(
      assetPath: 'assets/onboarding/rocket.png',
      title: 'Zu guter Letzt',
      subtitle:
          'Um Foodly zu verwenden, musst du dich registrieren, um einen Plan zu erstellen oder einem beizutreten. Deine E-Mail wird hierbei nur verwendet, um deine Einstellungen zu speichern.',
      background: Color(0xFF20bf6b),
    ),
  ];

  List<Color> get _colors => pages.map((p) => p.background).toList();

  @override
  Widget build(BuildContext context) {
    final heightMultiplier = 0.75;
    return Scaffold(
      body: ConcentricPageView(
        colors: _colors,
        radius: 30,
        curve: Curves.ease,
        duration: Duration(seconds: 1),
        verticalPosition: heightMultiplier,
        onFinish: () => _finishOnboarding(context),
        buttonChild: Center(
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

  void _finishOnboarding(context) {
    if (SettingsService.isFirstUsage) {
      SettingsService.setFirstUsageFalse();
    }

    if (AuthenticationService.currentUser == null) {
      Navigator.pushReplacement(
        context,
        ConcentricPageRoute(builder: (_) => AuthenticationScreen()),
      );
    } else {
      ExtendedNavigator.root.pop();
    }
  }
}
