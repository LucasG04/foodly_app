import 'dart:math' as math;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/page_data.dart';
import '../utils/basic_utils.dart';

class PageCard extends StatelessWidget {
  final PageData page;
  final double height;

  const PageCard({
    super.key,
    required this.page,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Centered on the screen like the page view's button, narrower when a side
    // inset (iPhone Duo's status bar column) would cut into it.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final padding = MediaQuery.paddingOf(context);
    final halfWidth = screenWidth / 2 - math.max(padding.left, padding.right);
    final width = math.min(
      BasicUtils.contentWidth(context, smallMultiplier: 0.8),
      2 * halfWidth - kPadding,
    );
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: (screenWidth - width) / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: height * 0.5,
            child: Center(child: _buildPicture(context, height * 0.5)),
          ),
          SizedBox(height: height * 0.05),
          _buildTitle(context),
          SizedBox(height: height * 0.025),
          _buildSubtitle(context),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      page.title!,
      style: TextStyle(
        color: page.primaryColor,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
        letterSpacing: 0.0,
        fontSize: 28.0,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return AutoSizeText(
      page.subtitle,
      style: TextStyle(
        color: page.primaryColor,
        fontSize: 20.0,
      ),
    );
  }

  Widget _buildPicture(BuildContext context, double size) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(top: 140),
      child: Image.asset(page.assetPath!),
    );
  }
}
