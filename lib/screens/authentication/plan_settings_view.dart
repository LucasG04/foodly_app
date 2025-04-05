import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/plan.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/progress_button.dart';
import '../../widgets/toggle_tab/flutter_toggle_tab.dart';
import 'authentication_keys.dart';

class PlanSettingsView extends StatefulWidget {
  final Plan? plan;
  final void Function() navigateBack;
  final void Function(Plan) navigateForward;

  const PlanSettingsView({
    required this.plan,
    required this.navigateBack,
    required this.navigateForward,
    super.key,
  });

  @override
  State<PlanSettingsView> createState() => _PlanSettingsViewState();
}

class _PlanSettingsViewState extends State<PlanSettingsView> {
  ButtonState? _buttonState;

  TextEditingController? _nameController;
  String? _nameErrorText;
  String? _unknownErrorText;

  @override
  void initState() {
    _buttonState = ButtonState.normal;

    _nameController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final contentWidth = size.width > 599 ? 600 : size.width * 0.9;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (MediaQuery.of(context).size.width - contentWidth) / 2,
      ),
      child: Column(
        children: [
          SizedBox(height: kPadding + MediaQuery.of(context).padding.top),
          FlutterToggleTab(
            width: 80,
            borderRadius: 15,
            selectedTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            unSelectedTextStyle: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            labels: ['plan_settings_create_plan'.tr()],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Wrap(
                children: [
                  Text(
                    'plan_settings_what_name',
                    style: _titleTextStyle,
                  ).tr(),
                ],
              ),
            ),
          ),
          const SizedBox(height: kPadding),
          MainTextField(
            key: AuthenticationKeys.buttonPlanNameNext,
            controller: _nameController,
            title: 'plan_settings_name_title'.tr(),
            textInputAction: TextInputAction.go,
            errorText: _nameErrorText,
          ),
          SizedBox(
            height: size.height * 0.2 +
                MediaQuery.of(context).viewInsets.bottom / 4,
            child: _unknownErrorText != null
                ? Row(
                    children: [
                      const Icon(EvaIcons.alertTriangleOutline,
                          color: Colors.red),
                      const SizedBox(width: kPadding),
                      Expanded(
                        child: Text(
                          _unknownErrorText ?? '',
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    ],
                  )
                : const SizedBox(),
          ),
          LayoutBuilder(builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MainButton(
                  iconData: Icons.arrow_back_ios_new_rounded,
                  width: constraints.maxWidth * 0.25,
                  onTap: widget.navigateBack,
                  isSecondary: true,
                ),
                MainButton(
                  text: 'modal_password_reset_next'.tr(),
                  width: constraints.maxWidth * 0.65,
                  onTap: _updatePlanSettings,
                  isProgress: true,
                  buttonState: _buttonState,
                ),
              ],
            );
          }),
          const SizedBox(height: kPadding * 2),
        ],
      ),
    );
  }

  TextStyle get _titleTextStyle => const TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.w700,
      );

  bool _validateName() {
    if (_nameController!.text.isEmpty ||
        _nameController!.text.trim().length < 3) {
      setState(() {
        _nameErrorText = 'plan_settings_error_name'.tr();
      });
      return false;
    }
    return true;
  }

  void _updatePlanSettings() async {
    _resetErrors();

    if (_validateName()) {
      final plan = Plan(name: _nameController!.text.trim());
      widget.navigateForward(plan);
    } else {
      setState(() {
        _buttonState = ButtonState.error;
      });
    }
  }

  void _resetErrors() {
    setState(() {
      _nameErrorText = null;
      _unknownErrorText = null;
      _buttonState = ButtonState.normal;
    });
  }
}
