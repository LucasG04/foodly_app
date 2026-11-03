import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../constants.dart';

/// Bottom bar for the library's floating main button (list and recipe page):
/// no background, the content scrolls behind it (`Scaffold.extendBody`).
/// Sits close to the home indicator instead of a full safe-area inset above it.
class LibraryActionBar extends StatelessWidget {
  final Widget child;

  const LibraryActionBar({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        padding.left + kPadding,
        kPadding / 2,
        padding.right + kPadding,
        math.max(kPadding / 2, padding.bottom - kPadding / 2),
      ),
      child: child,
    );
  }
}
