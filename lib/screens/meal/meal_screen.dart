import 'package:auto_route/auto_route.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:blur/blur.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_router.gr.dart';
import '../../constants.dart';
import '../../models/ingredient.dart';
import '../../models/meal.dart';
import '../../models/meal_stat.dart';
import '../../providers/state_providers.dart';
import '../../services/in_app_purchase_service.dart';
import '../../services/meal_service.dart';
import '../../services/meal_stat_service.dart';
import '../../services/plan_service.dart';
import '../../utils/basic_utils.dart';
import '../../utils/convert_util.dart';
import '../../utils/main_snackbar.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/disposable_widget.dart';
import '../../widgets/foodly_network_image.dart';
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
import 'tag_tile.dart';

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

class _MealScreenState extends ConsumerState<MealScreen> with DisposableWidget {
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
        .where((mealId) => mealId != null && widget.id == mealId)
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
    final Size size = MediaQuery.of(context).size;
    const sidePadding = EdgeInsets.symmetric(horizontal: kPadding);
    final currentPlanId = ref.read(planProvider)!.id;
    final meal = ref.watch(_$meal);

    return Scaffold(
      body: ref.watch(_$isLoading) || meal == null
          ? const Center(child: SmallCircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: size.width > 700.0 ? 400.0 : 250.0,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 4,
                  stretch: true,
                  flexibleSpace: FlexibleSpaceBar(
                    // ignore: avoid_redundant_argument_values
                    stretchModes: const <StretchMode>[
                      StretchMode.zoomBackground
                    ],
                    titlePadding: EdgeInsets.zero,
                    background: Stack(
                      children: [
                        if (meal.imageUrl != null && meal.imageUrl!.isNotEmpty)
                          Positioned.fill(
                            child: FoodlyNetworkImage(meal.imageUrl!),
                          )
                        else
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/food_fallback.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        Positioned(
                          width: size.width,
                          top:
                              kPadding / 2 + MediaQuery.of(context).padding.top,
                          child: Padding(
                            padding: sidePadding,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: const BorderIcon(
                                    height: 50,
                                    width: 50,
                                    child: Icon(
                                      EvaIcons.arrowBackOutline,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                if (widget.showOptions)
                                  BorderIcon(
                                    height: 50,
                                    width: 50,
                                    child: IconButton(
                                      icon: const Icon(
                                        EvaIcons.moreHorizontalOutline,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _showOptionsSheet(
                                        meal,
                                        currentPlanId,
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  title: const SizedBox(),
                  leading: const SizedBox(),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: kPadding),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: sidePadding,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AutoSizeText(
                                      meal.name,
                                      style: const TextStyle(
                                        fontSize: 26.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5.0),
                                    Text(
                                      meal.source != null &&
                                              meal.source!.isNotEmpty
                                          ? 'meal_details_source_known'
                                              .tr(args: [
                                              _formatSourceString(meal.source!)
                                            ])
                                          : 'meal_details_source_unknown'.tr(),
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .color!
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              BorderIcon(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 15,
                                ),
                                withBorder: true,
                                child: Text(
                                  'meal_details_duration_trailing'.tr(
                                    args: [
                                      (meal.duration ?? '?').toString(),
                                    ],
                                  ),
                                  style: const TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (meal.source != null && meal.source!.isNotEmpty) ...[
                          const SizedBox(height: kPadding),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: kPadding),
                            child: LinkPreview(meal.source!),
                          ),
                        ],
                        const SizedBox(height: kPadding),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              ...meal.tags!.map((e) => TagTile(e)),
                              const SizedBox(width: kPadding),
                            ],
                          ),
                        ),
                        _buildImportButton(meal),
                        _buildIngredientSection(meal),
                        if (meal.instructions != null &&
                            meal.instructions!.isNotEmpty) ...[
                          const SizedBox(height: kPadding),
                          _buildSection(
                            'meal_details_instructions'.tr(),
                            MarkdownBody(
                              data: meal.instructions ?? '',
                              styleSheet: MarkdownStyleSheet.fromTheme(
                                ThemeData(
                                  textTheme: const TextTheme(
                                    bodyLarge: TextStyle(fontSize: 16),
                                    bodyMedium: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: kPadding),
                        _buildMealStatSection(meal),
                        const SizedBox(height: 100.0),
                      ]
                          .map(
                            (child) => SizedBox(
                              width: BasicUtils.contentWidth(
                                context,
                                smallMultiplier: 1,
                              ),
                              child: child,
                            ),
                          )
                          .toList(),
                    ),
                  ),
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
          tooltip: 'meal_details_keep_screen_on'.tr(),
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
                    text: 'meal_details_import'.tr(),
                    isProgress: true,
                    buttonState: ref.watch(_$importButtonState),
                  );
                }),
              ],
            ),
          );
  }

  Widget _buildIngredientSection(Meal meal) {
    final isEmpty = meal.ingredients == null || meal.ingredients!.isEmpty;
    return isEmpty
        ? const SizedBox()
        : Padding(
            padding: const EdgeInsets.only(top: kPadding),
            child: _buildSection(
              'meal_details_ingredient'.tr(),
              meal.ingredients != null
                  ? ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: meal.ingredients!.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, index) => _buildIngredientTile(
                        meal.ingredients![index],
                      ),
                      padding: EdgeInsets.zero,
                    )
                  : const SizedBox(),
              Consumer(builder: (context, ref, _) {
                final servings = ref.watch(_$servings);
                return SmallNumberInput(
                  value: servings,
                  minValue: 1,
                  maxValue: 30,
                  onChanged: (value) =>
                      ref.read(_$servings.notifier).state = value,
                );
              }),
            ),
          );
  }

  Widget _buildIngredientTile(Ingredient ingredient) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: kPadding / 2),
      child: LayoutBuilder(builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SizedBox(
              width: constraints.maxWidth * 0.3 - kPadding / 2,
              child: Consumer(builder: (context, ref, _) {
                final servings = ref.watch(_$servings);
                final amount = ConvertUtil.calculateServingsAmount(
                  requestedServings: servings,
                  mealServings: ref.read(_$meal)?.servings ?? 0,
                  amount: ingredient.amount,
                );
                return Text(
                  ConvertUtil.amountToString(amount, ingredient.unit),
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 18.0),
                );
              }),
            ),
            SizedBox(
              width: constraints.maxWidth * 0.5 - kPadding / 2,
              child: Text(
                ingredient.name.toString(),
                textAlign: TextAlign.start,
                style: const TextStyle(fontSize: 18.0),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSection(String title, Widget content, [Widget? trailing]) {
    const sidePadding = EdgeInsets.symmetric(horizontal: kPadding);
    final titleText = Text(
      title,
      style: const TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.bold,
      ),
      overflow: TextOverflow.ellipsis,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: sidePadding,
          child: trailing == null
              ? titleText
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: titleText),
                    trailing,
                  ],
                ),
        ),
        const SizedBox(height: kPadding),
        Container(width: double.infinity, padding: sidePadding, child: content),
      ],
    );
  }

  Widget _buildMealStatSection(Meal meal) {
    return Consumer(
      builder: (context, ref, _) {
        final mealStat = ref.watch(_$mealStat);
        return mealStat == null
            ? const SizedBox()
            : _buildSection(
                'meal_details_stats'.tr(),
                Consumer(
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
            'meal_details_stats_locked'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          ElevatedButton(
            onPressed: _openGetPremium,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).textTheme.bodyLarge!.color,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'meal_details_stats_unlock'.tr(),
                  style: TextStyle(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
                Icon(
                  EvaIcons.arrowIosForwardOutline,
                  size: Theme.of(context).textTheme.bodyLarge!.fontSize! + 5,
                  color: Theme.of(context).scaffoldBackgroundColor,
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
        color: Theme.of(context).cardTheme.color,
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
    await Future.wait<void>([_fetchMeal()]);
    ref.read(_$isLoading.notifier).state = false;
    _fetchStats(); // call after is loading, to avoid riverpod issues
    _checkOwnerOfMeal();
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

  String _formatSourceString(String source) {
    return BasicUtils.isValidUri(source)
        ? Uri.parse(source).host.replaceAll('www.', '')
        : source;
  }

  void _showOptionsSheet(Meal meal, String? planId) {
    if (_isInPlan == false) {
      WidgetUtils.showFoodlyBottomSheet<void>(
        context: context,
        builder: (_) => OptionsSheet(options: [
          OptionsSheetOptions(
            title: 'meal_details_import'.tr(),
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
            title: 'meal_details_share_meal'.tr(),
            icon: EvaIcons.shareOutline,
            onTap: () => _shareMeal(meal, ctx),
          );
        }),
        OptionsSheetOptions(
          title: 'meal_details_add_to_plan'.tr(),
          icon: EvaIcons.fileAddOutline,
          onTap: () => _openAddToPlan(meal),
        ),
        OptionsSheetOptions(
          title: 'meal_details_edit'.tr(),
          icon: EvaIcons.edit2Outline,
          onTap: () => AutoRouter.of(context).push(
            MealCreateScreenRoute(id: meal.id!),
          ),
        ),
        OptionsSheetOptions(
          title: 'meal_details_delete'.tr(),
          icon: EvaIcons.minusCircleOutline,
          textColor: Theme.of(context).colorScheme.error,
          onTap: () => _openConfirmDelete(meal),
        ),
      ]),
    );
  }

  void _openGetPremium() {
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => const GetPremiumModal(),
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
        BasicUtils.emitMealsChanged(ref, value.id!);
        AutoRouter.of(context).popAndPush(MealScreenRoute(id: value.id!));
      }
    }).catchError((dynamic e) {
      ref.read(_$importButtonState.notifier).state = ButtonState.normal;
    });
  }

  void _shareMeal(Meal meal, BuildContext ctx) {
    final langCode = context.locale.languageCode;
    final box = ctx.findRenderObject() as RenderBox?;
    Share.share(
      '${meal.name} - $kAppWebBaseUrl/meal/${meal.id}?lang=$langCode',
      subject: meal.name,
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
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
    final result = await showModalBottomSheet<bool>(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      isScrollControlled: true,
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
    if (mounted && ref.read(showKeepOnScreenNotification)) {
      MainSnackbar(
        title: 'meal_details_keep_screen_on'.tr(),
        message: 'meal_details_keep_screen_on_description'.tr(),
        isDismissible: true,
      ).show(context);
      ref.read(showKeepOnScreenNotification.notifier).state = false;
    }
  }
}
