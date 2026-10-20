import 'package:flutter/material.dart';

import '../constants.dart';

class CardListTile extends StatelessWidget {
  final double height;
  final double? width;
  final Widget? leading;
  final Widget? content;
  final List<CardListTileAction> actions;

  const CardListTile({
    super.key,
    this.height = 75.0,
    this.width,
    this.leading,
    this.content,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width * 0.9;
    return Container(
      width: width > 599 ? 600 : width,
      margin: const EdgeInsets.symmetric(vertical: kPadding / 2),
      decoration: BoxDecoration(
        boxShadow: const [kSmallShadow],
        borderRadius: BorderRadius.circular(kRadius),
        color: Colors.white,
      ),
      // The text decides the height (at least [height], more for large
      // text); the leading picture fills it.
      child: Stack(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Padding(
              padding: EdgeInsets.only(left: height),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: content,
                    ),
                  ),
                  ...actions.map((e) => _buildActionContainer(e, context)),
                ],
              ),
            ),
          ),
          if (leading != null)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: height,
              child: leading!,
            ),
        ],
      ),
    );
  }

  Widget _buildActionContainer(
    CardListTileAction action,
    BuildContext context,
  ) {
    return Container(
      height: height / 2,
      width: height / 2,
      margin: const EdgeInsets.only(right: 20.0),
      child: OutlinedButton(
        onPressed: action.onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).primaryColor,
          padding: EdgeInsets.zero,
        ),
        child: action.widget,
      ),
    );
  }
}

class CardListTileAction {
  Widget widget;
  Function()? onTap;

  CardListTileAction({
    required this.widget,
    this.onTap,
  });
}
