import 'package:flutter/material.dart';

import '../../constants.dart';

class OptionsSheetOptions extends StatelessWidget {
  final IconData icon;
  final String title;
  final Function() onTap;
  final Color? textColor;

  const OptionsSheetOptions({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        Future<void>.delayed(Duration.zero, onTap);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadius),
          color:
              Theme.of(context).textTheme.bodyText1?.color?.withOpacity(0.06) ??
                  Colors.black.withOpacity(0.06),
        ),
        padding: const EdgeInsets.all(kPadding),
        child: Row(
          children: [
            Icon(
              icon,
              color: textColor ?? Theme.of(context).textTheme.bodyText1?.color,
            ),
            const SizedBox(width: kPadding),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.start,
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
