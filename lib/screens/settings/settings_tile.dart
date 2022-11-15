import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';

class SettingsTile extends StatelessWidget {
  final String text;
  final IconData? leadingIcon;
  final Widget? trailing;
  final void Function()? onTap;
  final Color? colorIcon;
  final Color? colorText;

  const SettingsTile({
    required this.text,
    this.leadingIcon,
    this.trailing,
    this.onTap,
    this.colorIcon,
    this.colorText,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color? textColor =
        colorText ?? Theme.of(context).textTheme.bodyText1!.color;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.only(bottom: kPadding / 2),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(kRadius)),
        child: Row(
          children: [
            if (leadingIcon != null)
              Icon(leadingIcon, color: colorIcon)
            else
              const SizedBox(),
            const SizedBox(width: kPadding),
            Expanded(
              child: AutoSizeText(
                text,
                style: TextStyle(color: textColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing ?? const SizedBox(),
          ],
        ),
      ),
    );
  }
}
