import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

import '../../../constants.dart';
import '../../../models/plan.dart';
import '../../../models/plan_meal.dart';
import '../../../services/lunix_api_service.dart';
import '../../../services/settings_service.dart';
import '../../../utils/analytics.dart';
import '../../../utils/main_snackbar.dart';
import '../../../utils/of_context_mixin.dart';
import '../../../utils/widget_utils.dart';
import '../../../widgets/main_button.dart';
import '../../../widgets/options_modal/options_modal.dart';
import '../../../widgets/options_modal/options_modal_option.dart';
import '../../../widgets/progress_button.dart';
import '../../../widgets/sheet_header.dart';
import '../../settings/settings_tile.dart';

class PlanDownloadModal extends StatefulWidget {
  final Plan plan;

  const PlanDownloadModal({
    super.key,
    required this.plan,
  });

  @override
  State<PlanDownloadModal> createState() => _PlanDownloadModalState();
}

class _PlanDownloadModalState extends State<PlanDownloadModal>
    with OfContextMixin {
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
    final width = mediaSize.width > 599 ? 580.0 : mediaSize.width * 0.8;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (mediaSize.width - width) / 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SheetHeader(
            title: context.tr('plan_download_modal_title'),
            actions: [
              IconButton(
                onPressed: _openDocxInfo,
                icon: Icon(
                  EvaIcons.infoOutline,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
          SettingsTile(
            text: context.tr('plan_download_modal_exclude_today'),
            trailing: Checkbox(
              value: _excludeToday,
              onChanged: _excludeTodayChange,
              activeColor: theme.primaryColor,
            ),
            onTap: () => _excludeTodayChange(!_excludeToday),
          ),
          SettingsTile(
            text: context.tr('plan_download_modal_portrait'),
            trailing: Checkbox(
              value: _portraitFormat,
              onChanged: _portraitFormatChange,
              activeColor: theme.primaryColor,
            ),
            onTap: () => _portraitFormatChange(!_portraitFormat),
          ),
          if (_isBreakfastAvailableForSelectedType())
            SettingsTile(
              text: context.tr('plan_download_modal_breakfast'),
              trailing: Checkbox(
                value: _includeBreakfast,
                onChanged: _includeBreakfastChange,
                activeColor: theme.primaryColor,
              ),
              onTap: () => _includeBreakfastChange(!_includeBreakfast),
            ),
          SettingsTile(
            text: context.tr('plan_download_modal_type'),
            value: context.tr(_getTextForDocType(_docType)),
            onTap: () => WidgetUtils.showFoodlyBottomSheet<void>(
              context: context,
              builder: (_) => OptionsSheet(options: [
                for (final type in _PlanDocType.values)
                  OptionsSheetOptions(
                    title: context.tr(_getTextForDocType(type)),
                    icon: type == _PlanDocType.color
                        ? EvaIcons.colorPaletteOutline
                        : EvaIcons.fileTextOutline,
                    selected: type == _docType,
                    onTap: () => _docTypeChange(type),
                  ),
              ]),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: kPadding,
              bottom: WidgetUtils.sheetBottomPadding(context),
            ),
            child: MainButton(
              text: context.tr('plan_download_modal_cta'),
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

  void _docTypeChange(_PlanDocType value) {
    if (!mounted) {
      return;
    }
    setState(() {
      _docType = value;
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
      message: context.tr('general_error_message'),
      isError: true,
    ).show(context);
    if (!mounted) {
      return;
    }
    setState(() {
      _buttonState = ButtonState.normal;
    });
  }

  Future<dynamic> _openDocxInfo() {
    return MainSnackbar(
      message: context.tr('plan_download_modal_docx_info'),
      infinite: true,
    ).show(context);
  }

  void _logAnalyticsEvent() {
    logEvent(AnalyticsEvent.planDownload, {
      'excludeToday': _excludeToday.toString(),
      'vertical': _portraitFormat.toString(),
      'includeBreakfast': _includeBreakfast.toString(),
      'type': _getValueForDocType(_docType),
    });
  }
}

enum _PlanDocType { color, simple }
