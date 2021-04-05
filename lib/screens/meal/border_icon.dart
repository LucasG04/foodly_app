import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:foodly/constants.dart';

class BorderIcon extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double width, height;
  final bool withBorder;

  const BorderIcon({
    Key key,
    @required this.child,
    this.width,
    this.height,
    this.padding,
    this.withBorder = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade200.withOpacity(0.5),
            borderRadius: BorderRadius.circular(kRadius * 2),
            border: Border.all(
              color: Colors.black.withAlpha(40),
              width: withBorder ? 2.0 : 0.0,
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
