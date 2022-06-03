import 'package:flutter/material.dart';

import '../constants.dart';
import '../utils/basic_utils.dart';

class UserInformation extends StatelessWidget {
  final String assetPath;
  final String? title;
  final String? message;

  const UserInformation({
    required this.assetPath,
    this.title,
    this.message,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox(
      width: BasicUtils.contentWidth(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(size.width * 0.1),
            child: Image.asset(
              assetPath,
              height: size.height * 0.2,
            ),
          ),
          if (title != null && title!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(kPadding),
              child: Text(
                title!,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          if (message != null && message!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kPadding,
                0,
                kPadding,
                kPadding,
              ),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
