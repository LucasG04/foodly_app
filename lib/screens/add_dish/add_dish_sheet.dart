import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_router.gr.dart';
import '../../constants.dart';
import '../../models/ai_usage.dart';
import '../../models/meal.dart';
import '../../providers/state_providers.dart';
import '../../services/in_app_purchase_service.dart';
import '../../utils/analytics.dart';
import '../../utils/basic_utils.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/ai_consent_sheet.dart';
import '../../widgets/get_premium_modal.dart';
import '../../widgets/keyboard_aware_sheet.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/sheet_header.dart';
import '../settings/import_meals_modal.dart';
import 'add_dish_input.dart';

/// What the user picked in the [AddDishSheet].
sealed class AddDishChoice {
  const AddDishChoice();
}

class AddDishLink extends AddDishChoice {
  final String url;
  final AddDishKind kind;
  const AddDishLink(this.url, this.kind);
}

class AddDishAi extends AddDishChoice {
  final String prompt;
  const AddDishAi(this.prompt);
}

class AddDishLibrary extends AddDishChoice {
  const AddDishLibrary();
}

class AddDishOtherPlans extends AddDishChoice {
  const AddDishOtherPlans();
}

class AddDishManual extends AddDishChoice {
  const AddDishManual();
}

/// The weekly quota for [feature] (`instagram` / `tiktok` / `assistant`) is
/// used up; both platforms share one quota.
class AddDishPremium extends AddDishChoice {
  final String feature;
  const AddDishPremium(this.feature);
}

/// Shows the [AddDishSheet] and, once it has closed, opens the flow the user
/// picked (never one sheet on top of another). With [returnsMeal] (picking a
/// dish for a plan slot) a dish created from the sheet is returned instead of
/// opening its detail page.
Future<Meal?> showAddDishSheet(
  BuildContext context,
  WidgetRef ref, {
  String initialText = '',
  bool returnsMeal = false,
}) async {
  final plans = ref.read(userProvider)?.plans ?? [];
  final choice = await WidgetUtils.showFoodlyBottomSheet<AddDishChoice>(
    context: context,
    builder: (_) => AddDishSheet(
      initialText: initialText,
      showOtherPlans: plans.length > 1,
    ),
  );
  if (choice == null || !context.mounted) {
    return null;
  }
  // AI needs consent first. Asked before leaving for the create screen, so
  // "Not now" brings the sheet back with the user's text instead of a blank
  // form.
  final aiText = switch (choice) {
    AddDishAi(:final prompt) => prompt,
    AddDishLink(:final url, kind: AddDishKind.social) => url,
    _ => null,
  };
  if (aiText != null && !await AiConsentSheet.ensure(context, ref)) {
    if (!context.mounted) {
      return null;
    }
    return showAddDishSheet(
      context,
      ref,
      initialText: aiText,
      returnsMeal: returnsMeal,
    );
  }
  if (!context.mounted) {
    return null;
  }
  final router = AutoRouter.of(context);
  final createRoute = switch (choice) {
    AddDishLink(:final url) => MealCreateScreenRoute(
        id: Uri.encodeComponent(url),
        navigateToDetailOnCreate: !returnsMeal,
        origin: 'sheet',
      ),
    AddDishAi(:final prompt) => MealCreateScreenRoute(
        id: 'create',
        navigateToDetailOnCreate: !returnsMeal,
        assistantPrompt: prompt,
      ),
    AddDishManual() => MealCreateScreenRoute(
        id: 'create',
        navigateToDetailOnCreate: !returnsMeal,
      ),
    _ => null,
  };
  if (createRoute != null) {
    final meal = await router.push<Object?>(createRoute);
    return meal is Meal ? meal : null;
  }
  switch (choice) {
    case AddDishLibrary():
      router.push(LibraryScreenRoute(entry: 'add_sheet'));
    case AddDishOtherPlans():
      WidgetUtils.showFoodlyBottomSheet<void>(
        context: context,
        builder: (_) => ImportMealsModal(
          plans.where((id) => id != ref.read(planProvider)?.id).toList(),
        ),
      );
    case AddDishPremium(:final feature):
      GetPremiumModal.show(
        context,
        source: 'ai_quota_$feature',
        highlight: PremiumFeature.ai,
      );
    case AddDishLink() || AddDishAi() || AddDishManual():
      break;
  }
  return null;
}

/// The cost line shown before the user commits to [input]. Counts only for
/// free users with a known quota; when the quota is unknown the server still
/// enforces it, so the action stays available.
({String label, bool exhausted}) addDishCost(
  BuildContext context,
  AddDishInput input,
  AiUsage? usage,
  bool isSubscribed,
) {
  switch (input.kind) {
    case AddDishKind.empty:
      return (label: '', exhausted: false);
    case AddDishKind.website:
      return (label: context.tr('add_dish_cost_free'), exhausted: false);
    case AddDishKind.social:
    case AddDishKind.ai:
      final platform = input.platform;
      final isSocial = platform != null;
      final name = isSocial ? 'social' : 'ai';
      if (isSubscribed || usage == null) {
        return (
          label: platform?.label ?? context.tr('add_dish_kind_ai'),
          exhausted: false,
        );
      }
      final remaining = isSocial ? usage.socialRemaining : usage.textRemaining;
      if (remaining == 0) {
        return (
          label: context.tr('add_dish_cost_exhausted_$name'),
          exhausted: true,
        );
      }
      final limit = isSocial ? usage.limits.social : usage.limits.text;
      return (
        label: context.tr('add_dish_cost_$name',
            args: [remaining.toString(), limit.toString()]),
        exhausted: false,
      );
  }
}

/// One place for every way to add a dish: a field for a link or a dish
/// description (with its cost shown before committing) and rows for the
/// library, the user's other plans and the blank form. Pops with an
/// [AddDishChoice], or null when dismissed.
class AddDishSheet extends ConsumerStatefulWidget {
  final String initialText;
  final bool showOtherPlans;

  const AddDishSheet({
    this.initialText = '',
    this.showOtherPlans = false,
    super.key,
  });

  @override
  ConsumerState<AddDishSheet> createState() => _AddDishSheetState();
}

class _AddDishSheetState extends ConsumerState<AddDishSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);
  late AddDishInput _input = classifyAddDishInput(widget.initialText);

  /// Keys the cost line per change: typing a link flips the kind back and
  /// forth, and a key that is still fading out must not come back.
  int _inputVersion = 0;

  /// Features whose used-up quota was already logged in this sheet.
  final _loggedExhausted = <String>{};

  @override
  void initState() {
    super.initState();
    BasicUtils.afterBuild(() => _logIfExhausted(_input));
    // Listens to the controller (not onChange) so pasting updates it too.
    _controller.addListener(() {
      final input = classifyAddDishInput(_controller.text);
      // The cost line and button only depend on the kind and platform; a new
      // url or prompt is read on commit.
      if (input.kind != _input.kind || input.platform != _input.platform) {
        setState(() {
          _input = input;
          _inputVersion++;
        });
        _logIfExhausted(input);
      } else {
        _input = input;
      }
    });
  }

  /// Quota feature for analytics and the paywall: the platform for social
  /// links (they share one quota), `assistant` for AI.
  static String _feature(AddDishInput input) =>
      input.platform?.name ?? 'assistant';

  /// Same event as the quota snackbar elsewhere, once per feature.
  void _logIfExhausted(AddDishInput input) {
    if (mounted &&
        _cost(input).exhausted &&
        _loggedExhausted.add(_feature(input))) {
      logEvent(AnalyticsEvent.aiQuotaExceededShown, {
        'feature': _feature(input),
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pop(AddDishChoice choice, String action) {
    logEvent(AnalyticsEvent.addDishSheet, {'action': action});
    Navigator.of(context).pop(choice);
  }

  void _commit() {
    final input = _input;
    if (input.kind == AddDishKind.empty) {
      return;
    }
    if (_cost(input).exhausted) {
      final feature = _feature(input);
      _pop(AddDishPremium(feature), 'premium_$feature');
    } else if (input.kind == AddDishKind.ai) {
      _pop(AddDishAi(input.text), input.kind.name);
    } else {
      _pop(AddDishLink(input.url!, input.kind),
          input.platform?.name ?? input.kind.name);
    }
  }

  ({String label, bool exhausted}) _cost(AddDishInput input) => addDishCost(
        context,
        input,
        ref.read(aiUsageProvider).valueOrNull,
        ref.read(InAppPurchaseService.$userIsSubscribed),
      );

  @override
  Widget build(BuildContext context) {
    // Rebuild when the quota or subscription changes while the sheet is open.
    ref.watch(aiUsageProvider);
    ref.watch(InAppPurchaseService.$userIsSubscribed);

    return KeyboardAwareSheet(
      header: SheetHeader(title: context.tr('add_dish_title'), maxLines: 2),
      children: [
        const SizedBox(height: kPadding / 2),
        MainTextField(
          controller: _controller,
          placeholder: context.tr('add_dish_placeholder'),
          hintMaxLines: 2,
          textInputAction: TextInputAction.go,
          textCapitalization: TextCapitalization.sentences,
          onSubmit: _commit,
          pasteFromClipboard: true,
          pasteValidator: (_) => true,
        ),
        _buildCommit(),
        _buildDivider(),
        _AddDishRow(
          icon: EvaIcons.bookOpenOutline,
          title: context.tr('add_dish_library'),
          subtitle: context.tr('add_dish_library_sub'),
          onTap: () => _pop(const AddDishLibrary(), 'library'),
        ),
        if (widget.showOtherPlans) ...[
          const SizedBox(height: kPadding / 2),
          _AddDishRow(
            icon: EvaIcons.copyOutline,
            title: context.tr('add_dish_other_plans'),
            onTap: () => _pop(const AddDishOtherPlans(), 'other_plans'),
          ),
        ],
        const SizedBox(height: kPadding / 2),
        _AddDishRow(
          icon: EvaIcons.edit2Outline,
          title: context.tr('add_dish_manual'),
          onTap: () => _pop(const AddDishManual(), 'manual'),
        ),
        SizedBox(height: WidgetUtils.sheetBottomPadding(context)),
      ],
    );
  }

  /// Cost line + action button for the current input; cross-fades when the
  /// input kind changes.
  Widget _buildCommit() {
    final input = _input;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 200);
    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, if (current != null) current],
        ),
        child: input.kind == AddDishKind.empty
            ? SizedBox(
                key: ValueKey(_inputVersion),
                width: double.infinity,
              )
            : _buildCostAndButton(input),
      ),
    );
  }

  Widget _buildCostAndButton(AddDishInput input) {
    final kind = input.kind;
    final theme = Theme.of(context);
    final cost = _cost(input);
    final textScaler = MediaQuery.textScalerOf(context);
    final iconSize = textScaler.scale(16);
    final color = cost.exhausted
        ? theme.colorScheme.error
        : theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6);
    final icon = input.platform?.icon ??
        (kind == AddDishKind.ai ? Icons.auto_awesome : EvaIcons.link2Outline);
    final String buttonText;
    if (cost.exhausted) {
      buttonText = context.tr('add_dish_get_premium');
    } else if (kind == AddDishKind.ai) {
      buttonText = context.tr('add_dish_create_ai');
    } else {
      buttonText = context.tr('add_dish_import');
    }

    return Column(
      key: ValueKey(_inputVersion),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grows with the text and stays centred on its first line.
            Padding(
              padding: EdgeInsets.only(
                top: math.max(0, (textScaler.scale(14) * 1.4 - iconSize) / 2),
              ),
              child: Icon(icon, size: iconSize, color: color),
            ),
            const SizedBox(width: kPadding / 4),
            Expanded(
              child: Text(
                cost.label,
                style: TextStyle(color: color, fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: kPadding),
        Center(
          child: MainButton(
            text: buttonText,
            onTap: _commit,
            color: cost.exhausted ? kPremiumColor : null,
            textColor: cost.exhausted ? kPrimaryColor : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    final color =
        Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kPadding),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: kPadding / 2),
            child: Text(
              context.tr('add_dish_or'),
              style: TextStyle(color: color),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

/// A row in the look of `OptionsSheetOptions`, with an optional second line.
/// Doesn't use it directly because that one pops without a result.
class _AddDishRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _AddDishRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final iconSize = MediaQuery.textScalerOf(context).scale(kIconHeight);
    // Same corners as the sheet's MainButton.
    final radius = BorderRadius.circular(10);
    return Material(
      color: textColor?.withValues(alpha: 0.06) ??
          Colors.black.withValues(alpha: 0.06),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(kPadding),
          child: Row(
            children: [
              Icon(icon, size: iconSize, color: textColor),
              const SizedBox(width: kPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: textColor?.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                EvaIcons.chevronRightOutline,
                size: iconSize,
                color: textColor?.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
