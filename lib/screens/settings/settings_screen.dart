import 'package:auto_route/auto_route.dart';
import 'package:concentric_transition/page_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

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
import '../../models/plan.dart';
import '../../widgets/main_appbar.dart';
import '../onboarding/onboarding_screen.dart';
import 'change_plan_name_modal.dart';
import 'help_slides/help_slide_share_import.dart';
import 'import_meals_modal.dart';
import 'settings_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        text: 'settings_title'.tr(),
        scrollController: _scrollController,
      ),
      body: Consumer(
        builder: (context, watch, _) {
          final plan = watch(planProvider).state;
          final foodlyUser = watch(userProvider).state;
          final firebaseUser = AuthenticationService.currentUser;
          return plan != null && foodlyUser != null && !isLoading
              ? SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: (MediaQuery.of(context).size.width -
                              BasicUtils.contentWidth(context)) /
                          2,
                    ),
                    child: Column(
                      children: [
                        _buildSectionTitle('settings_section_general'.tr()),
                        _buildSection([
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
                        _buildSectionTitle(
                          'settings_section_customization'.tr(),
                        ),
                        _buildSection([
                          SettingsTile(
                            leadingIcon: EvaIcons.listOutline,
                            text:
                                'settings_section_customization_multiple_meals'
                                    .tr(),
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
                            leadingIcon: EvaIcons.trendingUpOutline,
                            text: 'settings_section_customization_suggestions'
                                .tr(),
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
                            leadingIcon: EvaIcons.trash2Outline,
                            text: 'settings_section_customization_remove_bought'
                                .tr(),
                            trailing: Consumer(builder: (context, watch, _) {
                              return Switch.adaptive(
                                value: SettingsService.removeBoughtImmediately,
                                onChanged: (value) {
                                  setState(() {
                                    SettingsService.setRemoveBoughtImmediately(
                                        value);
                                  });
                                },
                              );
                            }),
                          ),
                        ], context),
                        _buildSectionTitle('settings_section_plan'.tr()),
                        _buildSection([
                          SettingsTile(
                            onTap: _openChangePlanNameModal,
                            leadingIcon: Icons.abc_rounded,
                            text: 'settings_section_plan_change_name'.tr(),
                            trailing:
                                const Icon(EvaIcons.arrowIosForwardOutline),
                          ),
                          SettingsTile(
                            onTap: () => _shareCode(plan.code!, plan.locked),
                            leadingIcon: EvaIcons.shareOutline,
                            text: 'settings_section_plan_share'
                                .tr(args: [plan.code!]),
                            trailing:
                                const Icon(EvaIcons.arrowIosForwardOutline),
                          ),
                          SettingsTile(
                            onTap: () => _changePlanCode(plan),
                            leadingIcon: EvaIcons.hashOutline,
                            text: 'settings_section_plan_change_code'.tr(),
                            trailing:
                                const Icon(EvaIcons.arrowIosForwardOutline),
                          ),
                          SettingsTile(
                            leadingIcon: EvaIcons.lockOutline,
                            text: 'settings_section_plan_change_locked'.tr(),
                            trailing: Switch.adaptive(
                              value: plan.locked ?? false,
                              onChanged: (value) =>
                                  _changePlanLockState(plan, value),
                            ),
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
                            trailing:
                                const Icon(EvaIcons.arrowIosForwardOutline),
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
                            trailing:
                                const Icon(EvaIcons.arrowIosForwardOutline),
                          ),
                          SettingsTile(
                            onTap: () => AutoRouter.of(context)
                                .push(const FeedbackScreenRoute()),
                            leadingIcon: EvaIcons.paperPlaneOutline,
                            text: 'settings_section_help_support'.tr(),
                            trailing:
                                const Icon(EvaIcons.arrowIosForwardOutline),
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
                            trailing:
                                const Icon(EvaIcons.arrowIosForwardOutline),
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
                        RichText(
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
                        const SizedBox(height: kPadding),
                      ],
                    ),
                  ),
                )
              : const LoadingLogut();
        },
      ),
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

  void _shareCode(String code, bool? isPlanLocked) async {
    await Share.share(
      'settings_share_msg'.tr(args: [kAppName, code]),
      subject: 'settings_share_msg'.tr(args: [kAppName, code]),
    );
    if (isPlanLocked != null && isPlanLocked && mounted) {
      MainSnackbar(
        message: 'settings_share_plan_locked'.tr(),
        infinite: true,
      ).show(context);
    }
  }

  Future<void> _changePlanCode(Plan plan) async {
    setState(() {
      isLoading = true;
    });
    String code = PlanService.generateCode();
    while ((await PlanService.getPlanById(code)) != null) {
      code = PlanService.generateCode();
    }
    plan.code = code;
    await PlanService.updatePlan(plan);
    if (!mounted) {
      return;
    }
    setState(() {
      isLoading = false;
    });
    context.read(planProvider).state = plan;
  }

  Future<void> _changePlanLockState(Plan plan, bool locked) async {
    setState(() {
      isLoading = true;
    });
    plan.locked = locked;
    await PlanService.updatePlan(plan);
    if (!mounted) {
      return;
    }
    setState(() {
      isLoading = false;
    });
    context.read(planProvider).state = plan;
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
}
