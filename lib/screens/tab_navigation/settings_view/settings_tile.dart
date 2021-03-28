import 'package:flutter/material.dart';

import '../../../constants.dart';

class SettingsTile extends StatelessWidget {
  final IconData leadingIcon;
  final String text;
  final Widget trailing;
  final void Function() onTap;
  final Color color;

  SettingsTile({
    @required this.leadingIcon,
    @required this.text,
    this.trailing,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    Color _color = color ?? Theme.of(context).textTheme.bodyText1.color;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.only(bottom: kPadding / 2),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(kRadius)),
        child: Row(
          children: [
            Icon(leadingIcon, color: _color),
            SizedBox(width: kPadding),
            Text(text, style: TextStyle(color: _color)),
            Spacer(),
            trailing ?? Container(),
          ],
        ),
      ),
    );
  }
}
