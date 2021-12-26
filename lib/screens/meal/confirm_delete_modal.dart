import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/meal.dart';
import '../../widgets/main_button.dart';

class ConfirmDeleteModal extends StatelessWidget {
  final Meal meal;

  const ConfirmDeleteModal(this.meal);

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
                'delete'.tr().toUpperCase(),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyText1!.copyWith(
                    fontSize: 16.0,
                  ),
              children: <TextSpan>[
                TextSpan(text: '${'modal_delete_sure_leading'.tr()} '),
                TextSpan(
                  text: '"${meal.name}"',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: ' ${'modal_delete_sure_trailing'.tr()}',
                ),
              ],
            ),
          ),
          const SizedBox(height: kPadding * 2),
          Center(
            child: MainButton(
              text: 'modal_delete_delete'.tr(),
              onTap: () => Navigator.pop(context, true),
              color: Theme.of(context).errorColor,
            ),
          ),
          const SizedBox(height: kPadding * 2),
        ],
      ),
    );
  }
}
