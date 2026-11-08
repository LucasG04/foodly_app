import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../services/settings_service.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/main_button.dart';
import '../../widgets/sheet_header.dart';

/// Which details (duration, kcal) the plan's meal tiles show.
class ChangePlanMealInfoModal extends StatefulWidget {
  const ChangePlanMealInfoModal({super.key});

  @override
  State<ChangePlanMealInfoModal> createState() =>
      _ChangePlanMealInfoModalState();
}

class _ChangePlanMealInfoModalState extends State<ChangePlanMealInfoModal> {
  bool _duration = SettingsService.planMealShowDuration;
  bool _kcal = SettingsService.planMealShowKcal;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width > 599
        ? 580.0
        : MediaQuery.sizeOf(context).width * 0.8;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (MediaQuery.sizeOf(context).width - width) / 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SheetHeader(
            title: context.tr('settings_section_customization_plan_info'),
          ),
          _buildCheckboxTile(
            _duration,
            context.tr('settings_section_customization_plan_duration'),
            (value) => setState(() => _duration = value),
          ),
          _buildCheckboxTile(
            _kcal,
            context.tr('settings_section_customization_plan_kcal'),
            (value) => setState(() => _kcal = value),
          ),
          const SizedBox(height: kPadding),
          Center(
            child: MainButton(
              text: context.tr('save'),
              onTap: _save,
            ),
          ),
          SizedBox(height: WidgetUtils.sheetBottomPadding(context)),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile(
    bool value,
    String title,
    ValueChanged<bool> onChanged,
  ) {
    return CheckboxListTile(
      value: value,
      onChanged: (value) => onChanged(value!),
      title: Text(title),
      contentPadding: EdgeInsets.zero,
      activeColor: Theme.of(context).primaryColor,
    );
  }

  Future<void> _save() async {
    await SettingsService.setPlanMealInfo(
      showDuration: _duration,
      showKcal: _kcal,
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
