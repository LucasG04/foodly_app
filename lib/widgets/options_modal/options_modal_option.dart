import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';

class OptionsSheetOptions extends StatelessWidget {
  final IconData? icon;
  final String title;
  final Function() onTap;
  final Color? textColor;
  final Widget? trailing;

  /// Marks the current value when the sheet is used as a single-choice
  /// picker: tinted in the primary color with a checkmark.
  final bool selected;

  const OptionsSheetOptions({
    required this.title,
    required this.onTap,
    this.icon,
    this.textColor,
    this.trailing,
    this.selected = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? theme.primaryColor : textColor;
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        Future<void>.delayed(Duration.zero, onTap);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadius),
          color: selected
              ? theme.primaryColor.withValues(alpha: 0.12)
              : theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.06) ??
                  Colors.black.withValues(alpha: 0.06),
        ),
        padding: const EdgeInsets.all(kPadding),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: color ?? theme.textTheme.bodyLarge?.color,
              ),
              const SizedBox(width: kPadding),
            ],
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : null,
                ),
              ),
            ),
            if (trailing != null || selected) ...[
              const SizedBox(width: kPadding),
              trailing ??
                  Icon(EvaIcons.checkmarkCircle2, color: theme.primaryColor),
            ],
          ],
        ),
      ),
    );
  }
}
