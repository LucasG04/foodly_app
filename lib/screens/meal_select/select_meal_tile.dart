import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/meal.dart';
import '../../widgets/card_list_tile.dart';
import '../../widgets/meal_tag.dart';
import '../../widgets/small_circular_progress_indicator.dart';

class SelectMealTile extends StatefulWidget {
  final Meal meal;
  final Function() onAddMeal;

  SelectMealTile({
    @required this.meal,
    @required this.onAddMeal,
  });

  @override
  _SelectMealTileState createState() => _SelectMealTileState();
}

class _SelectMealTileState extends State<SelectMealTile> {
  _ButtonState _buttonState = _ButtonState.DEFAULT;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: CardListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(kRadius),
          child: widget.meal.imageUrl != null && widget.meal.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: widget.meal.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Image.asset(
                    'assets/images/food_fallback.png',
                  ),
                )
              : Image.asset(
                  'assets/images/food_fallback.png',
                  fit: BoxFit.cover,
                ),
        ),
        content: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Text(
                widget.meal.name,
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
                children: widget.meal.tags.map((e) => MealTag(e)).toList(),
              ),
            ),
          ],
        ),
        trailing: AnimatedSwitcher(
          duration: const Duration(milliseconds: 375),
          child: _buttonState == _ButtonState.DEFAULT
              ? Icon(EvaIcons.plusOutline)
              : _buttonState == _ButtonState.LOADING
                  ? SmallCircularProgressIndicator()
                  : Icon(
                      EvaIcons.checkmarkOutline,
                      color: Colors.green,
                    ),
        ),
        trailingAction: () => _selectMeal(),
      ),
    );
  }

  void _selectMeal() async {
    if (_buttonState != _ButtonState.LOADING) {
      setState(() {
        _buttonState = _ButtonState.LOADING;
      });

      await widget.onAddMeal();

      setState(() {
        _buttonState = _ButtonState.DONE;
      });
      // await Future.delayed(Duration(seconds: 3));
      // setState(() {
      //   _buttonState = _ButtonState.DEFAULT;
      // });
      ExtendedNavigator.root.pop();
    }
  }
}

enum _ButtonState { DEFAULT, LOADING, DONE }
