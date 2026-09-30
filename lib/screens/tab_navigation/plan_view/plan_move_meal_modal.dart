import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../models/meal.dart';
import '../../../models/plan_meal.dart';
import '../../../providers/state_providers.dart';
import '../../../services/plan_service.dart';
import '../../../services/settings_service.dart';
import '../../../utils/analytics.dart';
import '../../../utils/basic_utils.dart';
import '../../../utils/of_context_mixin.dart';
import '../../../widgets/main_button.dart';
import '../../../widgets/progress_button.dart';

class PlanMoveMealModal extends ConsumerStatefulWidget {
  final bool isMoving;
  final PlanMeal? planMeal;
  final Meal? meal;

  const PlanMoveMealModal({
    required this.isMoving,
    this.planMeal,
    this.meal,
    super.key,
  }) : assert((isMoving && planMeal != null) || (!isMoving && meal != null));

  @override
  PlanMoveMealModalState createState() => PlanMoveMealModalState();
}

class PlanMoveMealModalState extends ConsumerState<PlanMoveMealModal>
    with OfContextMixin {
  late DateTime _selectedDate;
  late MealType _selectedMealType;
  late final List<DateTime> _dropdownValues;

  ButtonState _buttonState = ButtonState.normal;

  @override
  void initState() {
    _dropdownValues = getDropdownValues();
    final rawDate =
        widget.isMoving ? widget.planMeal!.date : _dropdownValues.first;
    _selectedDate = DateTime(rawDate.year, rawDate.month, rawDate.day);
    _selectedMealType =
        widget.isMoving ? widget.planMeal!.type : MealType.LUNCH;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = mediaSize.width > 599 ? 580.0 : mediaSize.width * 0.8;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (mediaSize.width - width) / 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: kPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'plan_move_${widget.isMoving ? 'move' : 'add'}'
                        .tr()
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: kPadding),
          _buildSectionLabel('plan_move_day'.tr()),
          _buildTileGrid([
            for (final (i, date) in _dropdownValues.indexed)
              _buildTile(
                selected: date == _selectedDate,
                onTap: () => _changeDate(date),
                builder: (color) => [
                  Text(
                    i == 0
                        ? 'plan_move_today'.tr()
                        : DateFormat.E(context.locale.toLanguageTag())
                            .format(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color, fontSize: 13),
                  ),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
          ]),
          const SizedBox(height: kPadding),
          _buildSectionLabel('plan_move_meal'.tr()),
          _buildTileGrid(
            [
              for (final (type, icon, label) in _mealTypes)
                _buildTile(
                  selected: type == _selectedMealType,
                  onTap: () => _changeMealType(type),
                  builder: (color) => [
                    Icon(icon, color: color),
                    Text(
                      label.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
            // All active meal types share one row.
            columns: _mealTypes.length,
          ),
          const SizedBox(height: kPadding),
          Center(
            child: MainButton(
              text: 'save'.tr(),
              onTap: _save,
              isProgress: true,
              buttonState: _buttonState,
            ),
          ),
          const SizedBox(height: kPadding * 2),
        ],
      ),
    );
  }

  void _changeDate(DateTime? value) {
    if (value == null) {
      return;
    }
    setState(() {
      _selectedDate = value;
    });
  }

  void _changeMealType(MealType? type) {
    if (type == null) {
      return;
    }
    setState(() {
      _selectedMealType = type;
    });
  }

  /// The active meal types with their icon and label key.
  List<(MealType, IconData, String)> get _mealTypes => [
        (
          MealType.BREAKFAST,
          Icons.free_breakfast_outlined,
          'plan_move_breakfast',
        ),
        (MealType.LUNCH, Icons.lunch_dining_outlined, 'plan_move_lunch'),
        (MealType.DINNER, Icons.dinner_dining_outlined, 'plan_move_dinner'),
      ].where((m) => _showMealTile(m.$1)).toList();

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kPadding / 2),
      child: Text(
        text,
        style: TextStyle(
          color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.6),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Equal-width tiles, [columns] per row.
  Widget _buildTileGrid(List<Widget> tiles, {int columns = 4}) {
    return Column(
      children: [
        for (var row = 0; row < tiles.length; row += columns)
          Padding(
            padding: EdgeInsets.only(top: row == 0 ? 0 : kPadding / 2),
            child: Row(
              children: [
                for (var i = row; i < row + columns; i++) ...[
                  if (i > row) const SizedBox(width: kPadding / 2),
                  Expanded(
                    child: i < tiles.length ? tiles[i] : const SizedBox(),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  /// A choice tile, filled with the primary color when [selected]. [builder]
  /// gets the matching content color.
  Widget _buildTile({
    required bool selected,
    required VoidCallback onTap,
    required List<Widget> Function(Color color) builder,
  }) {
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    return Semantics(
      selected: selected,
      child: Material(
        color:
            selected ? theme.primaryColor : textColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(kRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: kPadding / 2,
              horizontal: kPadding / 4,
            ),
            child: Column(
              children: builder(selected ? Colors.white : textColor),
            ),
          ),
        ),
      ),
    );
  }

  List<DateTime> getDropdownValues() {
    return BasicUtils.getPlanDateTimes(ref.read(planProvider)!.hourDiffToUtc!);
  }

  Future<void> _save() async {
    PlanMeal? newPlanMeal = null; // ignore: avoid_init_to_null
    if (widget.isMoving) {
      widget.planMeal!.date = _selectedDate;
      widget.planMeal!.type = _selectedMealType;
    } else {
      newPlanMeal = PlanMeal(
        date: _selectedDate,
        type: _selectedMealType,
        meal: widget.meal!.id!,
      );
    }
    setState(() {
      _buttonState = ButtonState.inProgress;
    });
    if (widget.isMoving) {
      await PlanService.updatePlanMealFromPlan(
        ref.read(planProvider)!.id,
        widget.planMeal!,
      );
      logEvent(AnalyticsEvent.planMealMove);
    } else {
      await PlanService.addPlanMealToPlan(
        ref.read(planProvider)!.id!,
        newPlanMeal!,
      );
      logEvent(AnalyticsEvent.addMealToPlan, {'source': 'meal_screen'});
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _buttonState = ButtonState.normal;
    });
    Navigator.pop(context, true);
  }

  bool _showMealTile(MealType type) {
    return SettingsService.activeMealTypes.contains(type);
  }
}
