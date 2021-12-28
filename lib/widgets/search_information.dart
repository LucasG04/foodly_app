import 'package:flutter/material.dart';

import '../constants.dart';

class SearchInformation extends StatelessWidget {
  final String _assetPath;
  final String _title;
  final String _message;

  const SearchInformation(this._assetPath, this._title, this._message);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(size.width * 0.1),
          child: Image.asset(
            _assetPath,
            height: size.height * 0.2,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(kPadding),
          child: Text(
            _title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            kPadding,
            0,
            kPadding,
            kPadding,
          ),
          child: Text(
            _message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
