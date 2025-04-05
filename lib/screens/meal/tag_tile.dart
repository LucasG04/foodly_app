import 'package:flutter/material.dart';

import 'border_icon.dart';

class TagTile extends StatelessWidget {
  final String text;

  const TagTile(
    this.text, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 25),
      child: Column(
        // ignore: avoid_redundant_argument_values
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          BorderIcon(
            height: 50.0,
            withBorder: true,
            child: Text(text, style: const TextStyle(fontSize: 16.0)),
          ),
        ],
      ),
    );
  }
}
