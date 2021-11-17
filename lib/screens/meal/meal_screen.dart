import 'package:auto_route/auto_route.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodly/services/meal_stat_service.dart';

import '../../app_router.gr.dart';
import '../../constants.dart';
import '../../models/ingredient.dart';
import '../../models/meal.dart';
import '../../providers/state_providers.dart';
import '../../services/meal_service.dart';
import '../../services/plan_service.dart';
import '../../utils/basic_utils.dart';
import '../../utils/convert_util.dart';
import '../../widgets/foodly_network_image.dart';
import '../../widgets/full_screen_loader.dart';
import '../../widgets/small_circular_progress_indicator.dart';
import 'border_icon.dart';
import 'confirm_delete_modal.dart';

class MealScreen extends StatefulWidget {
  final String id;

  const MealScreen({
    @PathParam() this.id,
  });

  @override
  _MealScreenState createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  bool _isDeleting;

  @override
  void initState() {
    _isDeleting = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final sidePadding = const EdgeInsets.symmetric(horizontal: kPadding);
    final currentPlanId = context.read(planProvider).state.id;

    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<Meal>(
            future: MealService.getMealById(widget.id),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final meal = snapshot.data;
                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: size.width > 700.0 ? 400.0 : 250.0,
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      elevation: 4,
                      stretch: true,
                      flexibleSpace: FlexibleSpaceBar(
                        stretchModes: <StretchMode>[StretchMode.zoomBackground],
                        titlePadding: const EdgeInsets.all(0),
                        background: Stack(
                          children: [
                            meal.imageUrl != null && meal.imageUrl.isNotEmpty
                                ? Positioned.fill(
                                    child: FoodlyNetworkImage(meal.imageUrl),
                                  )
                                : Positioned.fill(
                                    child: Image.asset(
                                      'assets/images/food_fallback.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                            Positioned(
                              width: size.width,
                              top: kPadding / 2 +
                                  MediaQuery.of(context).padding.top,
                              child: Padding(
                                padding: sidePadding,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: BorderIcon(
                                        height: 50,
                                        width: 50,
                                        child: Icon(
                                          EvaIcons.arrowBackOutline,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    meal.planId == currentPlanId
                                        ? BorderIcon(
                                            height: 50,
                                            width: 50,
                                            child: PopupMenuButton(
                                              padding: const EdgeInsets.all(0),
                                              onSelected: (value) =>
                                                  _onMenuSelected(
                                                value,
                                                meal,
                                                currentPlanId,
                                              ),
                                              itemBuilder: (context) => [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: ListTile(
                                                    title: Text(
                                                      'meal_details_edit',
                                                    ).tr(),
                                                    leading: Icon(
                                                      EvaIcons.edit2Outline,
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: ListTile(
                                                    title: Text(
                                                      'meal_details_delete',
                                                    ).tr(),
                                                    leading: Icon(
                                                      EvaIcons
                                                          .minusCircleOutline,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : SizedBox(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      title: SizedBox(),
                      leading: SizedBox(),
                    ),
                    SliverToBoxAdapter(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AutoSizeText(
                                          meal.name,
                                          style: TextStyle(
                                            fontSize: 26.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 5.0),
                                        Text(
                                          meal.source != null &&
                                                  meal.source.isNotEmpty
                                              ? 'meal_details_source_known'
                                                  .tr(args: [meal.source])
                                              : 'meal_details_source_unknown'
                                                  .tr(),
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyText1
                                                .color
                                                .withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  BorderIcon(
                                    child: Text(
                                      'meal_details_duration_trailing'
                                          .tr(args: [meal.duration.toString()]),
                                      style: TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                      horizontal: 15,
                                    ),
                                    withBorder: true,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: kPadding),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  ...meal.tags.map((e) => TagTile(e)).toList(),
                                  SizedBox(width: kPadding),
                                ],
                              ),
                            ),
                            SizedBox(height: kPadding),
                            ..._buildSection(
                              'meal_details_ingredient'.tr(),
                              Container(
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: meal.ingredients.length,
                                  separatorBuilder: (context, index) =>
                                      Divider(),
                                  itemBuilder: (context, index) =>
                                      _buildIngredientTile(
                                    meal.ingredients[index],
                                  ),
                                  padding: const EdgeInsets.all(0),
                                ),
                              ),
                            ),
                            SizedBox(height: kPadding),
                            ..._buildSection(
                              'meal_details_instructions'.tr(),
                              MarkdownBody(
                                data: meal.instructions ?? '',
                                styleSheet: MarkdownStyleSheet.fromTheme(
                                  ThemeData(
                                    textTheme: TextTheme(
                                      bodyText1: TextStyle(fontSize: 16),
                                      bodyText2: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: kPadding),
                            SizedBox(height: 100.0),
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
                );
              } else {
                return Center(child: SmallCircularProgressIndicator());
              }
            },
          ),
          _isDeleting
              ? FullScreenLoader(
                  backgroundColor: Colors.black45,
                )
              : SizedBox(),
        ],
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
              child: Text(
                ConvertUtil.amountToString(ingredient.amount, ingredient.unit),
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 18.0),
              ),
            ),
            SizedBox(
              width: constraints.maxWidth * 0.5 - kPadding / 2,
              child: Text(
                ingredient.name.toString(),
                textAlign: TextAlign.start,
                style: TextStyle(fontSize: 18.0),
              ),
            ),
          ],
        );
      }),
    );
  }

  List<Widget> _buildSection(String title, Widget content) {
    final sidePadding = EdgeInsets.symmetric(horizontal: kPadding);
    return [
      Padding(
        padding: sidePadding,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      SizedBox(height: kPadding),
      Padding(padding: sidePadding, child: content),
    ];
  }

  void _onMenuSelected(String value, Meal meal, String planId) async {
    if (meal.planId != planId) return;
    switch (value) {
      case 'edit':
        final result = await ExtendedNavigator.root.push(
          Routes.mealCreateScreen(id: meal.id),
        );

        if (result != null && result is Meal) {
          setState(() {});
        }
        break;
      case 'delete':
        _openConfirmDelete(meal);
        break;
      default:
    }
  }

  void _openConfirmDelete(Meal meal) async {
    final result = await showModalBottomSheet<bool>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      isScrollControlled: true,
      context: context,
      builder: (_) => ConfirmDeleteModal(meal),
    );

    if (result != null && result) {
      setState(() {
        _isDeleting = true;
      });
      await MealService.deleteMeal(meal.id);
      final plan = context.read(planProvider).state;
      await MealStatService.deleteStatByMealId(plan.id, meal.id);

      if (plan.meals != null && plan.meals.length > 0) {
        for (var planMeal in plan.meals.where((e) => e.meal == meal.id)) {
          await PlanService.deletePlanMealFromPlan(plan.id, planMeal.id);
        }
      }

      ExtendedNavigator.root.pop();
      _isDeleting = false;
    }
  }
}

class TagTile extends StatelessWidget {
  final String text;

  const TagTile(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BorderIcon(
            height: 50.0,
            child: Text(text, style: TextStyle(fontSize: 16.0)),
            withBorder: true,
          ),
        ],
      ),
    );
  }
}
