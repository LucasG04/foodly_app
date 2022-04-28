import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';

class SettingsTile extends StatelessWidget {
  final String text;
  final IconData? leadingIcon;
  final Widget? trailing;
  final void Function()? onTap;
  final Color? color;

  const SettingsTile({
    required this.text,
    this.leadingIcon,
    this.trailing,
    this.onTap,
    this.color,
    Key? key,
  }) : super(key: key);

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
            if (leadingIcon != null)
              Icon(leadingIcon, color: _color)
            else
              const SizedBox(),
            const SizedBox(width: kPadding),
            Expanded(
              child: AutoSizeText(
                text,
                style: TextStyle(color: _color),
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
