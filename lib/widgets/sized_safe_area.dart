import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// A [SafeArea] that also makes `MediaQuery.sizeOf(context)` report the width
/// left between the side insets, so layouts that size themselves from the
/// screen width (`width * 0.9`, centering) fit. iPhone Duo keeps the status
/// bar and camera in a column on one side.
class SizedSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;

  /// Like [SafeArea.minimum], e.g. room for a navigation rail.
  final double minLeft;
  final double minRight;

  const SizedSafeArea({
    required this.child,
    this.top = true,
    this.bottom = true,
    this.minLeft = 0,
    this.minRight = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    final left = math.max(data.padding.left, minLeft);
    final right = math.max(data.padding.right, minRight);
    return Padding(
      padding: EdgeInsets.only(left: left, right: right),
      child: MediaQuery(
        data: data.removePadding(removeLeft: true, removeRight: true).copyWith(
          size: Size(data.size.width - left - right, data.size.height),
          displayFeatures: [
            for (final feature in data.displayFeatures)
              DisplayFeature(
                bounds: feature.bounds.shift(Offset(-left, 0)),
                type: feature.type,
                state: feature.state,
              ),
          ],
        ),
        child: SafeArea(top: top, bottom: bottom, child: child),
      ),
    );
  }
}
