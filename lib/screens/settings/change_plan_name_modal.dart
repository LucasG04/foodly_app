import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../providers/state_providers.dart';
import '../../../services/plan_service.dart';
import '../../../widgets/main_button.dart';
import '../../../widgets/main_text_field.dart';
import '../../../widgets/progress_button.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/sheet_header.dart';

class ChangePlanNameModal extends ConsumerStatefulWidget {
  const ChangePlanNameModal({super.key});

  @override
  _ChangePlanNameModalState createState() => _ChangePlanNameModalState();
}

class _ChangePlanNameModalState extends ConsumerState<ChangePlanNameModal> {
  final TextEditingController _textEditingController = TextEditingController();
  ButtonState _buttonState = ButtonState.normal;
  bool _nameValid = true;

  @override
  void initState() {
    final currentName = ref.read(planProvider)!.name;
    _textEditingController.text = currentName!;
    super.initState();
  }

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
            title: context.tr('settings_section_plan_change_name'),
          ),
          MainTextField(
            controller: _textEditingController,
            errorText: _nameValid
                ? null
                : context.tr('settings_section_plan_change_name_error'),
            placeholder:
                context.tr('settings_section_plan_change_name_placeholder'),
            onSubmit: _save,
            textInputAction: TextInputAction.go,
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
          SizedBox(
            height: MediaQuery.viewInsetsOf(context).bottom == 0
                ? WidgetUtils.sheetBottomPadding(context)
                : kPadding + MediaQuery.viewInsetsOf(context).bottom,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final newName = _textEditingController.text.trim();
    if (newName.isEmpty) {
      setState(() {
        _nameValid = false;
        _buttonState = ButtonState.error;
      });
      return;
    }
    setState(() {
      _buttonState = ButtonState.inProgress;
    });
    final newPlan = ref.read(planProvider)!;
    newPlan.name = newName;
    await PlanService.updatePlan(newPlan);
    setState(() {
      _buttonState = ButtonState.normal;
    });
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }
}
