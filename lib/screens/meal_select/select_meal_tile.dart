import 'package:auto_route/auto_route.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../app_router.gr.dart';
import '../../constants.dart';
import '../../models/meal.dart';
import '../../widgets/card_list_tile.dart';
import '../../widgets/foodly_network_image.dart';
import '../../widgets/skeleton_container.dart';
import '../../widgets/small_circular_progress_indicator.dart';

class SelectMealTile extends StatefulWidget {
  final Meal? meal;
  final Function()? onAddMeal;
  final Function()? secondaryAction;
  final bool isLoading;

  const SelectMealTile({
    this.meal,
    this.onAddMeal,
    this.secondaryAction,
    this.isLoading = false,
    super.key,
  }) : assert(isLoading || (!isLoading && meal != null && onAddMeal != null));

  @override
  State<SelectMealTile> createState() => _SelectMealTileState();
}

class _SelectMealTileState extends State<SelectMealTile> {
  _ButtonState _buttonState = _ButtonState.DEFAULT;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Align(
      child: GestureDetector(
        onTap: () {
          if (widget.meal == null || widget.meal!.id == null) {
            return;
          }
          AutoRouter.of(context).push(
            MealScreenRoute(id: widget.meal!.id!, showOptions: false),
          );
        },
        child: CardListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(kRadius),
            child: widget.isLoading
                ? const SkeletonContainer(
                    height: double.infinity,
                    width: double.infinity,
                  )
                : widget.meal!.imageUrl != null &&
                        widget.meal!.imageUrl!.isNotEmpty
                    ? FoodlyNetworkImage(widget.meal!.imageUrl!)
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
                child: widget.isLoading
                    ? SkeletonContainer(
                        height: 16.0,
                        width: width * 0.5,
                      )
                    : AutoSizeText(
                        widget.meal!.name,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
          actions: [
            if (widget.secondaryAction != null)
              CardListTileAction(
                widget: const Icon(EvaIcons.syncOutline),
                onTap: widget.secondaryAction,
              ),
            CardListTileAction(
              widget: widget.isLoading
                  ? const SizedBox()
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 375),
                      child: _buttonState == _ButtonState.DEFAULT
                          ? const Icon(EvaIcons.plus)
                          : _buttonState == _ButtonState.LOADING
                              ? const SmallCircularProgressIndicator()
                              : const Icon(
                                  EvaIcons.checkmark,
                                  color: Colors.green,
                                ),
                    ),
              onTap: widget.isLoading ? null : () => _selectMeal(),
            )
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

      await widget.onAddMeal!();

      if (!mounted) {
        return;
      }
      setState(() {
        _buttonState = _ButtonState.DONE;
      });
      AutoRouter.of(context).pop();
    }
  }
}

// ignore: constant_identifier_names
enum _ButtonState { DEFAULT, LOADING, DONE }
