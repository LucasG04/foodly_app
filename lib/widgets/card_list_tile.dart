import 'package:flutter/material.dart';

import '../constants.dart';

class CardListTile extends StatelessWidget {
  final double height;
  final double? width;
  final Widget? leading;
  final Widget? content;
  final Widget? trailing;
  final void Function()? trailingAction;

  const CardListTile({
    Key? key,
    this.height = 75.0,
    this.width,
    this.leading,
    this.content,
    this.trailing,
    this.trailingAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double _width = MediaQuery.of(context).size.width * 0.9;
    return Container(
      width: _width > 599 ? 600 : _width,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: kPadding / 2),
      decoration: BoxDecoration(
        boxShadow: [kSmallShadow],
        borderRadius: BorderRadius.circular(kRadius),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            height: height,
            width: height,
            child: leading,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: content,
            ),
          ),
          Container(
            height: height / 2,
            width: height / 2,
            margin: const EdgeInsets.only(right: 20.0),
            child: OutlinedButton(
              onPressed: trailingAction,
              child: trailing!,
              style: ButtonStyle(
                padding: MaterialStateProperty.resolveWith(
                  (states) => const EdgeInsets.all(0),
                ),
                foregroundColor: MaterialStateProperty.resolveWith(
                  (states) => Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
