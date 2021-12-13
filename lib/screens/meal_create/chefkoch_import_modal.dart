import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import '../../utils/basic_utils.dart';

import '../../constants.dart';
import '../../services/chefkoch_service.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/progress_button.dart';

class ChefkochImportModal extends StatefulWidget {
  ChefkochImportModal();

  @override
  _ChefkochImportModalState createState() => _ChefkochImportModalState();
}

class _ChefkochImportModalState extends State<ChefkochImportModal> {
  TextEditingController _linkController = new TextEditingController();
  String? _linkErrorText;
  late bool _linkError;

  ButtonState? _buttonState;

  @override
  void initState() {
    _linkController = new TextEditingController();
    _linkErrorText = null;
    _linkError = false;
    _buttonState = ButtonState.normal;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: kPadding),
              child: Text(
                'import_modal_title'.tr().toUpperCase(),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ).tr(),
            ),
          ),
          MainTextField(
            controller: _linkController,
            title: 'import_modal_link_title'.tr(),
            placeholder:
                'https://www.chefkoch.de/rezepte/2280941363879458/Brokkoli-Spaetzle-Pfanne.html',
            errorText: _linkErrorText,
            onSubmit: _importMeal,
          ),
          _linkError
              ? Container(
                  margin: const EdgeInsets.only(top: kPadding),
                  padding: const EdgeInsets.symmetric(
                      horizontal: kPadding, vertical: kPadding / 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(kRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        EvaIcons.alertCircleOutline,
                        color: Theme.of(context).errorColor,
                      ),
                      SizedBox(width: kPadding),
                      Expanded(
                        child: Text('import_modal_error_not_found').tr(),
                      )
                    ],
                  ),
                )
              : SizedBox(),
          SizedBox(
            height: MediaQuery.of(context).viewInsets.bottom == 0
                ? kPadding * 2
                : MediaQuery.of(context).viewInsets.bottom,
          ),
          Center(
            child: MainButton(
              text: 'import_modal_import'.tr(),
              onTap: _importMeal,
              isProgress: true,
              buttonState: _buttonState,
            ),
          ),
          SizedBox(height: kPadding * 2),
        ],
      ),
    );
  }

  void _importMeal() async {
    final String link =
        BasicUtils.getUrlFromString(_linkController.text.trim());

    if (link.isEmpty) {
      setState(() {
        _buttonState = ButtonState.error;
        _linkErrorText = 'import_modal_error_no_link'.tr();
      });
      return;
    }

    setState(() {
      _linkError = false;
      _buttonState = ButtonState.inProgress;
    });

    try {
      final meal = await ChefkochService.getMealFromChefkochUrl(link);
      FocusScope.of(context).unfocus();
      _buttonState = ButtonState.normal;
      Navigator.pop(context, meal);
    } catch (e) {
      print(e);
      setState(() {
        _buttonState = ButtonState.error;
        _linkError = true;
      });
    }
  }
}
