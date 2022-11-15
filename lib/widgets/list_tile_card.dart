import 'package:flutter/material.dart';

import '../constants.dart';

class ListTileCard extends StatelessWidget {
  final IconData iconData;
  final Color? iconColor;
  final String title;
  final String? description;

  const ListTileCard({
    required this.iconData,
    required this.title,
    this.iconColor,
    this.description,
    Key? key,
  }) : super(key: key);

  TextStyle get _titleStyle => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      width: width > 599 ? 600 : width * 0.9,
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(kPadding / 2),
          child: Row(
            children: [
              Icon(
                iconData,
                color: iconColor ?? Theme.of(context).primaryColor,
              ),
              const SizedBox(width: kPadding / 2),
              Expanded(
                child: description == null || description!.isEmpty
                    ? Text(title, style: _titleStyle)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: _titleStyle),
                          const SizedBox(height: kPadding / 4),
                          Text(description!),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
