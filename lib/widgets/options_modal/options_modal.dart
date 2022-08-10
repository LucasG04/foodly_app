import 'package:flutter/material.dart';

import '../../constants.dart';
import 'options_modal_option.dart';

class OptionsSheet extends StatelessWidget {
  final List<OptionsSheetOptions> options;
  const OptionsSheet({
    required this.options,
    Key? key,
  })  : assert(options.length != 0),
        super(key: key);

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
