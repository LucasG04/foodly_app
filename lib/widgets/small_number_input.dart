import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import 'disposable_widget.dart';

class SmallNumberInput extends ConsumerStatefulWidget {
  final int initialValue;
  final Function(int) onChanged;
  final int minValue;
  final int maxValue;

  const SmallNumberInput({
    required this.initialValue,
    required this.onChanged,
    this.minValue = 0,
    this.maxValue = 99,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<SmallNumberInput> createState() => _SmallNumberInputState();
}

class _SmallNumberInputState extends ConsumerState<SmallNumberInput>
    with DisposableWidget {
  late AutoDisposeStateProvider<int> _$currentValue;

  @override
  void initState() {
    _$currentValue = AutoDisposeStateProvider((ref) => widget.initialValue);
    ref
        .read(_$currentValue.notifier)
        .stream
        .listen((int next) => widget.onChanged(next))
        .canceledBy(this);
    super.initState();
  }

  @override
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }

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
          child: Consumer(builder: (context, ref, _) {
            return Text(
              '${ref.watch(_$currentValue)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.bodyText1!.fontSize! + 2,
                fontWeight: FontWeight.bold,
              ),
            );
          }),
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

  void _decrease() {
    if (ref.read(_$currentValue) <= widget.minValue) {
      return;
    }
    ref.read(_$currentValue.notifier).state--;
  }

  void _increase() {
    if (ref.read(_$currentValue) >= widget.maxValue) {
      return;
    }
    ref.read(_$currentValue.notifier).state++;
  }
}
