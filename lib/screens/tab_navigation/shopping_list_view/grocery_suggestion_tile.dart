import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../models/grocery.dart';

class GrocerySuggestionTile extends StatelessWidget {
  final Grocery grocery;
  final void Function() onTap;

  const GrocerySuggestionTile({
    required this.grocery,
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
                  grocery.name.toString(),
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
