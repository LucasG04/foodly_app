import 'package:auto_route/auto_route.dart';
import 'package:concentric_transition/page_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../../models/shopping_list_sort.dart';
import '../../services/foodly_user_service.dart';
import '../../services/in_app_purchase_service.dart';
import '../../utils/analytics.dart';
import '../../utils/of_context_mixin.dart';
import '../../utils/permission_utils.dart';
import '../../widgets/ai_consent_sheet.dart';
import '../../widgets/get_premium_modal.dart';
import '../../widgets/main_appbar.dart';
import '../../widgets/options_modal/options_modal.dart';
import '../../widgets/options_modal/options_modal_option.dart';
import '../../widgets/small_circular_progress_indicator.dart';
import '../onboarding/onboarding_screen.dart';
import 'change_meal_types_modal.dart';
import 'change_plan_name_modal.dart';
import 'help_slides/help_slide_share_import.dart';
import 'import_meals_modal.dart';
import 'settings_alerts.dart';
import 'settings_change_primary_color_modal.dart';
import 'settings_mcp_token_modal.dart';
import 'settings_reauthenticate_modal.dart';
import 'settings_tile.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with OfContextMixin {
  final Logger _log = Logger('SettingsScreen');
  final ScrollController _scrollController = ScrollController();
  final _$loadingChangePlanLockState =
      AutoDisposeStateProvider<bool>((_) => false);
  bool isLoading = false;

  List<_ShoppingListSortValue> get shoppingListSorts => [
        _ShoppingListSortValue(
          ShoppingListSort.name,
          context.tr('shopping_list_sort_name'),
        ),
        _ShoppingListSortValue(
          ShoppingListSort.group,
          context.tr('shopping_list_sort_group'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(
        text: context.tr('settings_title'),
        scrollController: _scrollController,
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final plan = ref.watch(planProvider);
          final foodlyUser = ref.watch(userProvider);
          final firebaseUser = AuthenticationService.currentUser;
          return plan != null && foodlyUser != null && !isLoading
              ? SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          (mediaSize.width - BasicUtils.contentWidth(context)) /
                              2,
                    ),
                    child: Column(
                      children: [
                        _buildSectionTitle(
                            context.tr('settings_section_general')),
                        _buildSection([
                          SettingsTile(
                            leadingIcon: EvaIcons.globe2Outline,
                            text:
                                context.tr('settings_section_general_language'),
                            value: _localeName(context.locale),
                            onTap: _openLanguagePicker,
                          ),
                          WidgetUtils.userIsSubscribed(
                            ref: ref,
                            negate: true,
                            child: SettingsTile(
                              onTap: _openGetPremium,
                              leadingIcon: EvaIcons.awardOutline,
                              text: context.tr(
                                  'settings_section_general_premium',
                                  args: ['✨']),
                              trailing: const Icon(
                                EvaIcons.arrowIosForwardOutline,
                              ),
                              colorIcon: kPremiumColor,
                              gradientBorder: true,
                            ),
                          ),
                          if (PermissionUtils.allowedToModerate(foodlyUser))
                            SettingsTile(
                              leadingIcon: EvaIcons.code,
                              text: context
                                  .tr('settings_section_general_use_dev_api'),
                              trailing: StreamBuilder<bool>(
                                initialData: SettingsService.useDevApi,
                                stream: SettingsService.streamUseDevApi(),
                                builder: (context, snapshot) {
                                  return Switch.adaptive(
                                    value: snapshot.data!,
                                    onChanged: (value) {
                                      SettingsService.setUseDevApi(value);
                                    },
                                  );
                                },
                              ),
                            ),
                        ], context),
                        _buildSectionTitle(
                          context.tr('settings_section_customization'),
                        ),
                        _buildSection([
                          SettingsTile(
                            leadingIcon: EvaIcons.listOutline,
                            text: context.tr(
                                'settings_section_customization_multiple_meals'),
                            trailing: Consumer(builder: (context, ref, _) {
                              return Switch.adaptive(
                                value: SettingsService.multipleMealsPerTime,
                                onChanged: (value) {
                                  setState(() {
                                    SettingsService.setMultipleMealsPerTime(
                                      value,
                                    );
                                  });
                                },
                              );
                            }),
                          ),
                          WidgetUtils.userIsSubscribed(
                            ref: ref,
                            child: SettingsTile(
                              leadingIcon: EvaIcons.trendingUpOutline,
                              text: context.tr(
                                  'settings_section_customization_suggestions'),
                              trailing: Consumer(builder: (context, ref, _) {
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
                          ),
                          SettingsTile(
                            leadingIcon: EvaIcons.trash2Outline,
                            text: context.tr(
                                'settings_section_customization_remove_bought'),
                            trailing: Consumer(builder: (context, ref, _) {
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
                          SettingsTile(
                            onTap: _openChangeMealTypesModal,
                            leadingIcon: Icons.emoji_food_beverage_rounded,
                            text: context.tr(
                                'settings_section_customization_meal_types'),
                            trailing: const Icon(
                              EvaIcons.arrowIosForwardOutline,
                            ),
                          ),
                          WidgetUtils.userIsSubscribed(
                            ref: ref,
                            child: SettingsTile(
                              onTap: _openChangePrimaryColorModal,
                              leadingIcon: EvaIcons.colorPaletteOutline,
                              text: context.tr(
                                  'settings_section_customization_change_color'),
                              trailing: CircleAvatar(
                                maxRadius: kPadding / 2,
                                backgroundColor: theme.primaryColor,
                              ),
                            ),
                          ),
                          _buildShoppingListSortTile(),
                          WidgetUtils.userIsSubscribed(
                            ref: ref,
                            child: SettingsTile(
                              onTap: _openReorderProductGroups,
                              leadingIcon: EvaIcons.menu,
                              text: context.tr(
                                  'settings_section_customization_shoppinglist_group_order'),
                              trailing:
                                  const Icon(EvaIcons.arrowIosForwardOutline),
                            ),
                          ),
                        ], context),
                        _buildSectionTitle(context.tr('settings_section_plan')),
                        _buildSection([
                          SettingsTile(
                            onTap: _openChangePlanNameModal,
                            leadingIcon: Icons.abc_rounded,
                            text:
                                context.tr('settings_section_plan_change_name'),
                            trailing:
                                const Icon(EvaIcons.arrowIosForwardOutline),
                          ),
                          Builder(
                            builder: (BuildContext ctx) => SettingsTile(
                              onTap: () => _shareCode(plan, ctx),
                              leadingIcon: EvaIcons.shareOutline,
                              text: context.tr('settings_section_plan_share',
                                  args: [plan.code!]),
                              trailing:
                                  const Icon(EvaIcons.arrowIosForwardOutline),
                            ),
                          ),
                          SettingsTile(
                            onTap: () => _changePlanCode(plan),
                            leadingIcon: EvaIcons.hashOutline,
                            text:
                                context.tr('settings_section_plan_change_code'),
                            trailing:
                                const Icon(EvaIcons.arrowIosForwardOutline),
                          ),
                          SettingsTile(
                            leadingIcon: EvaIcons.lockOutline,
                            text: context
                                .tr('settings_section_plan_change_locked'),
                            trailing: Consumer(builder: (context, ref, _) {
                              final isLoadingLockState =
                                  ref.watch(_$loadingChangePlanLockState);
                              return isLoadingLockState
                                  ? const SmallCircularProgressIndicator()
                                  : Switch.adaptive(
                                      value: plan.locked ?? false,
                                      onChanged: (value) =>
                                          _changePlanLockState(plan, value),
                                    );
                            }),
                          ),
                          SettingsTile(
                            onTap: () => _leavePlan(plan.id!, context),
                            leadingIcon: EvaIcons.closeCircleOutline,
                            text: context.tr('settings_section_plan_leave'),
                            trailing: const Icon(
                              EvaIcons.arrowIosForwardOutline,
                              color: Colors.red,
                            ),
                            colorIcon: Colors.red,
                            colorText: Colors.red,
                          ),
                        ], context),
                        if (foodlyUser.plans!.length > 1)
                          _buildSectionTitle(
                              context.tr('settings_section_meals'))
                        else
                          const SizedBox(),
                        if (foodlyUser.plans!.length > 1)
                          _buildSection([
                            SettingsTile(
                              onTap: () => _importMeals(
                                foodlyUser.plans!
                                    .where((id) => id != plan.id)
                                    .toList(),
                                context,
                              ),
                              leadingIcon: EvaIcons.downloadOutline,
                              text: context.tr('settings_section_meals_import'),
                              trailing:
                                  const Icon(EvaIcons.arrowIosForwardOutline),
                            ),
                          ], context)
                        else
                          const SizedBox(),
                        _buildSectionTitle(context.tr('settings_section_help')),
                        _buildSection([
                          SettingsTile(
                            onTap: () => Navigator.push(
                              context,
                              ConcentricPageRoute<OnboardingScreen>(
                                builder: (_) => const OnboardingScreen(),
                              ),
                            ),
                            leadingIcon: EvaIcons.questionMarkCircleOutline,
                            text: context.tr('settings_section_help_intro'),
                            trailing:
                                const Icon(EvaIcons.arrowIosForwardOutline),
                          ),
                          SettingsTile(
                            onTap: () => Navigator.push(
                              context,
                              ConcentricPageRoute<HelpSlideShareImport>(
                                builder: (_) => const HelpSlideShareImport(),
                              ),
                            ),
                            leadingIcon: EvaIcons.questionMarkCircleOutline,
                            text: context.tr('settings_section_help_import'),
                            trailing:
                                const Icon(EvaIcons.arrowIosForwardOutline),
                          ),
                          SettingsTile(
                            onTap: () => AutoRouter.of(context)
                                .push(const FeedbackScreenRoute()),
                            leadingIcon: EvaIcons.paperPlaneOutline,
                            text: context.tr('settings_section_help_support'),
                            trailing:
                                const Icon(EvaIcons.arrowIosForwardOutline),
                          ),
                        ], context),
                        _buildSectionTitle(
                            context.tr('settings_section_account')),
                        _buildSection([
                          if (PermissionUtils.allowedToModerate(foodlyUser))
                            SettingsTile(
                              onTap: () => WidgetUtils.showFoodlyBottomSheet(
                                context: context,
                                scrollable: true,
                                // Drag-to-dismiss bypasses PopScope, which keeps
                                // the freshly created token from being closed.
                                enableDrag: false,
                                builder: (_) => const SettingsMcpTokenModal(),
                              ),
                              leadingIcon: EvaIcons.code,
                              text: context.tr('settings_section_account_mcp'),
                              trailing:
                                  const Icon(EvaIcons.arrowIosForwardOutline),
                            ),
                          SettingsTile(
                            leadingIcon: Icons.auto_awesome,
                            text: context
                                .tr('settings_section_general_ai_consent'),
                            trailing: Switch.adaptive(
                              value: foodlyUser.aiConsentAt != null,
                              onChanged: _onAiConsentChanged,
                            ),
                          ),
                          SettingsTile(
                            onTap: () async {
                              await AuthenticationService.resetPassword(
                                  firebaseUser!.email!);
                              if (!context.mounted) {
                                return;
                              }
                              MainSnackbar(
                                message: context
                                    .tr('settings_section_account_reset_msg'),
                                isSuccess: true,
                              ).show(context);
                            },
                            leadingIcon: EvaIcons.lockOutline,
                            text: context.tr('settings_section_account_reset'),
                            trailing:
                                const Icon(EvaIcons.arrowIosForwardOutline),
                          ),
                          SettingsTile(
                            onTap: _deleteAccount,
                            leadingIcon: EvaIcons.trash2Outline,
                            text: context.tr('settings_section_account_delete'),
                            trailing: const Icon(
                              EvaIcons.arrowIosForwardOutline,
                              color: Colors.red,
                            ),
                            colorIcon: Colors.red,
                            colorText: Colors.red,
                          ),
                          SettingsTile(
                            onTap: _signOut,
                            leadingIcon: EvaIcons.logOutOutline,
                            text: context.tr('settings_section_account_logout'),
                            trailing: const Icon(
                              EvaIcons.arrowIosForwardOutline,
                              color: Colors.red,
                            ),
                            colorIcon: Colors.red,
                            colorText: Colors.red,
                          ),
                        ], context),
                        Consumer(
                          builder: (context, ref, _) {
                            final isSubscribed = ref
                                .watch(InAppPurchaseService.$userIsSubscribed);
                            final isGifted =
                                BasicUtils.premiumGiftedActive(foodlyUser);
                            return RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: theme.textTheme.bodyLarge,
                                children: <TextSpan>[
                                  TextSpan(
                                      text: context.tr('settings_sign_in_as')),
                                  TextSpan(
                                    text:
                                        '\n${firebaseUser?.email ?? '...'}${isSubscribed ? isGifted ? ' 🎁' : ' ⭐️' : ''}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: kPadding),
                          child: Wrap(
                            alignment: WrapAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                onPressed: () => _launchUrl(kAppPrivacyUrl),
                                child: Text(
                                  context.tr('settings_privacy'),
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                              TextButton(
                                onPressed: () => _launchUrl(kAppTermsOfUseUrl),
                                child: Text(
                                  context.tr('settings_terms_of_use'),
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const LoadingLogout();
        },
      ),
    );
  }

  Widget _buildShoppingListSortTile() {
    return WidgetUtils.userIsSubscribed(
      ref: ref,
      child: StreamBuilder(
        stream: SettingsService.streamShoppingListSort(),
        builder: (context, _) {
          final current = SettingsService.shoppingListSort;
          final sorts = shoppingListSorts;
          return SettingsTile(
            leadingIcon: Icons.sort_rounded,
            text:
                context.tr('settings_section_customization_shoppinglist_sort'),
            value: sorts
                .firstWhere(
                  (sort) => sort.value == current,
                  orElse: () => sorts.first,
                )
                .label,
            onTap: () => WidgetUtils.showFoodlyBottomSheet<void>(
              context: context,
              builder: (_) => OptionsSheet(options: [
                for (final sort in sorts)
                  OptionsSheetOptions(
                    title: sort.label,
                    selected: sort.value == current,
                    onTap: () async {
                      if (sort.value != current) {
                        await _updateShoppingListSort(sort.value);
                      }
                    },
                  ),
              ]),
            ),
          );
        },
      ),
    );
  }

  String _localeName(Locale locale) =>
      LocaleNames.of(context)!.nameOf(locale.languageCode)!;

  void _openLanguagePicker() {
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => OptionsSheet(options: [
        for (final locale in context.supportedLocales)
          OptionsSheetOptions(
            title: _localeName(locale),
            selected: locale == context.locale,
            onTap: () async {
              if (locale == context.locale) {
                return;
              }
              await context.setLocale(locale);
            },
          ),
      ]),
    );
  }

  Widget _buildSection(List<Widget> widgets, BuildContext context) {
    return Container(
      width: mediaSize.width * 0.9,
      margin: const EdgeInsets.only(bottom: kPadding),
      decoration: BoxDecoration(
        color: theme.dialogTheme.backgroundColor,
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Wrap(children: widgets),
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

  Future<void> _updateShoppingListSort(ShoppingListSort sort) async {
    await SettingsService.setShoppingListSort(sort);
  }

  void _shareCode(Plan plan, BuildContext ctx) async {
    if (plan.locked ?? false) {
      MainSnackbar(
        message: context.tr('settings_share_plan_locked'),
        infinite: true,
      ).show(ctx);
      return;
    }
    final code = plan.code!;
    final joinUrl = Uri.parse('$kAppWebBaseUrl/join/$code').replace(
      queryParameters: {
        if (plan.name?.isNotEmpty ?? false) 'name': plan.name,
        'lang': context.locale.languageCode,
      },
    );
    final box = ctx.findRenderObject() as RenderBox?;
    final params = ShareParams(
      text:
          context.tr('settings_share_msg', args: [kAppName, code, '$joinUrl']),
      subject: context.tr('settings_share_msg_short', args: [kAppName, code]),
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
    await SharePlus.instance.share(params);
    logEvent(AnalyticsEvent.shareCode);
  }

  Future<void> _changePlanCode(Plan plan) async {
    setState(() {
      isLoading = true;
    });
    String code = PlanService.generateCode();
    while ((await PlanService.getPlanByCode(code)) != null) {
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
    ref.read(planProvider.notifier).state = plan;
  }

  Future<void> _changePlanLockState(Plan plan, bool locked) async {
    ref.read(_$loadingChangePlanLockState.notifier).state = true;
    plan.locked = locked;
    await PlanService.updatePlan(plan);
    if (!mounted) {
      return;
    }
    ref.read(_$loadingChangePlanLockState.notifier).state = false;
    ref.read(planProvider.notifier).state = plan;
  }

  void _leavePlan(String planId, BuildContext context) async {
    final leavePlan = await showLeaveConfirmDialog(context);

    if (!leavePlan) {
      return;
    }
    logEvent(AnalyticsEvent.leavePlan);

    final String userId = AuthenticationService.currentUser!.uid;
    Future.wait([
      PlanService.leavePlan(planId, userId),
      FoodlyUserService.removePlanFromUser(userId, planId)
    ]).then((_) {
      AuthenticationService.signOut();
      BasicUtils.clearAllProvider(ref);
    });
  }

  void _importMeals(List<String?> planIds, BuildContext context) {
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => ImportMealsModal(planIds),
    );
  }

  void _openReorderProductGroups() {
    AutoRouter.of(context).push(const ReorderProductGroupsScreenRoute());
  }

  void _openChangePlanNameModal() {
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => const ChangePlanNameModal(),
    );
  }

  void _openChangePrimaryColorModal() {
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => const SettingsChangePrimaryColorModal(),
    );
  }

  Future<void> _deleteAccount() async {
    final delete = await showDeleteConfirmDialog(context);
    if (!delete) {
      return;
    }
    try {
      await AuthenticationService.deleteAccount();
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
        await _reauthenticateUserAndDelete();
      }
    }
    BasicUtils.clearAllProvider(ref);
    logEvent(AnalyticsEvent.deleteAccount);
  }

  Future<void> _reauthenticateUserAndDelete() async {
    final reauthenticated = await WidgetUtils.showFoodlyBottomSheet<bool?>(
      context: context,
      builder: (_) => const SettingsReauthenticateModal(),
    );

    if (reauthenticated == null || !reauthenticated) {
      return;
    }

    try {
      await AuthenticationService.deleteAccount();
    } catch (e) {
      _log.severe('ERR! Account deletion failed after reauthentication!', e);
    }
  }

  Future<void> _signOut() async {
    await AuthenticationService.signOut();
    BasicUtils.clearAllProvider(ref);
  }

  void _openGetPremium() {
    GetPremiumModal.show(context, source: 'settings');
  }

  void _openChangeMealTypesModal() {
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => const ChangeMealTypesModal(),
    );
  }

  Future<void> _onAiConsentChanged(bool allow) async {
    if (allow) {
      await AiConsentSheet.ensure(context, ref);
    } else {
      AiConsentSheet.setConsent(ref, null);
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _launchUrl(String href) async {
    final url = Uri.parse(href);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _log.severe('Could not launch $href');
    }
  }
}

class _ShoppingListSortValue {
  const _ShoppingListSortValue(this.value, this.label);

  final ShoppingListSort value;
  final String label;
}
