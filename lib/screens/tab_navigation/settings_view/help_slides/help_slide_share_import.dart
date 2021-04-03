import 'package:auto_route/auto_route.dart';
import 'package:concentric_transition/concentric_transition.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodly/models/page_data.dart';
import 'package:foodly/widgets/page_card.dart';

class HelpSlideShareImport extends StatelessWidget {
  final List<PageData> pages = [
    PageData(
      assetPath: 'assets/onboarding/welcome.png',
      title: 'Rezepte importieren.',
      subtitle:
          'Du musst zum Glück nicht all deine Rezepte per Hand eintippen. In diesem kurzen Guide wird dir gezeigt wie!',
      background: Color(0xFFf05945),
    ),
    PageData(
      assetPath: 'assets/help_slide/share-button.png',
      title: 'Über Chefkoch',
      subtitle:
          'Öffne Chefkoch und wähle das Rezept aus, das du importieren möchtest. Klicken dann auf das "Teilen" Icon.',
      background: Color(0xFF5eaaa8),
    ),
    PageData(
      assetPath: 'assets/help_slide/share-app.png',
      title: 'Über Chefkoch',
      subtitle: 'Wähle danach aus der Liste die "Foodly" App aus.',
      background: Color(0xFFffb037),
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
        onFinish: () => ExtendedNavigator.root.pop(),
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
}
