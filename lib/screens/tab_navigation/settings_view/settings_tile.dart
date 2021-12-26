import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';

class SettingsTile extends StatelessWidget {
  final IconData leadingIcon;
  final String text;
  final Widget? trailing;
  final void Function()? onTap;
  final Color? color;

  const SettingsTile({
    required this.leadingIcon,
    required this.text,
    this.trailing,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Color? _color = color ?? Theme.of(context).textTheme.bodyText1!.color;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.only(bottom: kPadding / 2),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(kRadius)),
        child: Row(
          children: [
            Icon(leadingIcon, color: _color),
            const SizedBox(width: kPadding),
            Expanded(
              child: AutoSizeText(
                text,
                style: TextStyle(color: _color),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing ?? Container(),
          ],
        ),
      ),
    );
  }
}
