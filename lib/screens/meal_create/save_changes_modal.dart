import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/main_button.dart';
import '../../widgets/sheet_header.dart';

enum SaveChangesResult { discard, save, cancel }

class SaveChangesModal extends StatelessWidget {
  const SaveChangesModal({super.key});

  @override
  Widget build(BuildContext context) {
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
            title: context.tr('save_changes_title'),
            showClose: false,
            padding: const EdgeInsets.only(top: kPadding, bottom: kPadding / 2),
          ),
          Text(context.tr('save_changes_text')),
          const SizedBox(height: kPadding * 2),
          Center(
            child: MainButton(
              text: context.tr('save_changes_confirm'),
              onTap: () => Navigator.pop(context, SaveChangesResult.save),
            ),
          ),
          const SizedBox(height: kPadding),
          Center(
            child: MainButton(
              text: context.tr('save_changes_discard'),
              onTap: () => Navigator.pop(context, SaveChangesResult.discard),
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: kPadding),
          Center(
            child: MainButton(
              text: context.tr('save_changes_cancel'),
              onTap: () => Navigator.pop(context, SaveChangesResult.cancel),
              isSecondary: true,
            ),
          ),
          SizedBox(height: WidgetUtils.sheetBottomPadding(context)),
        ],
      ),
    );
  }
}
