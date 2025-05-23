import 'dart:math' as math;

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

/// FROM: https://pub.dev/packages/animate_icons
class AnimateIcons extends StatefulWidget {
  const AnimateIcons(
      {

      /// The IconData that will be visible before animation Starts
      required this.startIcon,

      /// The IconData that will be visible after animation ends
      required this.endIcon,

      /// On icon tap.
      this.onTap,

      /// The size of the icon that are to be shown.
      this.size = 24.0,

      /// AnimateIcons controller
      this.controller,

      /// The color of the icons that are to be shown
      this.color,

      /// The duration for which the animation runs
      this.duration = const Duration(milliseconds: 300),

      /// If the animation runs in the clockwise or anticlockwise direction
      this.clockwise = false,

      /// This is the tooltip that will be used for the [startIcon]
      this.startTooltip = '',

      /// This is the tooltip that will be used for the [endIcon]
      this.endTooltip = '',
      super.key});
  final IconData? startIcon, endIcon;
  final Duration duration;
  final bool clockwise;
  final double size;
  final Color? color;
  final AnimateIconController? controller;
  final String startTooltip, endTooltip;
  final void Function()? onTap;

  @override
  State<AnimateIcons> createState() => _AnimateIconsState();
}

class _AnimateIconsState extends State<AnimateIcons>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    initControllerFunctions();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void initControllerFunctions() {
    if (widget.controller != null) {
      widget.controller!.animateToEnd = () {
        _controller.forward();
        return true;
      };
      widget.controller!.animateToStart = () {
        _controller.reverse();
        return true;
      };
      widget.controller!.isStart = () => _controller.value == 0.0;
      widget.controller!.isEnd = () => _controller.value == 1.0;
    }
  }

  // _onStartIconPress() {
  //   if (widget.onStartIconPress()) _controller.forward();
  // }

  // _onEndIconPress() {
  //   if (widget.onEndIconPress()) _controller.reverse();
  // }

  @override
  Widget build(BuildContext context) {
    final double x = _controller.value;
    final double y = 1.0 - _controller.value;
    final double angleX = math.pi / 180 * (180 * x);
    final double angleY = math.pi / 180 * (180 * y);

    Widget first() {
      return Transform.rotate(
        angle: (widget.clockwise) ? angleX : -angleX,
        child: Opacity(
          opacity: y,
          child: Icon(
            widget.startIcon ?? EvaIcons.close,
            size: widget.size,
            color: widget.startIcon != null ? widget.color : Colors.transparent,
          ),
        ),
      );
    }

    Widget second() {
      return Transform.rotate(
        angle: (widget.clockwise) ? -angleY : angleY,
        child: Opacity(
          opacity: x,
          child: Icon(
            widget.endIcon ?? EvaIcons.close,
            size: widget.size,
            color: widget.endIcon != null ? widget.color : Colors.transparent,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (x == 1 && y == 0) second() else first(),
          if (x == 0 && y == 1) first() else second(),
        ],
      ),
    );
  }
}

class AnimateIconController {
  bool Function()? animateToStart, animateToEnd;
  bool Function()? isStart, isEnd;
}
