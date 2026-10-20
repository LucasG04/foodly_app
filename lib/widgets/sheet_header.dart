import 'package:auto_size_text/auto_size_text.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

/// Standard bottom sheet header: uppercase title on the left, [actions] and a
/// close button on the right. Always one tap target tall, so the spacing below
/// it is the same with or without buttons.
class SheetHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> actions;
  final bool showClose;
  final EdgeInsetsGeometry padding;

  /// Lines the title may take before it is cut off; more than one keeps a
  /// long title readable at large text sizes.
  final int maxLines;

  const SheetHeader({
    required this.title,
    this.icon,
    this.actions = const [],
    this.showClose = true,
    this.padding = const EdgeInsets.only(top: kPadding),
    this.maxLines = 1,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: kPadding / 2),
            ],
            Expanded(
              child: Semantics(
                header: true,
                child: AutoSizeText(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  minFontSize: 16,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            ...actions,
            if (showClose)
              IconButton(
                icon: const Icon(EvaIcons.close),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
          ],
        ),
      ),
    );
  }
}
