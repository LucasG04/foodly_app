import 'package:flutter/material.dart';

import 'small_circular_progress_indicator.dart';

class FullScreenLoader extends StatefulWidget {
  /// The background color of the loader. Default is black26.
  final Color backgroundColor;

  /// The color of the loader. Default is white.
  final Color loaderColor;

  const FullScreenLoader({
    Key? key,
    this.backgroundColor = Colors.black26,
    this.loaderColor = Colors.white,
  }) : super(key: key);

  @override
  _FullScreenLoaderState createState() => _FullScreenLoaderState();
}

class _FullScreenLoaderState extends State<FullScreenLoader> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: widget.backgroundColor,
        ),
        Center(
          child: SmallCircularProgressIndicator(color: widget.loaderColor),
        ),
      ],
    );
  }
}
