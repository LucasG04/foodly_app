import 'package:flutter/material.dart';

class MealTag extends StatelessWidget {
  const MealTag(this.tag, {Key? key}) : super(key: key);

  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
      margin: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 4.0),
      decoration: BoxDecoration(
        color:
            Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.12) ??
                Colors.black12,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Text(
        tag,
        style: const TextStyle(fontSize: 12.0),
      ),
    );
  }

  static double get tagHeight => 30.0;
}
