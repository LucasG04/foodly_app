import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../utils/basic_utils.dart';

/// Dishes needed to plan a whole week.
const weekGoal = 7;

/// The line shows for 1–6 dishes, never while the list is [busy] (loading,
/// searching, tag-filtered) and never again once the goal was [reached].
bool showWeekGoal({
  required int count,
  required bool reached,
  required bool busy,
}) =>
    !reached && !busy && count > 0 && count < weekGoal;

/// "3 of 7 dishes for a week · Add more" under the meal list title.
class WeekGoalLine extends StatelessWidget {
  final int count;
  final VoidCallback onAdd;

  const WeekGoalLine({required this.count, required this.onAdd, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: BasicUtils.contentWidth(context),
        child: TextButton(
          onPressed: onAdd,
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.zero,
            foregroundColor: Theme.of(context).primaryColor,
          ),
          child: Text(
            context.tr('week_goal_line', args: ['$count']),
          ),
        ),
      ),
    );
  }
}
