import 'package:flutter/material.dart';
import 'package:foodly/services/chefkoch_service.dart';
import 'package:foodly/widgets/main_button.dart';
import 'package:foodly/widgets/main_text_field.dart';

import '../../constants.dart';

class ChefkochImportModal extends StatefulWidget {
  ChefkochImportModal();

  @override
  _ChefkochImportModalState createState() => _ChefkochImportModalState();
}

class _ChefkochImportModalState extends State<ChefkochImportModal> {
  TextEditingController _linkController = new TextEditingController();
  String _linkErrorText;

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
          ),
          SizedBox(height: kPadding * 2),
          Center(
            child: MainButton(
              text: 'Importieren',
              onTap: _importMeal,
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
        _linkErrorText = 'Bitte trag einen Link ein.';
      });
      return;
    }

    setState(() {
      _linkErrorText = null;
    });

    try {
      final meal = await ChefkochService.getMealFromChefkochUrl(link);
      FocusScope.of(context).unfocus();
      Navigator.pop(context, meal);
    } catch (e) {
      print(e);
      setState(() {
        _linkErrorText =
            'Leider konnte für diesen Link kein Gericht gefunden werden.';
      });
    }
  }
}
