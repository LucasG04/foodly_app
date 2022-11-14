import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants.dart';
import '../../../providers/state_providers.dart';
import '../../../services/plan_service.dart';
import '../../../widgets/main_button.dart';
import '../../../widgets/main_text_field.dart';
import '../../../widgets/progress_button.dart';

class ChangePlanNameModal extends ConsumerStatefulWidget {
  const ChangePlanNameModal({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
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
                    'settings_section_plan_change_name'.tr().toUpperCase(),
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
          MainTextField(
            controller: _textEditingController,
            errorText: _nameValid
                ? null
                : 'settings_section_plan_change_name_error'.tr(),
            placeholder: 'settings_section_plan_change_name_placeholder'.tr(),
            onSubmit: _save,
            textInputAction: TextInputAction.go,
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
          SizedBox(
            height: kPadding +
                (MediaQuery.of(context).viewInsets.bottom == 0
                    ? 0
                    : MediaQuery.of(context).viewInsets.bottom),
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
