import 'dart:math';

import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../utils/widget_utils.dart';
import 'get_premium_modal.dart';

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
        : InkWell(
            onTap: () => _openGetPremium(context),
            child: Container(
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
                  ),
                  const Icon(EvaIcons.arrowIosForwardOutline),
                ],
              ),
            ),
          );
  }

  void _openGetPremium(BuildContext context) {
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => const GetPremiumModal(),
    );
  }
}
