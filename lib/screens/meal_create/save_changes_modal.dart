import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../widgets/main_button.dart';

enum SaveChangesResult { discard, save, cancel }

class SaveChangesModal extends StatelessWidget {
  const SaveChangesModal({super.key});

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
                'save_changes_title'.tr().toUpperCase(),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Text('save_changes_text'.tr()),
          const SizedBox(height: kPadding * 2),
          Center(
            child: MainButton(
              text: 'save_changes_confirm'.tr(),
              onTap: () => Navigator.pop(context, SaveChangesResult.save),
            ),
          ),
          const SizedBox(height: kPadding),
          Center(
            child: MainButton(
              text: 'save_changes_discard'.tr(),
              onTap: () => Navigator.pop(context, SaveChangesResult.discard),
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: kPadding),
          Center(
            child: MainButton(
              text: 'save_changes_cancel'.tr(),
              onTap: () => Navigator.pop(context, SaveChangesResult.cancel),
              isSecondary: true,
            ),
          ),
          const SizedBox(height: kPadding * 2),
        ],
      ),
    );
  }
}
