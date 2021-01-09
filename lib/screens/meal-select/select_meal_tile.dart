import 'package:cached_network_image/cached_network_image.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:foodly/constants.dart';
import 'package:foodly/models/meal.dart';
import 'package:foodly/widgets/meal_tag.dart';
import 'package:foodly/widgets/small_circular_progress_indicator.dart';

class SelectMealTile extends StatefulWidget {
  final Meal meal;
  final Function() onAddMeal;

  SelectMealTile({
    @required this.meal,
    @required this.onAddMeal,
  });

  @override
  _SelectMealTileState createState() => _SelectMealTileState();

  static double get fullHeight => 75.0 + kPadding;
}

class _SelectMealTileState extends State<SelectMealTile> {
  _ButtonState _buttonState = _ButtonState.DEFAULT;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = 75.0;

    return Align(
      alignment: Alignment.center,
      child: Container(
        width: width > 599 ? 600 : width * 0.9,
        height: height,
        margin: const EdgeInsets.symmetric(vertical: kPadding / 2),
        decoration: BoxDecoration(
          boxShadow: [kSmallShadow],
          borderRadius: BorderRadius.circular(kRadius),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              height: height,
              width: height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(kRadius),
                child: widget.meal.imageUrl != null &&
                        widget.meal.imageUrl.isNotEmpty
                    ? CachedNetworkImage(imageUrl: widget.meal.imageUrl)
                    : Image.asset('assets/images/food_fallback.png'),
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
                        children:
                            widget.meal.tags.map((e) => MealTag(e)).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: height / 2,
              width: height / 2,
              margin: const EdgeInsets.only(right: 20.0),
              child: OutlineButton(
                onPressed: () => _selectMeal(),
                child: AnimatedSwitcher(
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
              ),
            ),
          ],
        ),
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
      await Future.delayed(Duration(seconds: 3));
      setState(() {
        _buttonState = _ButtonState.DEFAULT;
      });
    }
  }
}

enum _ButtonState { DEFAULT, LOADING, DONE }
