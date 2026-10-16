import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../constants.dart';
import '../../../models/meal.dart';
import '../../../models/plan_meal.dart';
import '../../../providers/state_providers.dart';
import '../../../services/plan_service.dart';
import '../../../services/settings_service.dart';
import '../../../utils/analytics.dart';
import '../../../utils/basic_utils.dart';
import '../../../utils/of_context_mixin.dart';
import '../../../utils/widget_utils.dart';
import '../../../widgets/choice_tile.dart';
import '../../../widgets/main_button.dart';
import '../../../widgets/progress_button.dart';
import '../../../widgets/sheet_header.dart';

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
          SheetHeader(
            title: context.tr('plan_move_${widget.isMoving ? 'move' : 'add'}'),
          ),
          const SizedBox(height: kPadding / 2),
          _buildSectionLabel(context.tr('plan_move_day')),
          ChoiceTileGrid([
            for (final (i, date) in _dropdownValues.indexed)
              ChoiceTile(
                selected: date == _selectedDate,
                onTap: () => _changeDate(date),
                builder: (color) => [
                  Text(
                    i == 0
                        ? context.tr('plan_move_today')
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
          _buildSectionLabel(context.tr('plan_move_meal')),
          ChoiceTileGrid(
            [
              for (final (type, icon, label) in _mealTypes)
                ChoiceTile(
                  selected: type == _selectedMealType,
                  onTap: () => _changeMealType(type),
                  builder: (color) => [
                    Icon(icon, color: color),
                    Text(
                      context.tr(label),
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
              text: context.tr('save'),
              onTap: _save,
              isProgress: true,
              buttonState: _buttonState,
            ),
          ),
          SizedBox(height: WidgetUtils.sheetBottomPadding(context)),
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
        (MealType.LUNCH, Symbols.meal_lunch, 'plan_move_lunch'),
        (MealType.DINNER, Symbols.meal_dinner, 'plan_move_dinner'),
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
