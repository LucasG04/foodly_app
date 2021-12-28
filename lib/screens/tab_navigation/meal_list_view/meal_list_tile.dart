import 'package:auto_route/auto_route.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../../app_router.gr.dart';
import '../../../constants.dart';
import '../../../models/meal.dart';
import '../../../widgets/foodly_network_image.dart';
import '../../../widgets/meal_tag.dart';

class MealListTile extends StatelessWidget {
  final height = 75.0;
  final Meal meal;

  const MealListTile(this.meal);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Align(
      child: GestureDetector(
        onTap: () => AutoRouter.of(context).push(MealScreenRoute(id: meal.id!)),
        child: Container(
          width: width > 599 ? 600 : width * 0.9,
          height: height,
          margin: const EdgeInsets.symmetric(vertical: kPadding / 2),
          decoration: BoxDecoration(
            boxShadow: const [kSmallShadow],
            borderRadius: BorderRadius.circular(kRadius),
            color: Colors.white,
          ),
          child: Row(
            children: [
              SizedBox(
                height: height,
                width: height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(kRadius),
                  child: meal.imageUrl != null && meal.imageUrl!.isNotEmpty
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: AutoSizeText(
                          meal.name,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                        ),
                      ),
                      if (meal.tags!.isNotEmpty) SizedBox(
                              height: MealTag.tagHeight,
                              child: Wrap(
                                clipBehavior: Clip.hardEdge,
                                children:
                                    meal.tags!.map((e) => MealTag(e)).toList(),
                              ),
                            ) else const SizedBox(),
                    ],
                  ),
                ),
              ),
              Container(
                height: height / 2,
                width: height / 2,
                margin: const EdgeInsets.only(right: 20.0),
                child: Container(),
                // child: OutlineButton(
                //   onPressed: () => _selectMeal(),
                //   child: AnimatedSwitcher(
                //     duration: const Duration(milliseconds: 375),
                //     child: _buttonState == _ButtonState.DEFAULT
                //         ? Icon(EvaIcons.plusOutline)
                //         : _buttonState == _ButtonState.LOADING
                //             ? SmallCircularProgressIndicator()
                //             : Icon(
                //                 EvaIcons.checkmarkOutline,
                //                 color: Colors.green,
                //               ),
                //   ),
                // ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
