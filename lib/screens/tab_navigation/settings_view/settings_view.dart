import 'package:concentric_transition/page_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodly/screens/tab_navigation/settings_view/loading_logout.dart';
import 'package:foodly/utils/main_snackbar.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:share/share.dart';

import '../../../constants.dart';
import '../../../providers/state_providers.dart';
import '../../../services/authentication_service.dart';
import '../../../services/plan_service.dart';
import '../../../services/settings_service.dart';
import '../../../utils/basic_utils.dart';
import '../../../widgets/page_title.dart';
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
      final firebaseUser = AuthenticationService.currentUser;
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
                    PageTitle(text: 'settings_title'.tr()),
                    _buildSectionTitle('settings_section_general'.tr()),
                    _buildSection([
                      SettingsTile(
                        onTap: () => Navigator.push(
                          context,
                          ConcentricPageRoute(
                              builder: (_) => OnboardingScreen()),
                        ),
                        leadingIcon: EvaIcons.listOutline,
                        text: 'settings_section_general_multiple_meals'.tr(),
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
                    _buildSectionTitle('settings_section_plan'.tr()),
                    _buildSection([
                      SettingsTile(
                        onTap: () => _shareCode(plan.code),
                        leadingIcon: EvaIcons.shareOutline,
                        text:
                            'settings_section_plan_share'.tr(args: [plan.code]),
                        trailing: Icon(EvaIcons.arrowIosForwardOutline),
                      ),
                      SettingsTile(
                        onTap: () => _leavePlan(plan.id, context),
                        leadingIcon: EvaIcons.closeCircleOutline,
                        text: 'settings_section_plan_leave'.tr(),
                        trailing: Icon(
                          EvaIcons.arrowIosForwardOutline,
                          color: Colors.red,
                        ),
                        color: Colors.red,
                      ),
                    ], context),
                    foodlyUser != null && foodlyUser.oldPlans.length > 1
                        ? _buildSectionTitle('settings_section_meals'.tr())
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
                              text: 'settings_section_meals_import'.tr(),
                              trailing: Icon(EvaIcons.arrowIosForwardOutline),
                            ),
                          ], context)
                        : SizedBox(),
                    _buildSectionTitle('settings_section_help'.tr()),
                    _buildSection([
                      SettingsTile(
                        onTap: () => Navigator.push(
                          context,
                          ConcentricPageRoute(
                              builder: (_) => OnboardingScreen()),
                        ),
                        leadingIcon: EvaIcons.questionMarkCircleOutline,
                        text: 'settings_section_help_intro'.tr(),
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
                        text: 'settings_section_help_import'.tr(),
                        trailing: Icon(EvaIcons.arrowIosForwardOutline),
                      ),
                    ], context),
                    _buildSectionTitle('settings_section_account'.tr()),
                    _buildSection([
                      SettingsTile(
                        onTap: () async {
                          await AuthenticationService.resetPassword(
                              firebaseUser.email);
                          MainSnackbar(
                            message: 'settings_section_account_reset_msg'.tr(),
                            isSuccess: true,
                          ).show(context);
                        },
                        leadingIcon: EvaIcons.lockOutline,
                        text: 'settings_section_account_reset'.tr(),
                        trailing: Icon(EvaIcons.arrowIosForwardOutline),
                      ),
                      SettingsTile(
                        onTap: () => AuthenticationService.signOut(),
                        leadingIcon: EvaIcons.logOutOutline,
                        text: 'settings_section_account_logout'.tr(),
                        trailing: Icon(
                          EvaIcons.arrowIosForwardOutline,
                          color: Colors.red,
                        ),
                        color: Colors.red,
                      ),
                    ], context),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyText1,
                        children: <TextSpan>[
                          TextSpan(text: 'settings_sign_in_as'.tr()),
                          TextSpan(
                            text: '\n' + firebaseUser.email,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: kPadding),
                  ],
                ),
              ),
            )
          : LoadingLogut();
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
    Share.share('settings_share_msg'.tr(args: [kAppName, code]));
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
