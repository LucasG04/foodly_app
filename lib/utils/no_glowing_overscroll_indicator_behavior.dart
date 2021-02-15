import 'package:flutter/material.dart';

class NoGlowingOverscrollIndicatorBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}
