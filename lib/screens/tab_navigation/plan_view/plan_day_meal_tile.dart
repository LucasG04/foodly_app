import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:foodly/models/grocery.dart';
import 'package:foodly/services/shopping_list_service.dart';

import '../../../constants.dart';
import '../../../models/meal.dart';
import '../../../models/plan_meal.dart';
import '../../../providers/state_providers.dart';
import '../../../services/meal_service.dart';
import '../../../services/plan_service.dart';
import '../../../widgets/meal_tag.dart';

class PlanDayMealTile extends StatelessWidget {
  final bool enableVoting;
  final PlanMeal planMeal;

  PlanDayMealTile(this.planMeal, [this.enableVoting = false]);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: kPadding / 2),
      child: planMeal.meal.startsWith(kPlaceholderSymbol)
          ? _buildDataRow(
              context,
              placeholder: planMeal.meal.split(kPlaceholderSymbol)[1],
            )
          : FutureBuilder<Meal>(
              future: MealService.getMealById(this.planMeal.meal),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final meal = snapshot.data;
                  return _buildDataRow(context, meal: meal);
                } else {
                  // TODO: Skeleton loading
                  return CircularProgressIndicator();
                }
              },
            ),
    );
  }

  Row _buildDataRow(BuildContext context, {String placeholder, Meal meal}) {
    bool isPlaceholder = placeholder != null && placeholder.isNotEmpty;
    return Row(
      children: [
        Container(
          width: 50.0,
          height: 50.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10000),
            child: isPlaceholder
                ? Container(
                    width: 50.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10000),
                      child: Center(child: Icon(EvaIcons.codeOutline)),
                    ),
                  )
                : meal.imageUrl != null && meal.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: meal.imageUrl,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        'assets/images/food_fallback.png',
                        fit: BoxFit.cover,
                      ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: isPlaceholder || (meal.tags == null || meal.tags.isEmpty)
                ? Text(
                    isPlaceholder ? placeholder : meal.name,
                    style: TextStyle(
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
                        child: Text(
                          meal.name,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        height: MealTag.tagHeight,
                        child: Wrap(
                          clipBehavior: Clip.hardEdge,
                          children: meal.tags.map((e) => MealTag(e)).toList(),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (enableVoting) ...[
          SizedBox(width: kPadding / 2),
          Column(
            children: [
              IconButton(
                icon: Icon(EvaIcons.arrowIosUpwardOutline),
                onPressed: () => print('upvote'),
                splashRadius: 15.0,
              ),
              Text(planMeal.upvotes.length.toString()),
            ],
          ),
          SizedBox(width: kPadding / 4),
          Column(
            children: [
              IconButton(
                icon: Icon(EvaIcons.arrowIosDownwardOutline),
                onPressed: () => print('downvote'),
                splashRadius: 15.0,
              ),
              Text(planMeal.downvotes.length.toString()),
            ],
          ),
          SizedBox(width: kPadding / 2),
        ],
        PopupMenuButton(
          onSelected: (val) =>
              _onMenuSelected(val, context.read(planProvider).state.id),
          icon: Icon(EvaIcons.moreVerticalOutline),
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem(
                value: 'tolist',
                child: ListTile(
                  title: Text('Zutaten auf Einkaufsliste'),
                  leading: Icon(EvaIcons.fileAddOutline),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  title: Text('Löschen'),
                  leading: Icon(EvaIcons.minusCircleOutline),
                ),
              ),
            ];
          },
        ),
      ],
    );
  }

  void _onMenuSelected(String value, String planId) async {
    if (value == 'delete') {
      PlanService.deletePlanMealFromPlan(planId, planMeal);
    } else if (value == 'tolist') {
      final meal = await MealService.getMealById(planMeal.meal);
      final listId =
          (await ShoppingListService.getShoppingListByPlanId(planId)).id;
      for (var ingredient in meal.ingredients) {
        ShoppingListService.addGrocery(listId, new Grocery(name: ingredient));
      }
    }
  }
}
