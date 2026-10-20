import 'package:flutter/material.dart';

/// Body of a bottom sheet with a text field: stays above the keyboard and
/// scrolls when [children] don't fit (small screens, open keyboard). Content
/// width per AGENTS.md "UI: bottom sheets" (580, or 80 % on phones).
class KeyboardAwareSheet extends StatelessWidget {
  /// Stays in place above the scrolling [children], e.g. the [SheetHeader].
  final Widget? header;
  final List<Widget> children;

  const KeyboardAwareSheet({required this.children, this.header, super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width > 599 ? 580.0 : size.width * 0.8;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final sidePadding = EdgeInsets.symmetric(
      horizontal: (size.width - width) / 2,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: size.height * 0.85 - keyboard,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (header != null) Padding(padding: sidePadding, child: header),
            Flexible(
              child: SingleChildScrollView(
                padding: sidePadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
