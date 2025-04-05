import 'package:flutter/material.dart';

import '../../constants.dart';

class BorderIcon extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? width, height;
  final bool withBorder;

  const BorderIcon({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.withBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(kRadius * 2),
      // Known issue: https://github.com/flutter/flutter/issues/132735
      // child: BackdropFilter(
      //   filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
      //   child:
      // ),
      child: Container(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade200.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(kRadius * 2),
          border: Border.all(
            color: Colors.black.withAlpha(40),
            width: withBorder ? 2.0 : 0.0,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}
