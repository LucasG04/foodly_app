import 'package:flutter/material.dart';

import '../../constants.dart';

class OptionsSheet extends StatelessWidget {
  final List<Widget> options;
  const OptionsSheet({
    required this.options,
    super.key,
  })  : assert(options.length != 0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kPadding),
      child: Wrap(
        spacing: kPadding,
        runSpacing: kPadding,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: options,
      ),
    );
  }
}
