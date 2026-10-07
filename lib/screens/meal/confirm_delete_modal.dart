import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/meal.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/main_button.dart';
import '../../widgets/sheet_header.dart';

class ConfirmDeleteModal extends StatelessWidget {
  final Meal meal;

  const ConfirmDeleteModal(this.meal, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final width = screenWidth > 599 ? 580.0 : screenWidth * 0.8;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (screenWidth - width) / 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SheetHeader(
            title: context.tr('delete'),
            padding: const EdgeInsets.only(top: kPadding, bottom: kPadding / 2),
          ),
          RichText(
            text: TextSpan(
              style: theme.textTheme.bodyLarge!.copyWith(
                fontSize: 16.0,
              ),
              children: <TextSpan>[
                TextSpan(text: '${context.tr('modal_delete_sure_leading')} '),
                TextSpan(
                  text: '"${meal.name}"',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: ' ${context.tr('modal_delete_sure_trailing')}',
                ),
              ],
            ),
          ),
          const SizedBox(height: kPadding * 2),
          Center(
            child: MainButton(
              text: context.tr('modal_delete_delete'),
              onTap: () => Navigator.pop(context, true),
              color: theme.colorScheme.error,
            ),
          ),
          SizedBox(height: WidgetUtils.sheetBottomPadding(context)),
        ],
      ),
    );
  }
}
