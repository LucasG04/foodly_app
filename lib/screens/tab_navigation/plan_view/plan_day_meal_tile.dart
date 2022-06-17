import 'package:auto_route/auto_route.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_router.gr.dart';
import '../../../constants.dart';
import '../../../models/grocery.dart';
import '../../../models/meal.dart';
import '../../../models/plan_meal.dart';
import '../../../providers/state_providers.dart';
import '../../../services/authentication_service.dart';
import '../../../services/meal_service.dart';
import '../../../services/plan_service.dart';
import '../../../services/shopping_list_service.dart';
import '../../../utils/widget_utils.dart';
import '../../../widgets/foodly_network_image.dart';
import '../../../widgets/meal_tag.dart';
import '../../../widgets/skeleton_container.dart';
import '../../../widgets/small_circular_progress_indicator.dart';
import 'plan_move_meal_modal.dart';

class PlanDayMealTile extends StatefulWidget {
  final bool enableVoting;
  final PlanMeal planMeal;

  const PlanDayMealTile(this.planMeal, {Key? key, this.enableVoting = false})
      : super(key: key);

  @override
  State<PlanDayMealTile> createState() => _PlanDayMealTileState();
}

class _PlanDayMealTileState extends State<PlanDayMealTile> {
  bool _voteIsLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: kPadding / 2),
      child: widget.planMeal.meal.startsWith(kPlaceholderSymbol)
          ? GestureDetector(
              onTap: _editPlaceholder,
              onLongPress: _openMoveModal,
              child: _buildDataRow(
                context,
                placeholder: widget.planMeal.meal.split(kPlaceholderSymbol)[1],
              ),
            )
          : FutureBuilder<Meal?>(
              future: MealService.getMealById(widget.planMeal.meal),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    final meal = snapshot.data!;
                    return GestureDetector(
                      onTap: () => AutoRouter.of(context)
                          .push(MealScreenRoute(id: meal.id!)),
                      onLongPress: _openMoveModal,
                      child: _buildDataRow(context, meal: meal),
                    );
                  } else {
                    final currentPlanId = context.read(planProvider).state!.id;
                    PlanService.deletePlanMealFromPlan(
                        currentPlanId, widget.planMeal.id);
                    return _buildSkeletonLoading();
                  }
                } else {
                  return _buildSkeletonLoading();
                }
              },
            ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Row(
      children: const [
        SkeletonContainer(
          width: 50.0,
          height: 50.0,
          borderRadius: 1000,
        ),
        SizedBox(width: 10.0),
        SkeletonContainer(
          width: 150.0,
          height: 17.0,
          borderRadius: 1000,
        ),
      ],
    );
  }

  Row _buildDataRow(BuildContext context, {String? placeholder, Meal? meal}) {
    final bool isPlaceholder = placeholder != null && placeholder.isNotEmpty;
    final voteColor = widget.planMeal.upvotes!
            .contains(AuthenticationService.currentUser!.uid)
        ? Theme.of(context).primaryColor
        : Theme.of(context).textTheme.bodyText1!.color;

    return Row(
      children: [
        SizedBox(
          width: 50.0,
          height: 50.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10000),
            child: isPlaceholder
                ? SizedBox(
                    width: 50.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10000),
                      child: const Center(child: Icon(EvaIcons.code)),
                    ),
                  )
                : meal!.imageUrl != null && meal.imageUrl!.isNotEmpty
                    ? FoodlyNetworkImage(meal.imageUrl!)
                    : Image.asset(
                        'assets/images/food_fallback.png',
                        fit: BoxFit.cover,
                      ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: isPlaceholder || (meal!.tags == null || meal.tags!.isEmpty)
                ? AutoSizeText(
                    isPlaceholder ? placeholder : meal!.name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: AutoSizeText(
                          meal.name,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MealTag.tagHeight,
                        child: Wrap(
                          clipBehavior: Clip.hardEdge,
                          children: meal.tags!.map((e) => MealTag(e)).toList(),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (widget.enableVoting) ...[
          const SizedBox(width: kPadding / 2),
          Row(
            children: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _voteIsLoading
                      ? const SmallCircularProgressIndicator()
                      : Icon(
                          EvaIcons.arrowIosUpwardOutline,
                          color: voteColor,
                        ),
                ),
                onPressed: _voteIsLoading
                    ? null
                    : () => _voteMeal(
                          context.read(planProvider).state!.id,
                          AuthenticationService.currentUser!.uid,
                        ),
                splashRadius: 15.0,
              ),
              Text(
                widget.planMeal.upvotes!.length.toString(),
                style: TextStyle(
                  color: voteColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: kPadding / 2),
        ],
        PopupMenuButton(
          onSelected: (String val) =>
              _onMenuSelected(val, context.read(planProvider).state!.id!),
          icon: const Icon(EvaIcons.moreVerticalOutline),
          itemBuilder: (BuildContext context) {
            return [
              if (!widget.planMeal.meal.startsWith(kPlaceholderSymbol))
                PopupMenuItem(
                  value: 'tolist',
                  child: ListTile(
                    title: const Text('plan_ingredients_to_list').tr(),
                    leading: const Icon(EvaIcons.fileAddOutline),
                  ),
                ),
              PopupMenuItem(
                value: 'move',
                child: ListTile(
                  title: const Text('plan_move').tr(),
                  leading: const Icon(EvaIcons.cornerLeftUpOutline),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  title: const Text('plan_day_tile_remove').tr(),
                  leading: const Icon(EvaIcons.minusCircleOutline),
                ),
              ),
            ];
          },
        ),
      ],
    );
  }

  void _voteMeal(String? planId, String userId) async {
    setState(() {
      _voteIsLoading = true;
    });
    await PlanService.voteForPlanMeal(planId, widget.planMeal, userId);
    setState(() {
      _voteIsLoading = false;
    });
  }

  void _onMenuSelected(String value, String planId) async {
    if (value == 'delete') {
      PlanService.deletePlanMealFromPlan(planId, widget.planMeal.id);
    } else if (value == 'tolist') {
      final meal = await MealService.getMealById(widget.planMeal.meal);
      if (meal == null || meal.ingredients == null) {
        return;
      }
      final listId =
          (await ShoppingListService.getShoppingListByPlanId(planId)).id;
      for (final ingredient in meal.ingredients!) {
        ShoppingListService.addGrocery(
          listId!,
          Grocery(
            name: ingredient.name,
            amount: ingredient.amount,
            unit: ingredient.unit,
            productGroup: ingredient.productGroup,
          ),
        );
      }
    } else if (value == 'move') {
      _openMoveModal();
    }
  }

  Future<void> _openMoveModal() async {
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => PlanMoveMealModal(planMeal: widget.planMeal),
    );
  }

  Future<void> _editPlaceholder() async {
    final planId = context.read(planProvider).state!.id!;
    final text = await WidgetUtils.showPlaceholderEditDialog(
      context,
      initialText: widget.planMeal.meal.split(kPlaceholderSymbol)[1],
      required: false,
    );

    if (text == null) {
      return;
    }

    if (text.isNotEmpty) {
      widget.planMeal.meal = kPlaceholderSymbol + text;
      await PlanService.updatePlanMealFromPlan(planId, widget.planMeal);
    } else {
      await PlanService.deletePlanMealFromPlan(planId, widget.planMeal.id);
    }
  }
}
