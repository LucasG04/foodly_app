import 'package:auto_route/auto_route.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../../app_router.gr.dart';
import '../../../constants.dart';
import '../../../models/meal.dart';
import '../../../widgets/foodly_network_image.dart';
import '../../../widgets/meal_tag.dart';
import '../../../widgets/skeleton_container.dart';

class MealListTile extends StatelessWidget {
  final Meal? meal;

  const MealListTile(this.meal, {Key? key}) : super(key: key);

  double get height => 80.0;

  @override
  Widget build(BuildContext context) {
    return _buildWrapper(
      context: context,
      child: Row(
        children: [
          _buildImageWrapper(
            child: meal == null
                ? _buildLoadingImage()
                : meal!.imageUrl != null && meal!.imageUrl!.isNotEmpty
                    ? FoodlyNetworkImage(meal!.imageUrl!)
                    : Image.asset(
                        'assets/images/food_fallback.png',
                        fit: BoxFit.cover,
                      ),
          ),
          _buildTileContent(
            title: meal == null
                ? _buildLoadingTitle()
                : AutoSizeText(
                    meal!.name,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
            subtitle: meal != null && meal!.tags!.isNotEmpty
                ? SizedBox(
                    height: MealTag.tagHeight,
                    child: Wrap(
                      clipBehavior: Clip.hardEdge,
                      children: meal!.tags!.map((e) => MealTag(e)).toList(),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Expanded _buildTileContent({
    required Widget title,
    Widget? subtitle,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: title,
            ),
            if (subtitle != null) subtitle
          ],
        ),
      ),
    );
  }

  Widget _buildWrapper({
    required BuildContext context,
    required Widget child,
  }) {
    final width = MediaQuery.of(context).size.width;
    return Align(
      child: GestureDetector(
        onTap: () {
          if (meal != null && meal!.id != null) {
            AutoRouter.of(context).push(MealScreenRoute(id: meal!.id!));
          }
        },
        child: Container(
          width: width > 599 ? 600 : width * 0.9,
          height: height,
          margin: const EdgeInsets.symmetric(vertical: kPadding / 2),
          decoration: BoxDecoration(
            boxShadow: const [kSmallShadow],
            borderRadius: BorderRadius.circular(kRadius),
            color: Colors.white,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildImageWrapper({required Widget child}) {
    return SizedBox(
      height: height,
      width: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadius),
        child: child,
      ),
    );
  }

  Widget _buildLoadingImage() {
    return const SkeletonContainer(
        width: double.infinity, height: double.infinity);
  }

  Widget _buildLoadingTitle() {
    return LayoutBuilder(builder: (context, constraints) {
      return SkeletonContainer(
        height: Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16,
        width: constraints.maxWidth * 0.7,
      );
    });
  }
}
