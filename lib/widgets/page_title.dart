import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

class PageTitle extends StatelessWidget {
  final String text;
  final bool autoSize;
  final List<Widget>? actions;

  const PageTitle({
    Key? key,
    required this.text,
    this.autoSize = false,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Center(
        child: SizedBox(
          height: 50.0,
          width: MediaQuery.of(context).size.width > 599
              ? 600.0
              : MediaQuery.of(context).size.width * 0.9,
          child: Row(
            children: [
              _buildTitle(),
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(width: kPadding),
                const Spacer(),
                ...actions!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  AutoSizeText _buildTitle() {
    return AutoSizeText(
      text,
      maxFontSize: 30.0,
      minFontSize: 26.0,
      style: TextStyle(
        fontSize: autoSize ? null : 30.0,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
      ),
    );
  }
}
