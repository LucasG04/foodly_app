import 'package:auto_route/auto_route.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

class PageTitle extends StatelessWidget {
  final String text;
  final List<Widget> actions;

  const PageTitle({
    Key key,
    @required this.text,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Center(
        child: Container(
          height: 50.0,
          width: MediaQuery.of(context).size.width > 599
              ? 600
              : MediaQuery.of(context).size.width * 0.9,
          child: Row(
            children: [
              _buildTitle(),
              if (actions != null && actions.isNotEmpty) ...[
                SizedBox(width: kPadding),
                Spacer(),
                ...actions,
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
      style: TextStyle(
        fontSize: 30.0,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
      ),
    );
  }
}
