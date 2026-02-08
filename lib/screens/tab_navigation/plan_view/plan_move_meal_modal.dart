import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../models/meal.dart';
import '../../../models/plan_meal.dart';
import '../../../providers/state_providers.dart';
import '../../../services/plan_service.dart';
import '../../../services/settings_service.dart';
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
    _selectedDate =
        widget.isMoving ? widget.planMeal!.date : _dropdownValues.first;
    _selectedMealType =
        widget.isMoving ? widget.planMeal!.type : MealType.LUNCH;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = media.size.width > 599 ? 580.0 : media.size.width * 0.8;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (media.size.width - width) / 2,
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
          DropdownButton(
            value: _selectedDate,
            dropdownColor: theme.scaffoldBackgroundColor,
            items: _dropdownValues
                .map(
                  (date) => DropdownMenuItem(
                    value: date,
                    child: Text(getDropdownLabelByDate(date)),
                  ),
                )
                .toList(),
            onChanged: _changeDate,
            isExpanded: true,
          ),
          const SizedBox(height: kPadding / 2),
          RadioGroup<MealType>(
            groupValue: _selectedMealType,
            onChanged: _changeMealType,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showMealTile(MealType.BREAKFAST))
                  RadioListTile(
                    title: const Text('plan_move_breakfast').tr(),
                    value: MealType.BREAKFAST,
                    activeColor: theme.primaryColor,
                  ),
                if (_showMealTile(MealType.LUNCH))
                  RadioListTile(
                    title: const Text('plan_move_lunch').tr(),
                    value: MealType.LUNCH,
                    activeColor: theme.primaryColor,
                  ),
                if (_showMealTile(MealType.DINNER))
                  RadioListTile(
                    title: const Text('plan_move_dinner').tr(),
                    value: MealType.DINNER,
                    activeColor: theme.primaryColor,
                  ),
              ],
            ),
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

  String getDropdownLabelByDate(DateTime date) {
    return '${DateFormat('EEEE', context.locale.toLanguageTag()).format(date)} - ${DateFormat('d. MMMM y', context.locale.toLanguageTag()).format(date)}';
  }

  List<DateTime> getDropdownValues() {
    final dates =
        BasicUtils.getPlanDateTimes(ref.read(planProvider)!.hourDiffToUtc!);
    for (var date in dates) {
      date = DateTime(date.year, date.month, date.day);
    }
    return dates;
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
    } else {
      await PlanService.addPlanMealToPlan(
        ref.read(planProvider)!.id!,
        newPlanMeal!,
      );
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
