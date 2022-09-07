import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

class SuggestionTile extends StatelessWidget {
  final String text;
  final void Function() onTap;

  const SuggestionTile({
    required this.text,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: Theme.of(context).dialogBackgroundColor,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: const [kSmallShadow],
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: kPadding / 2,
            vertical: kPadding / 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4.0),
              const Icon(EvaIcons.plus, size: kIconHeight * 0.65),
            ],
          ),
        ),
      ),
    );
  }
}
