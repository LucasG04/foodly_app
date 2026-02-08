import 'package:flutter/material.dart';

import '../constants.dart';

class SkeletonContainer extends StatelessWidget {
  final double? height;
  final double width;
  final EdgeInsetsGeometry margin;
  final Color shimmerColor;
  final Color gradientColor;
  final Color? backgroundColor;
  final Curve curve;
  final double borderRadius;

  const SkeletonContainer({
    required this.width,
    required this.height,
    this.margin = EdgeInsets.zero,
    this.shimmerColor = Colors.white54,
    this.gradientColor = const Color.fromARGB(0, 244, 244, 244),
    this.backgroundColor,
    this.curve = Curves.fastOutSlowIn,
    this.borderRadius = kRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: _SkeletonAnimation(
        shimmerColor: shimmerColor,
        gradientColor: gradientColor,
        curve: curve,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: backgroundColor ?? Colors.black12,
          ),
        ),
      ),
    );
  }
}

/// author: https://github.com/imlegend19
class _SkeletonAnimation extends StatefulWidget {
  final Widget child;
  final Color shimmerColor;
  final Color gradientColor;
  final Curve curve;

  const _SkeletonAnimation(
      {required this.child,
      this.shimmerColor = Colors.white54,
      this.gradientColor = const Color.fromARGB(0, 244, 244, 244),
      this.curve = Curves.fastOutSlowIn});

  @override
  _SkeletonAnimationState createState() => _SkeletonAnimationState();
}

class _SkeletonAnimationState extends State<_SkeletonAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.child,
        Positioned.fill(
            child: ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FractionallySizedBox(
                widthFactor: .2,
                alignment: AlignmentGeometryTween(
                  begin: const Alignment(-1.0 - .2 * 3, .0),
                  end: const Alignment(1.0 + .2 * 3, .0),
                ).chain(CurveTween(curve: widget.curve)).evaluate(_controller)!,
                child: child,
              );
            },
            child: DecoratedBox(
                decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                widget.gradientColor,
                widget.shimmerColor,
              ]),
            )),
          ),
        ))
      ],
    );
  }
}
