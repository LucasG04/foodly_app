import 'package:flutter/material.dart';

class PageData {
  final String title;
  final String subtitle;
  final String assetPath;
  final Color primaryColor;
  final Color background;

  PageData({
    this.title,
    this.subtitle = '',
    this.assetPath,
    this.primaryColor = Colors.white,
    this.background = Colors.black,
  });
}
