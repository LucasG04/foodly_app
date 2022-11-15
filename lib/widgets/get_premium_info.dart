import 'dart:math';

import 'package:flutter/material.dart';

import '../constants.dart';

class GetPremiumInfo extends StatelessWidget {
  final String title;
  final String description;
  final double? width;
  final double displayProbability;

  const GetPremiumInfo({
    required this.title,
    required this.description,
    this.width,
    this.displayProbability = 1.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final showInfo = Random().nextDouble() <= displayProbability;
    return !showInfo
        ? const SizedBox()
        : Container(
            width: width,
            decoration: BoxDecoration(
              color: kGreyBackgroundColor,
              borderRadius: BorderRadius.circular(kRadius),
            ),
            padding: const EdgeInsets.all(kPadding / 2),
            child: Row(
              children: [
                const Text('⭐️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: kPadding / 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: kPadding / 6),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyText1,
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
  }
}
