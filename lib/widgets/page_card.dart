import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../models/page_data.dart';
import '../utils/basic_utils.dart';

class PageCard extends StatelessWidget {
  final PageData page;
  final double height;

  const PageCard({
    Key? key,
    required this.page,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: (MediaQuery.of(context).size.width -
                BasicUtils.contentWidth(context, smallMultiplier: 0.8)) /
            2,
      ),
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
