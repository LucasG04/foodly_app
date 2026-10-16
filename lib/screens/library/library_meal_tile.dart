import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../models/library_meal.dart';
import '../tab_navigation/meal_list_view/meal_list_tile.dart';

/// A library dish in the list: the meal list's tile (duration as first tag)
/// plus a selection circle ([onToggle]). The list never shows dishes the
/// plan already has.
class LibraryMealTile extends StatelessWidget {
  final LibraryMeal meal;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const LibraryMealTile({
    required this.meal,
    required this.selected,
    required this.onTap,
    required this.onToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final preview = meal.toPreviewMeal()
      ..tags = [
        context.tr('library_duration', args: ['${meal.duration}']),
        ...meal.tags,
      ];
    return MealListTile(
      preview,
      onTap: onTap,
      trailing: Semantics(
        checked: selected,
        label: context.tr('library_select'),
        child: IconButton(
          onPressed: onToggle,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Icon(
              selected
                  ? EvaIcons.checkmarkCircle2
                  : EvaIcons.radioButtonOffOutline,
              key: ValueKey(selected),
              color: selected
                  ? Theme.of(context).primaryColor
                  : Colors.black.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}
