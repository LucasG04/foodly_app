import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';

import '../constants.dart';

class SmallNumberInput extends StatelessWidget {
  final int value;
  final Function(int) onChanged;
  final int minValue;
  final int maxValue;

  const SmallNumberInput({
    required this.value,
    required this.onChanged,
    this.minValue = 0,
    this.maxValue = 99,
    super.key,
  });

  int get _effectiveValue => value.clamp(minValue, maxValue);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(EvaIcons.minusCircleOutline),
          onPressed: _decrease,
          padding: EdgeInsets.zero,
          splashRadius: kPadding,
        ),
        SizedBox(
          width: kPadding * 1.5,
          child: _buildText(context, _effectiveValue),
        ),
        IconButton(
          icon: const Icon(EvaIcons.plusCircleOutline),
          onPressed: _increase,
          padding: EdgeInsets.zero,
          splashRadius: kPadding,
        ),
      ],
    );
  }

  Widget _buildText(BuildContext context, int value) {
    return Text(
      '$value',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: Theme.of(context).textTheme.bodyLarge!.fontSize! + 2,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _decrease() {
    if (_effectiveValue <= minValue) {
      return;
    }
    onChanged(_effectiveValue - 1);
  }

  void _increase() {
    if (_effectiveValue >= maxValue) {
      return;
    }
    onChanged(_effectiveValue + 1);
  }
}
