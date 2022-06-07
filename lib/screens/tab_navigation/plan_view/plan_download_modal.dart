import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

import '../../../constants.dart';
import '../../../models/plan.dart';
import '../../../services/lunix_api_service.dart';
import '../../../utils/main_snackbar.dart';
import '../../../widgets/main_button.dart';
import '../../../widgets/progress_button.dart';
import '../settings_view/settings_tile.dart';

class PlanDownloadModal extends StatefulWidget {
  final Plan plan;

  const PlanDownloadModal({
    Key? key,
    required this.plan,
  }) : super(key: key);

  @override
  State<PlanDownloadModal> createState() => _PlanDownloadModalState();
}

class _PlanDownloadModalState extends State<PlanDownloadModal> {
  bool _excludeToday = false;
  bool _portraitFormat = false;
  ButtonState _buttonState = ButtonState.normal;

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
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: kPadding),
              child: Text(
                'plan_download_modal_title'.tr().toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Flexible(
            child: Image.asset(
              'assets/images/template-plan-${_portraitFormat ? 'vertical' : 'horizontal'}-color.png',
            ),
          ),
          SettingsTile(
            text: 'plan_download_modal_exclude_today'.tr(),
            trailing: Checkbox(
              value: _excludeToday,
              onChanged: _excludeTodayChange,
            ),
            onTap: () => _excludeTodayChange(!_excludeToday),
          ),
          SettingsTile(
            text: 'plan_download_modal_portrait'.tr(),
            trailing: Checkbox(
              value: _portraitFormat,
              onChanged: _portraitFormatChange,
            ),
            onTap: () => _portraitFormatChange(!_portraitFormat),
          ),
          Padding(
            padding: const EdgeInsets.only(top: kPadding, bottom: kPadding * 2),
            child: MainButton(
              text: 'plan_download_modal_cta'.tr(),
              isProgress: true,
              buttonState: _buttonState,
              onTap: _handleDownload,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDownload() async {
    setState(() {
      _buttonState = ButtonState.inProgress;
    });
    final path = await LunixApiService.saveDocxForPlan(
      plan: widget.plan,
      languageTag: context.locale.toLanguageTag(),
      excludeToday: _excludeToday,
      vertical: _portraitFormat,
    );
    setState(() {
      _buttonState = ButtonState.normal;
    });
    await _savePlanPdf(path);
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  void _excludeTodayChange(bool? value) {
    setState(() {
      _excludeToday = value ?? false;
    });
  }

  void _portraitFormatChange(bool? value) {
    setState(() {
      _portraitFormat = value ?? false;
    });
  }

  Future<void> _savePlanPdf(String? path) async {
    if (path == null || path.isEmpty) {
      _handleException();
      return;
    }

    final params = SaveFileDialogParams(sourceFilePath: path);
    await FlutterFileDialog.saveFile(params: params);
  }

  void _handleException() async {
    setState(() {
      _buttonState = ButtonState.error;
    });
    await MainSnackbar(
      message: 'general_error_message'.tr(),
      isError: true,
    ).show(context);
    setState(() {
      _buttonState = ButtonState.normal;
    });
  }
}
