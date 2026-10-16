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
    final inset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        kPadding,
        kPadding / 2,
        kPadding,
        math.max(kPadding / 2, inset - kPadding / 2),
      ),
      child: child,
    );
  }
}
