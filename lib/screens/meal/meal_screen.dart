import 'package:auto_route/auto_route.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foodly/providers/state_providers.dart';
import 'package:foodly/screens/meal/confirm_delete_modal.dart';
import 'package:foodly/services/plan_service.dart';
import 'package:foodly/utils/convert_util.dart';
import 'package:foodly/widgets/foodly_network_image.dart';
import 'package:foodly/widgets/full_screen_loader.dart';
import 'package:foodly/widgets/skeleton_container.dart';

import '../../app_router.gr.dart';
import '../../constants.dart';
import '../../models/ingredient.dart';
import '../../models/meal.dart';
import '../../services/meal_service.dart';
import '../../utils/no_glowing_overscroll_indicator_behavior.dart';
import '../../widgets/small_circular_progress_indicator.dart';
import 'border_icon.dart';

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
                return ScrollConfiguration(
                  behavior: NoGlowingOverscrollIndicatorBehavior(),
                  child: SingleChildScrollView(
                    physics: ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            meal.imageUrl != null && meal.imageUrl.isNotEmpty
                                ? Center(
                                    child: SizedBox(
                                      height: 300,
                                      width: double.infinity,
                                      child: FoodlyNetworkImage(meal.imageUrl),
                                    ),
                                  )
                                : Image.asset(
                                    'assets/images/food_fallback.png',
                                    fit: BoxFit.cover,
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
                                                    title: Text('Bearbeiten'),
                                                    leading: Icon(
                                                        EvaIcons.edit2Outline),
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: ListTile(
                                                    title: Text('Löschen'),
                                                    leading: Icon(EvaIcons
                                                        .minusCircleOutline),
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
                        SizedBox(height: kPadding),
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
                                      style: TextStyle(
                                        fontSize: 26.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 5.0),
                                    Text(
                                      meal.source != null &&
                                              meal.source.isNotEmpty
                                          ? 'von ${meal.source}'
                                          : 'von Unbekannt',
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
                                  '${meal.duration.toString()} Minuten',
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: kPadding),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: BouncingScrollPhysics(),
                          child: Row(
                            children: meal.tags.map((e) => TagTile(e)).toList(),
                          ),
                        ),
                        SizedBox(height: kPadding),
                        ..._buildSection(
                          'Zutaten',
                          Container(
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: meal.ingredients.length,
                              separatorBuilder: (context, index) => Divider(),
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
                          'Zubereitung',
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
                      ],
                    ),
                  ),
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
    final amountWidth = MediaQuery.of(context).size.width * 0.3 - kPadding;
    final nameWidth = MediaQuery.of(context).size.width * 0.5 - kPadding;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: kPadding / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox(
            width: amountWidth,
            child: Text(
              ConvertUtil.amountToString(ingredient.amount, ingredient.unit),
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 18.0),
            ),
          ),
          SizedBox(
            width: nameWidth,
            child: Text(
              '${ingredient.name}',
              textAlign: TextAlign.start,
              style: TextStyle(fontSize: 18.0),
            ),
          ),
        ],
      ),
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
          ),
        ],
      ),
    );
  }
}
