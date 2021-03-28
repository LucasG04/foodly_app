import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

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
  String _linkErrorText;
  bool _linkError;

  ButtonState _buttonState;

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
                'CHEFKOCH-IMPORT',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          MainTextField(
            controller: _linkController,
            title: 'Link von Chefkoch',
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
                        child: Text(
                          'Leider konnte für diesen Link kein Gericht auf Chefkoch gefunden werden.',
                        ),
                      )
                    ],
                  ),
                )
              : SizedBox(),
          SizedBox(height: kPadding * 2),
          Center(
            child: MainButton(
              text: 'Importieren',
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
    final String link = _linkController.text.trim();

    if (link.isEmpty) {
      setState(() {
        _buttonState = ButtonState.error;
        _linkErrorText = 'Bitte füg einen Link ein.';
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
