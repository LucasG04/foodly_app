import 'package:easy_localization/src/public_ext.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../models/plan.dart';
import '../../../services/lunix_api_service.dart';
import '../../../widgets/main_button.dart';
import '../../../widgets/progress_button.dart';
import '../settings_view/settings_tile.dart';

class PlanDownloadModal extends StatefulWidget {
  final Plan plan;

  const PlanDownloadModal({Key? key, required this.plan}) : super(key: key);

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
        // crossAxisAlignment: CrossAxisAlignment.start,
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: kPadding),
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
              onTap: () async {
                setState(() {
                  _buttonState = ButtonState.inProgress;
                });
                final path = await LunixApiService.printDocxForPlan(
                  plan: widget.plan,
                  languageTag: context.locale.toLanguageTag(),
                );
                setState(() {
                  _buttonState = ButtonState.normal;
                });
                print(path);
              },
            ),
          ),
        ],
      ),
    );
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
}
