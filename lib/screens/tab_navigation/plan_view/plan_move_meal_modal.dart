import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../models/plan_meal.dart';
import '../../../providers/state_providers.dart';
import '../../../services/plan_service.dart';
import '../../../utils/basic_utils.dart';
import '../../../widgets/main_button.dart';
import '../../../widgets/progress_button.dart';

class PlanMoveMealModal extends StatefulWidget {
  final PlanMeal planMeal;

  const PlanMoveMealModal({
    required this.planMeal,
    Key? key,
  }) : super(key: key);

  @override
  State<PlanMoveMealModal> createState() => _PlanMoveMealModalState();
}

class _PlanMoveMealModalState extends State<PlanMoveMealModal> {
  late DateTime? _selectedDate;
  late MealType? _selectedMealType;
  late final List<DateTime> _dropdownValues;

  ButtonState _buttonState = ButtonState.normal;

  @override
  void initState() {
    _dropdownValues = getDropdownValues();
    _selectedDate = _dropdownValues[0];
    _selectedMealType = widget.planMeal.type;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width > 599
        ? 580.0
        : MediaQuery.of(context).size.width * 0.8;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (MediaQuery.of(context).size.width - width) / 2,
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
                    'plan_move'.tr().toUpperCase(),
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
          RadioListTile(
            title: const Text('plan_move_lunch').tr(),
            value: MealType.LUNCH,
            groupValue: _selectedMealType,
            onChanged: _changeMealType,
          ),
          RadioListTile(
            title: const Text('plan_move_dinner').tr(),
            value: MealType.DINNER,
            groupValue: _selectedMealType,
            onChanged: _changeMealType,
          ),
          const SizedBox(height: kPadding),
          MainButton(
            text: 'save'.tr(),
            onTap: _save,
            isProgress: true,
            buttonState: _buttonState,
          ),
          const SizedBox(height: kPadding * 2),
        ],
      ),
    );
  }

  void _changeDate(DateTime? value) {
    setState(() {
      _selectedDate = value;
    });
  }

  void _changeMealType(MealType? type) {
    setState(() {
      _selectedMealType = type;
    });
  }

  String getDropdownLabelByDate(DateTime date) {
    return '${DateFormat('EEEE', context.locale.toLanguageTag()).format(date)} - ${DateFormat('d. MMMM y', context.locale.toLanguageTag()).format(date)}';
  }

  List<DateTime> getDropdownValues() {
    final dates = BasicUtils.getPlanDateTimes(
        context.read(planProvider).state!.hourDiffToUtc!);
    for (var date in dates) {
      date = DateTime(date.year, date.month, date.day);
    }
    return dates;
  }

  Future<void> _save() async {
    widget.planMeal.date = _selectedDate!;
    widget.planMeal.type = _selectedMealType!;
    setState(() {
      _buttonState = ButtonState.inProgress;
    });
    await PlanService.updatePlanMealFromPlan(
      context.read(planProvider).state!.id,
      widget.planMeal,
    );
    setState(() {
      _buttonState = ButtonState.normal;
    });
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }
}
