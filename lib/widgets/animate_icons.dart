import 'dart:math' as math;

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

/// FROM: https://pub.dev/packages/animate_icons
class AnimateIcons extends StatefulWidget {
  const AnimateIcons({
    /// The IconData that will be visible before animation Starts
    @required this.startIcon,

    /// The IconData that will be visible after animation ends
    @required this.endIcon,

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
  });
  final IconData startIcon, endIcon;
  final Duration duration;
  final bool clockwise;
  final double size;
  final Color color;
  final AnimateIconController controller;
  final String startTooltip, endTooltip;
  final void Function() onTap;

  @override
  _AnimateIconsState createState() => _AnimateIconsState();
}

class _AnimateIconsState extends State<AnimateIcons>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    this._controller = new AnimationController(
      vsync: this,
      duration: widget.duration,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    this._controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    initControllerFunctions();
    super.initState();
  }

  @override
  void dispose() {
    this._controller.dispose();
    super.dispose();
  }

  initControllerFunctions() {
    if (widget.controller != null) {
      widget.controller.animateToEnd = () {
        _controller.forward();
        return true;
      };
      widget.controller.animateToStart = () {
        _controller.reverse();
        return true;
      };
      widget.controller.isStart = () => _controller.value == 0.0;
      widget.controller.isEnd = () => _controller.value == 1.0;
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
    double x = _controller.value ?? 0.0;
    double y = 1.0 - _controller.value ?? 0.0;
    double angleX = math.pi / 180 * (180 * x);
    double angleY = math.pi / 180 * (180 * y);

    Widget first() {
      return Transform.rotate(
        angle: (widget.clockwise ?? false) ? angleX : -angleX,
        child: Opacity(
          opacity: y,
          child: Icon(
            widget.startIcon != null ? widget.startIcon : EvaIcons.closeOutline,
            size: widget.size,
            color: widget.startIcon != null ? widget.color : Colors.transparent,
          ),
        ),
      );
    }

    Widget second() {
      return Transform.rotate(
        angle: (widget.clockwise ?? false) ? -angleY : angleY,
        child: Opacity(
          opacity: x ?? 0.0,
          child: Icon(
            widget.endIcon != null ? widget.endIcon : EvaIcons.closeOutline,
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
          x == 1 && y == 0 ? second() : first(),
          x == 0 && y == 1 ? first() : second(),
        ],
      ),
    );
  }
}

class AnimateIconController {
  bool Function() animateToStart, animateToEnd;
  bool Function() isStart, isEnd;
}
