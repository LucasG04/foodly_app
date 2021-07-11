import 'package:concentric_transition/page_route.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:share/share.dart';

import '../../../constants.dart';
import '../../../providers/state_providers.dart';
import '../../../services/authentication_service.dart';
import '../../../services/plan_service.dart';
import '../../../services/settings_service.dart';
import '../../../utils/basic_utils.dart';
import '../../../widgets/page_title.dart';
import '../../../widgets/small_circular_progress_indicator.dart';
import '../../onboarding/onboarding_screen.dart';
import 'help_slides/help_slide_share_import.dart';
import 'import_meals_modal.dart';
import 'settings_tile.dart';

class SettingsView extends StatefulWidget {
  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, watch, _) {
      final plan = watch(planProvider).state;
      final foodlyUser = watch(userProvider).state;
      return plan != null && foodlyUser != null
          ? SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: (MediaQuery.of(context).size.width -
                          BasicUtils.contentWidth(context)) /
                      2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: kPadding),
                    PageTitle(text: 'Einstellungen'),
                    _buildSectionTitle('Allgemein'),
                    _buildSection([
                      SettingsTile(
                        onTap: () => Navigator.push(
                          context,
                          ConcentricPageRoute(
                              builder: (_) => OnboardingScreen()),
                        ),
                        leadingIcon: EvaIcons.listOutline,
                        text: 'Mehrere Gerichte pro Mahlzeit',
                        trailing: Consumer(builder: (context, watch, _) {
                          return Switch.adaptive(
                            value: SettingsService.multipleMealsPerTime,
                            onChanged: (value) {
                              setState(() {
                                SettingsService.setMultipleMealsPerTime(value);
                              });
                            },
                          );
                        }),
                      ),
                    ], context),
                    _buildSectionTitle('Plan'),
                    _buildSection([
                      SettingsTile(
                        onTap: () => _shareCode(plan.code),
                        leadingIcon: EvaIcons.shareOutline,
                        text: 'Plan teilen (${plan.code})',
                        trailing: Icon(EvaIcons.arrowIosForwardOutline),
                      ),
                      SettingsTile(
                        onTap: () => _leavePlan(plan.id, context),
                        leadingIcon: EvaIcons.closeCircleOutline,
                        text: 'Plan verlassen',
                        trailing: Icon(
                          EvaIcons.arrowIosForwardOutline,
                          color: Colors.red,
                        ),
                        color: Colors.red,
                      ),
                    ], context),
                    foodlyUser != null && foodlyUser.oldPlans.length > 1
                        ? _buildSectionTitle('Gerichte')
                        : SizedBox(),
                    foodlyUser != null && foodlyUser.oldPlans.length > 1
                        ? _buildSection([
                            SettingsTile(
                              onTap: () => _importMeals(
                                foodlyUser.oldPlans
                                    .where((id) => id != plan.id)
                                    .toList(),
                                context,
                              ),
                              leadingIcon: EvaIcons.downloadOutline,
                              text: 'Alte Gerichte importieren',
                              trailing: Icon(EvaIcons.arrowIosForwardOutline),
                            ),
                          ], context)
                        : SizedBox(),
                    _buildSectionTitle('Hilfe'),
                    _buildSection([
                      SettingsTile(
                        onTap: () => Navigator.push(
                          context,
                          ConcentricPageRoute(
                              builder: (_) => OnboardingScreen()),
                        ),
                        leadingIcon: EvaIcons.questionMarkCircleOutline,
                        text: 'Einführung anzeigen',
                        trailing: Icon(EvaIcons.arrowIosForwardOutline),
                      ),
                      SettingsTile(
                        onTap: () => Navigator.push(
                          context,
                          ConcentricPageRoute(
                            builder: (_) => HelpSlideShareImport(),
                          ),
                        ),
                        leadingIcon: EvaIcons.questionMarkCircleOutline,
                        text: 'Rezepte importieren',
                        trailing: Icon(EvaIcons.arrowIosForwardOutline),
                      ),
                    ], context),
                  ],
                ),
              ),
            )
          : Center(child: SmallCircularProgressIndicator());
    });
  }

  Widget _buildSection(List<Widget> widgets, BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      margin: const EdgeInsets.only(bottom: kPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).dialogBackgroundColor,
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(kPadding, 8, kPadding, 0),
        child: Wrap(children: widgets),
      ),
    );
  }

  Container _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          0,
          kPadding / 4,
          kPadding,
          kPadding / 2,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.start,
        ),
      ),
    );
  }

  void _shareCode(String code) {
    Share.share('Tritt meinem Essensplan bei Foodly mit dem Code "$code" bei.');
  }

  void _leavePlan(String planId, context) async {
    String userId = AuthenticationService.currentUser.uid;
    await PlanService.leavePlan(planId, userId);
    AuthenticationService.signOut();
    BasicUtils.clearAllProvider(context);
  }

  void _importMeals(List<String> planIds, context) async {
    showBarModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      context: context,
      builder: (context) => ImportMealsModal(planIds),
    );
  }
}
