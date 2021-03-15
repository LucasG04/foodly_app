import 'package:flutter/material.dart';
import 'package:foodly/models/meal.dart';

import '../../constants.dart';
import '../../widgets/main_button.dart';

class ConfirmDeleteModal extends StatelessWidget {
  final Meal meal;

  ConfirmDeleteModal(this.meal);

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
                'LÖSCHEN',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyText1.copyWith(
                    fontSize: 16.0,
                  ),
              children: <TextSpan>[
                TextSpan(text: 'Bist du dir sicher, dass du das Gericht '),
                TextSpan(
                  text: '"${meal.name}"',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      ' für immer löschen möchtest. Es kann nicht wiederhergestellt noch von jemanden aufgerufen werden.',
                ),
              ],
            ),
          ),
          SizedBox(height: kPadding * 2),
          Center(
            child: MainButton(
              text: 'Permanent löschen',
              onTap: () => Navigator.pop(context, true),
              color: Theme.of(context).errorColor,
            ),
          ),
          SizedBox(height: kPadding * 2),
        ],
      ),
    );
  }
}
