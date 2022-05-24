import 'package:auto_route/auto_route.dart';
import 'package:concentric_transition/page_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share/share.dart';

import '../../../app_router.gr.dart';
import '../../../constants.dart';
import '../../../providers/state_providers.dart';
import '../../../services/authentication_service.dart';
import '../../../services/plan_service.dart';
import '../../../services/settings_service.dart';
import '../../../utils/basic_utils.dart';
import '../../../utils/main_snackbar.dart';
import '../../../utils/widget_utils.dart';
import '../../../widgets/loading_logout.dart';
import '../../../widgets/log_view.dart';
import '../../../widgets/page_title.dart';
import '../../onboarding/onboarding_screen.dart';
import 'change_plan_name_modal.dart';
import 'help_slides/help_slide_share_import.dart';
import 'import_meals_modal.dart';
import 'settings_tile.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);
  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, watch, _) {
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
                    children: [
                      const SizedBox(height: kPadding),
                      PageTitle(text: 'settings_title'.tr()),
                      _buildSectionTitle('settings_section_general'.tr()),
                      _buildSection([
                        SettingsTile(
                          onTap: () => Navigator.push(
                            context,
                            ConcentricPageRoute<OnboardingScreen>(
                                builder: (_) => OnboardingScreen()),
                          ),
                          leadingIcon: EvaIcons.listOutline,
                          text: 'settings_section_general_multiple_meals'.tr(),
                          trailing: Consumer(builder: (context, watch, _) {
                            return Switch.adaptive(
                              value: SettingsService.multipleMealsPerTime,
                              onChanged: (value) {
                                setState(() {
                                  SettingsService.setMultipleMealsPerTime(
                                      value);
                                });
                              },
                            );
                          }),
                        ),
                        SettingsTile(
                          onTap: () => Navigator.push(
                            context,
                            ConcentricPageRoute<OnboardingScreen>(
                                builder: (_) => OnboardingScreen()),
                          ),
                          leadingIcon: EvaIcons.trendingUpOutline,
                          text: 'settings_section_general_suggestions'.tr(),
                          trailing: Consumer(builder: (context, watch, _) {
                            return Switch.adaptive(
                              value: SettingsService.showSuggestions,
                              onChanged: (value) {
                                setState(() {
                                  SettingsService.setShowSuggestions(value);
                                });
                              },
                            );
                          }),
                        ),
                        SettingsTile(
                          leadingIcon: EvaIcons.globe2Outline,
                          text: 'settings_section_general_language'.tr(),
                          trailing: DropdownButton<Locale>(
                            value: context.locale,
                            items: context.supportedLocales
                                .map((locale) => DropdownMenuItem<Locale>(
                                      value: locale,
                                      child: Text(
                                        LocaleNames.of(context)!
                                            .nameOf(locale.languageCode)!,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (Locale? locale) async {
                              await context.setLocale(locale!);
                            },
                          ),
                        ),
                      ], context),
                      _buildSectionTitle('settings_section_plan'.tr()),
                      _buildSection([
                        SettingsTile(
                          onTap: _openChangePlanNameModal,
                          leadingIcon: Icons.abc_rounded,
                          text: 'settings_section_plan_change_name'.tr(),
                          trailing: const Icon(EvaIcons.arrowIosForwardOutline),
                        ),
                        SettingsTile(
                          onTap: () => _shareCode(plan.code!),
                          leadingIcon: EvaIcons.shareOutline,
                          text: 'settings_section_plan_share'
                              .tr(args: [plan.code!]),
                          trailing: const Icon(EvaIcons.arrowIosForwardOutline),
                        ),
                        SettingsTile(
                          onTap: () => _leavePlan(plan.id, context),
                          leadingIcon: EvaIcons.closeCircleOutline,
                          text: 'settings_section_plan_leave'.tr(),
                          trailing: const Icon(
                            EvaIcons.arrowIosForwardOutline,
                            color: Colors.red,
                          ),
                          color: Colors.red,
                        ),
                      ], context),
                      if (foodlyUser.oldPlans!.length > 1)
                        _buildSectionTitle('settings_section_meals'.tr())
                      else
                        const SizedBox(),
                      if (foodlyUser.oldPlans!.length > 1)
                        _buildSection([
                          SettingsTile(
                            onTap: () => _importMeals(
                              foodlyUser.oldPlans!
                                  .where((id) => id != plan.id)
                                  .toList(),
                              context,
                            ),
                            leadingIcon: EvaIcons.downloadOutline,
                            text: 'settings_section_meals_import'.tr(),
                            trailing:
                                const Icon(EvaIcons.arrowIosForwardOutline),
                          ),
                        ], context)
                      else
                        const SizedBox(),
                      _buildSectionTitle('settings_section_help'.tr()),
                      _buildSection([
                        SettingsTile(
                          onTap: () => Navigator.push(
                            context,
                            ConcentricPageRoute<OnboardingScreen>(
                                builder: (_) => OnboardingScreen()),
                          ),
                          leadingIcon: EvaIcons.questionMarkCircleOutline,
                          text: 'settings_section_help_intro'.tr(),
                          trailing: const Icon(EvaIcons.arrowIosForwardOutline),
                        ),
                        SettingsTile(
                          onTap: () => Navigator.push(
                            context,
                            ConcentricPageRoute<HelpSlideShareImport>(
                              builder: (_) => HelpSlideShareImport(),
                            ),
                          ),
                          leadingIcon: EvaIcons.questionMarkCircleOutline,
                          text: 'settings_section_help_import'.tr(),
                          trailing: const Icon(EvaIcons.arrowIosForwardOutline),
                        ),
                        SettingsTile(
                          onTap: () => AutoRouter.of(context)
                              .push(const FeedbackScreenRoute()),
                          leadingIcon: EvaIcons.paperPlaneOutline,
                          text: 'settings_section_help_support'.tr(),
                          trailing: const Icon(EvaIcons.arrowIosForwardOutline),
                        ),
                      ], context),
                      _buildSectionTitle('settings_section_account'.tr()),
                      _buildSection([
                        SettingsTile(
                          onTap: () async {
                            await AuthenticationService.resetPassword(
                                firebaseUser!.email!);
                            if (!mounted) {
                              return;
                            }
                            MainSnackbar(
                              message:
                                  'settings_section_account_reset_msg'.tr(),
                              isSuccess: true,
                            ).show(context);
                          },
                          leadingIcon: EvaIcons.lockOutline,
                          text: 'settings_section_account_reset'.tr(),
                          trailing: const Icon(EvaIcons.arrowIosForwardOutline),
                        ),
                        SettingsTile(
                          onTap: () => AuthenticationService.signOut(),
                          leadingIcon: EvaIcons.logOutOutline,
                          text: 'settings_section_account_logout'.tr(),
                          trailing: const Icon(
                            EvaIcons.arrowIosForwardOutline,
                            color: Colors.red,
                          ),
                          color: Colors.red,
                        ),
                      ], context),
                      GestureDetector(
                        onDoubleTap: _openLogView,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyText1,
                            children: <TextSpan>[
                              TextSpan(text: 'settings_sign_in_as'.tr()),
                              TextSpan(
                                text: '\n${firebaseUser!.email!}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: kPadding),
                    ],
                  ),
                ),
              )
            : const LoadingLogut();
      },
    );
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

  SizedBox _buildSectionTitle(String title) {
    return SizedBox(
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
          style: const TextStyle(
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

  void _leavePlan(String? planId, BuildContext context) {
    final String userId = AuthenticationService.currentUser!.uid;
    PlanService.leavePlan(planId, userId).then((_) {
      AuthenticationService.signOut();
      BasicUtils.clearAllProvider(context);
    });
  }

  void _importMeals(List<String?> planIds, BuildContext context) {
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => ImportMealsModal(planIds),
    );
  }

  void _openChangePlanNameModal() {
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => const ChangePlanNameModal(),
    );
  }

  void _openLogView() {
    if (!kLogViewEnabled) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<LogView>(
        builder: (context) => const LogView(),
      ),
    );
  }
}
