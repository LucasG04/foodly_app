import 'package:flutter/material.dart';

class SmallCircularProgressIndicator extends StatelessWidget {
  final Color? color;
  final double additionalSize;

  double get _iconHeight => 24.0;

  const SmallCircularProgressIndicator({
    super.key,
    this.color,
    this.additionalSize = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _iconHeight - 5 + additionalSize,
      width: _iconHeight - 5 + additionalSize,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color?>(
          color ?? Theme.of(context).textTheme.bodyLarge!.color,
        ),
      ),
    );
  }
}
