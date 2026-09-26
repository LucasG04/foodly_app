import 'package:flutter/material.dart';

/// A fixed [header] above a scrollable [body]. Shows a shadow below the
/// header once the body is scrolled. The shadow is painted on top of the body
/// so opaque content (e.g. cards) doesn't cover it.
class ScrollShadowLayout extends StatefulWidget {
  final Widget header;
  final Widget body;

  const ScrollShadowLayout({
    required this.header,
    required this.body,
    super.key,
  });

  @override
  State<ScrollShadowLayout> createState() => _ScrollShadowLayoutState();
}

class _ScrollShadowLayoutState extends State<ScrollShadowLayout> {
  bool _showShadow = false;

  @override
  Widget build(BuildContext context) {
    final shadowColor = Theme.of(context).primaryColor;
    return Column(
      children: [
        widget.header,
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: _handleScroll,
                child: widget.body,
              ),
              if (_showShadow)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 2,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            shadowColor.withValues(alpha: 0.16),
                            shadowColor.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _handleScroll(ScrollNotification notification) {
    if (notification.depth == 0 &&
        notification.metrics.axis == Axis.vertical) {
      final showShadow =
          notification.metrics.pixels > notification.metrics.minScrollExtent;
      if (showShadow != _showShadow) {
        setState(() => _showShadow = showShadow);
      }
    }
    return false;
  }
}
