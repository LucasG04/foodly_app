import 'package:auto_route/auto_route.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:blur/blur.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_router.gr.dart';
import '../../constants.dart';
import '../../models/meal.dart';
import '../../models/meal_stat.dart';
import '../../providers/state_providers.dart';
import '../../services/in_app_purchase_service.dart';
import '../../services/meal_service.dart';
import '../../services/meal_stat_service.dart';
import '../../services/plan_service.dart';
import '../../services/settings_service.dart';
import '../../utils/analytics.dart';
import '../../utils/basic_utils.dart';
import '../../utils/main_snackbar.dart';
import '../../utils/of_context_mixin.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/disposable_widget.dart';
import '../../widgets/get_premium_modal.dart';
import '../../widgets/link_preview.dart';
import '../../widgets/main_button.dart';
import '../../widgets/options_modal/options_modal.dart';
import '../../widgets/options_modal/options_modal_option.dart';
import '../../widgets/progress_button.dart';
import '../../widgets/small_circular_progress_indicator.dart';
import '../../widgets/small_number_input.dart';
import '../tab_navigation/plan_view/plan_move_meal_modal.dart';
import 'border_icon.dart';
import 'confirm_delete_modal.dart';
import 'meal_detail_widgets.dart';

class MealScreen extends ConsumerStatefulWidget {
  final String id;
  final bool showOptions;

  const MealScreen({
    required this.id,
    this.showOptions = true,
    super.key,
  });

  @override
  _MealScreenState createState() => _MealScreenState();
}

class _MealScreenState extends ConsumerState<MealScreen>
    with DisposableWidget, OfContextMixin {
  final _$isLoading = AutoDisposeStateProvider<bool>((_) => true);
  final _$meal = AutoDisposeStateProvider<Meal?>((_) => null);
  final _$mealStat = AutoDisposeStateProvider<MealStat?>((_) => null);
  final _$importButtonState = AutoDisposeStateProvider<ButtonState>(
    (_) => ButtonState.normal,
  );
  final _$keepScreenOnActive = AutoDisposeStateProvider<bool>((_) => false);
  late final AutoDisposeStateProvider<int> _$servings;

  bool? _isInPlan;

  @override
  void initState() {
    super.initState();
    _$servings = AutoDisposeStateProvider<int>(
      (ref) => ref.watch(_$meal)?.servings ?? 1,
    );
    _fetchMealAndStats();
    ref
        .read(lastChangedMealProvider.notifier)
        .stream
        .where((mealId) => mealId != null && widget.id == mealId && mounted)
        .listen((_) => _fetchMealAndStats())
        .canceledBy(this);
  }

  @override
  void dispose() {
    KeepScreenOn.turnOff();
    cancelSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const sidePadding = EdgeInsets.symmetric(horizontal: kPadding);
    final currentPlanId = ref.read(planProvider)!.id;
    final meal = ref.watch(_$meal);

    return Scaffold(
      body: ref.watch(_$isLoading) || meal == null
          ? const Center(child: SmallCircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                MealImageAppBar(
                  imageUrl: meal.imageUrl,
                  imageCredit: meal.imageCredit,
                  action: widget.showOptions
                      ? BorderIcon(
                          height: 50,
                          width: 50,
                          child: IconButton(
                            icon: const Icon(EvaIcons.moreHorizontalOutline),
                            padding: EdgeInsets.zero,
                            onPressed: () =>
                                _showOptionsSheet(meal, currentPlanId),
                          ),
                        )
                      : null,
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: kPadding),
                ),
                MealDetailBody(
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        return MealHeadline(
                          name: meal.name,
                          source: meal.source,
                          duration: meal.duration,
                          kcal: meal.kcal,
                          mealServings: meal.servings,
                          servings: ref.watch(_$servings),
                        );
                      },
                    ),
                    if (meal.source != null &&
                        BasicUtils.isValidUri(meal.source!)) ...[
                      const SizedBox(height: kPadding),
                      Padding(
                        padding: sidePadding,
                        child: LinkPreview(meal.source!),
                      ),
                    ],
                    const SizedBox(height: kPadding),
                    MealTagRow(meal.tags!),
                    _buildImportButton(meal),
                    _buildIngredientSection(meal),
                    if (meal.instructions != null &&
                        meal.instructions!.isNotEmpty) ...[
                      const SizedBox(height: kPadding),
                      MealSection(
                        title: context.tr('meal_details_instructions'),
                        child: MealInstructions(meal.instructions!),
                      ),
                    ],
                    const SizedBox(height: kPadding),
                    _buildMealStatSection(meal),
                    const SizedBox(height: 100.0),
                  ],
                ),
              ],
            ),
      floatingActionButton: Consumer(builder: (context, ref, _) {
        final isActive = ref.watch(_$keepScreenOnActive);
        return FloatingActionButton.small(
          onPressed: () => _keepScreenOn(!isActive),
          // the white background for `isActive` indicates that the screen is kept on
          // the `flashOffOutline` icon is used to indicate what will happen when the button is pressed
          foregroundColor: isActive ? Colors.grey[850] : Colors.white,
          backgroundColor: isActive ? Colors.white : Colors.grey[850],
          tooltip: context.tr('meal_details_keep_screen_on'),
          child: Icon(
            isActive ? EvaIcons.flashOffOutline : EvaIcons.flashOutline,
          ),
        );
      }),
    );
  }

  Widget _buildImportButton(Meal? meal) {
    if (_isInPlan == null || meal == null) {
      return const SizedBox();
    }
    return _isInPlan!
        ? const SizedBox()
        : Padding(
            padding: const EdgeInsets.only(
              top: kPadding,
              left: kPadding,
              right: kPadding,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Consumer(builder: (_, ref, __) {
                  return MainButton(
                    onTap: () => _importMeal(meal),
                    text: context.tr('meal_details_import'),
                    isProgress: true,
                    buttonState: ref.watch(_$importButtonState),
                  );
                }),
              ],
            ),
          );
  }

  Widget _buildIngredientSection(Meal meal) {
    if (meal.ingredients == null || meal.ingredients!.isEmpty) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(top: kPadding),
      child: Consumer(builder: (context, ref, _) {
        final servings = ref.watch(_$servings);
        return MealSection(
          title: context.tr('meal_details_ingredient'),
          trailing: SmallNumberInput(
            value: servings,
            minValue: 1,
            maxValue: 30,
            onChanged: (value) => ref.read(_$servings.notifier).state = value,
          ),
          child: MealIngredientList(
            ingredients: meal.ingredients!,
            groupOrder: meal.ingredientGroupOrder,
            servings: servings,
            mealServings: meal.servings,
          ),
        );
      }),
    );
  }

  Widget _buildMealStatSection(Meal meal) {
    return Consumer(
      builder: (context, ref, _) {
        final mealStat = ref.watch(_$mealStat);
        return mealStat == null
            ? const SizedBox()
            : MealSection(
                title: context.tr('meal_details_stats'),
                child: Consumer(
                  builder: (context, ref, child) {
                    final isSubscribed =
                        ref.watch(InAppPurchaseService.$userIsSubscribed);
                    return isSubscribed
                        ? child!
                        : _buildMealStatBlur(context, child!);
                  },
                  child: _buildMealStatBody(meal, mealStat),
                ),
              );
      },
    );
  }

  Widget _buildMealStatBlur(BuildContext context, Widget child) {
    return Blur(
      overlay: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            context.tr('meal_details_stats_locked'),
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          ElevatedButton(
            onPressed: _openGetPremium,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.textTheme.bodyLarge!.color,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('meal_details_stats_unlock'),
                  style: TextStyle(
                    color: theme.scaffoldBackgroundColor,
                  ),
                ),
                Icon(
                  EvaIcons.arrowIosForwardOutline,
                  size: theme.textTheme.bodyLarge!.fontSize! + 5,
                  color: theme.scaffoldBackgroundColor,
                ),
              ],
            ),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildMealStatBody(Meal meal, MealStat mealStat) {
    return Wrap(
      runSpacing: kPadding,
      spacing: kPadding,
      alignment: WrapAlignment.spaceEvenly,
      children: [
        _buildMealStatInfo(
          'Geplant',
          '${mealStat.plannedCount} x',
        ),
        _buildMealStatInfo(
          'Letzte Mal geplant',
          mealStat.plannedCount != null && mealStat.plannedCount! > 0
              ? DateFormat.yMd(context.locale.languageCode)
                  .format(mealStat.lastTimePlanned!)
              : '-',
        ),
        if (meal.createdAt != null)
          _buildMealStatInfo(
            'Erstellt',
            DateFormat.yMd(context.locale.languageCode).format(meal.createdAt!),
          ),
      ],
    );
  }

  Widget _buildMealStatInfo(String title, String stat) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(kPadding / 2),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: const [kSmallShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(kPadding / 2),
        child: Column(
          children: [
            AutoSizeText(
              stat,
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              minFontSize: 14,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: kPadding / 2),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchMealAndStats() async {
    ref.read(_$isLoading.notifier).state = true;
    await _fetchMeal();
    _checkOwnerOfMeal();
    ref.read(_$isLoading.notifier).state = false;
    await _fetchStats();
  }

  Future<void> _fetchMeal() async {
    final result = await MealService.getMealById(widget.id);
    ref.read(_$meal.notifier).state = result;
  }

  Future<void> _fetchStats() async {
    final result =
        await MealStatService.getStat(ref.read(planProvider)!.id!, widget.id);
    if (mounted) {
      ref.read(_$mealStat.notifier).state = result;
    }
  }

  void _checkOwnerOfMeal() {
    final planId = ref.read(planProvider)?.id;
    final meal = ref.read(_$meal);

    if (meal == null || planId == null) {
      return;
    }

    _isInPlan = meal.planId == planId;
  }

  void _showOptionsSheet(Meal meal, String? planId) {
    if (_isInPlan == false) {
      WidgetUtils.showFoodlyBottomSheet<void>(
        context: context,
        builder: (_) => OptionsSheet(options: [
          OptionsSheetOptions(
            title: context.tr('meal_details_import'),
            icon: EvaIcons.downloadOutline,
            onTap: () => _importMeal(meal),
          ),
        ]),
      );
      return;
    }

    if (meal.planId != planId) {
      return;
    }
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => OptionsSheet(options: [
        Builder(builder: (ctx) {
          return OptionsSheetOptions(
            title: context.tr('meal_details_share_meal'),
            icon: EvaIcons.shareOutline,
            onTap: () => _shareMeal(meal, ctx),
          );
        }),
        OptionsSheetOptions(
          title: context.tr('meal_details_add_to_plan'),
          icon: EvaIcons.fileAddOutline,
          onTap: () => _openAddToPlan(meal),
        ),
        OptionsSheetOptions(
          title: context.tr('meal_details_edit'),
          icon: EvaIcons.edit2Outline,
          onTap: () => AutoRouter.of(context).push(
            MealCreateScreenRoute(id: meal.id!),
          ),
        ),
        OptionsSheetOptions(
          title: context.tr('meal_details_delete'),
          icon: EvaIcons.minusCircleOutline,
          textColor: theme.colorScheme.error,
          onTap: () => _openConfirmDelete(meal),
        ),
      ]),
    );
  }

  void _openGetPremium() {
    GetPremiumModal.show(
      context,
      source: 'meal_stats',
      highlight: PremiumFeature.stats,
    );
  }

  void _importMeal(Meal meal) {
    meal.id = null;
    final planId = ref.read(planProvider)?.id;
    meal.planId = planId;
    ref.read(_$importButtonState.notifier).state = ButtonState.inProgress;
    MealService.createMeal(meal).then((value) {
      ref.read(_$importButtonState.notifier).state = ButtonState.normal;
      if (value != null && value.id != null) {
        logEvent(AnalyticsEvent.mealCreate, {'source': 'copy'});
        BasicUtils.emitMealsChanged(ref, value.id!);
        if (mounted) {
          AutoRouter.of(context).popAndPush(MealScreenRoute(id: value.id!));
        }
      }
    }).catchError((dynamic e) {
      ref.read(_$importButtonState.notifier).state = ButtonState.normal;
    });
  }

  void _shareMeal(Meal meal, BuildContext ctx) {
    final langCode = context.locale.languageCode;
    final box = ctx.findRenderObject() as RenderBox?;
    final params = ShareParams(
      text: '${meal.name} - $kAppWebBaseUrl/meal/${meal.id}?lang=$langCode',
      subject: meal.name,
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
    SharePlus.instance.share(params);
  }

  void _openAddToPlan(Meal meal) async {
    final added = await WidgetUtils.showFoodlyBottomSheet<bool?>(
      context: context,
      builder: (_) => PlanMoveMealModal(isMoving: false, meal: meal),
    );

    if (added != null && added) {
      await _fetchStats();
    }
  }

  void _openConfirmDelete(Meal meal) async {
    final result = await WidgetUtils.showFoodlyBottomSheet<bool>(
      context: context,
      builder: (_) => ConfirmDeleteModal(meal),
    );

    if (result != null && result) {
      await _deleteMeal(meal.id!);

      if (!mounted) {
        return;
      }
      BasicUtils.emitMealsChanged(ref, meal.id ?? '');
      AutoRouter.of(context).pop();
    }
  }

  Future<void> _deleteMeal(String mealId) async {
    ref.read(_$isLoading.notifier).state = true;
    final plan = ref.read(planProvider)!;
    await MealService.deleteMeal(mealId);
    await MealStatService.deleteStatByMealId(plan.id, mealId);

    if (plan.meals != null && plan.meals!.isNotEmpty) {
      for (final planMeal in plan.meals!.where((e) => e.meal == mealId)) {
        await PlanService.deletePlanMealFromPlan(plan.id, planMeal.id);
      }
    }
    ref.read(_$isLoading.notifier).state = true;
  }

  void _keepScreenOn(bool active) {
    ref.read(_$keepScreenOnActive.notifier).state = active;

    if (!active) {
      KeepScreenOn.turnOff();
      return;
    }

    KeepScreenOn.turnOn();
    if (mounted && !SettingsService.keepScreenOnHintSeen) {
      MainSnackbar(
        title: context.tr('meal_details_keep_screen_on'),
        message: context.tr('meal_details_keep_screen_on_description'),
      ).show(context);
      SettingsService.setKeepScreenOnHintSeen();
    }
  }
}
