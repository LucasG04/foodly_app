import 'package:flutter/material.dart';
import '../constants.dart';

class SkeletonContainer extends StatelessWidget {
  final double height;
  final double width;
  final EdgeInsetsGeometry margin;
  final Color shimmerColor;
  final Color gradientColor;
  final Color backgroundColor;
  final Curve curve;
  final double borderRadius;

  SkeletonContainer({
    @required this.width,
    @required this.height,
    this.margin = const EdgeInsets.all(0),
    this.shimmerColor = Colors.white54,
    this.gradientColor = const Color.fromARGB(0, 244, 244, 244),
    this.backgroundColor,
    this.curve = Curves.fastOutSlowIn,
    this.borderRadius = kRadius,
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
            color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
      ),
    );
  }
}

/// author: Mahen Gandhi <mahen.gandhi@civilmachines.com>
/// github: https://github.com/imlegend19
class _SkeletonAnimation extends StatefulWidget {
  final Widget child;
  final Color shimmerColor;
  final Color gradientColor;
  final Curve curve;

  _SkeletonAnimation(
      {@required this.child,
      this.shimmerColor = Colors.white54,
      this.gradientColor = const Color.fromARGB(0, 244, 244, 244),
      this.curve = Curves.fastOutSlowIn,
      Key key})
      : super(key: key);

  @override
  _SkeletonAnimationState createState() => _SkeletonAnimationState();
}

class _SkeletonAnimationState extends State<_SkeletonAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

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
                  begin: Alignment(-1.0 - .2 * 3, .0),
                  end: Alignment(1.0 + .2 * 3, .0),
                ).chain(CurveTween(curve: widget.curve)).evaluate(_controller),
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
