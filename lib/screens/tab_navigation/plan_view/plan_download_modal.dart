import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

import '../../../constants.dart';
import '../../../models/plan.dart';
import '../../../models/plan_meal.dart';
import '../../../services/lunix_api_service.dart';
import '../../../services/settings_service.dart';
import '../../../utils/main_snackbar.dart';
import '../../../widgets/main_button.dart';
import '../../../widgets/progress_button.dart';
import '../../settings/settings_tile.dart';

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
  ButtonState _buttonState = ButtonState.normal;
  bool _excludeToday = false;
  bool _portraitFormat = false;
  late bool _includeBreakfast;
  _PlanDocType _docType = _PlanDocType.color;

  @override
  void initState() {
    _includeBreakfast = _initialIncludeBreakfast();
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
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: kPadding / 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'plan_download_modal_title'.tr().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _openDocxInfo,
                  icon: Icon(
                    EvaIcons.infoOutline,
                    color: Theme.of(context).primaryColor,
                  ),
                  splashRadius: 25.0,
                ),
              ],
            ),
          ),
          SettingsTile(
            text: 'plan_download_modal_exclude_today'.tr(),
            trailing: Checkbox(
              value: _excludeToday,
              onChanged: _excludeTodayChange,
              activeColor: Theme.of(context).primaryColor,
            ),
            onTap: () => _excludeTodayChange(!_excludeToday),
          ),
          SettingsTile(
            text: 'plan_download_modal_portrait'.tr(),
            trailing: Checkbox(
              value: _portraitFormat,
              onChanged: _portraitFormatChange,
              activeColor: Theme.of(context).primaryColor,
            ),
            onTap: () => _portraitFormatChange(!_portraitFormat),
          ),
          if (_isBreakfastAvailableForSelectedType())
            SettingsTile(
              text: 'plan_download_modal_breakfast'.tr(),
              trailing: Checkbox(
                value: _includeBreakfast,
                onChanged: _includeBreakfastChange,
                activeColor: Theme.of(context).primaryColor,
              ),
              onTap: () => _includeBreakfastChange(!_includeBreakfast),
            ),
          SettingsTile(
            text: 'plan_download_modal_type'.tr(),
            trailing: DropdownButton<_PlanDocType>(
              value: _docType,
              dropdownColor: Theme.of(context).scaffoldBackgroundColor,
              items: _PlanDocType.values
                  .map((type) => DropdownMenuItem<_PlanDocType>(
                        value: type,
                        child: Text(_getTextForDocType(type)).tr(),
                      ))
                  .toList(),
              onChanged: _docTypeChange,
            ),
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
    _logAnalyticsEvent();
    setState(() {
      _buttonState = ButtonState.inProgress;
    });
    final path = await LunixApiService.saveDocxForPlan(
      plan: widget.plan,
      languageTag: context.locale.toLanguageTag(),
      excludeToday: _excludeToday,
      vertical: _portraitFormat,
      includeBreakfast: _includeBreakfast,
      type: _getValueForDocType(_docType),
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _buttonState = ButtonState.normal;
    });
    await _savePlanPdf(path);
    if (!mounted) {
      return;
    }
    Navigator.maybePop(context);
  }

  bool _initialIncludeBreakfast() {
    final settingActive =
        SettingsService.activeMealTypes.contains(MealType.BREAKFAST);
    final breakfastInPlan =
        widget.plan.meals?.any((e) => e.type == MealType.BREAKFAST) ?? false;

    return settingActive || breakfastInPlan;
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

  void _includeBreakfastChange(bool? value) {
    setState(() {
      _includeBreakfast = value ?? false;
    });
  }

  void _docTypeChange(_PlanDocType? value) {
    setState(() {
      _docType = value ?? _PlanDocType.color;
    });
  }

  String _getTextForDocType(_PlanDocType type) {
    switch (type) {
      case _PlanDocType.color:
        return 'plan_download_modal_type_color';
      case _PlanDocType.simple:
        return 'plan_download_modal_type_simple';
    }
  }

  String _getValueForDocType(_PlanDocType type) {
    switch (type) {
      case _PlanDocType.color:
        return 'color';
      case _PlanDocType.simple:
        return 'simple';
    }
  }

  bool _isBreakfastAvailableForSelectedType() {
    return [_PlanDocType.simple].contains(_docType);
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

  Future<dynamic> _openDocxInfo() {
    return MainSnackbar(
      message: 'plan_download_modal_docx_info'.tr(),
      infinite: true,
    ).show(context);
  }

  void _logAnalyticsEvent() {
    FirebaseAnalytics.instance.logEvent(
      name: 'plan_download',
      parameters: {
        'excludeToday': _excludeToday.toString(),
        'vertical': _portraitFormat.toString(),
        'includeBreakfast': _includeBreakfast.toString(),
        'type': _getValueForDocType(_docType),
      },
    );
  }
}

enum _PlanDocType { color, simple }
