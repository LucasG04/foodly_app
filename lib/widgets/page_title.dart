import 'package:auto_route/auto_route.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

class PageTitle extends StatelessWidget {
  final String text;
  final bool showBackButton;
  final List<Widget> actions;

  const PageTitle({
    Key key,
    @required this.text,
    this.showBackButton = false,
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
              if (showBackButton) ...[
                IconButton(
                  icon: Icon(EvaIcons.arrowBackOutline),
                  onPressed: _navigateBack,
                  splashRadius: 25.0,
                ),
                SizedBox(width: kPadding),
              ],
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

  void _navigateBack() {
    ExtendedNavigator.root.maybePop();
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
