import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';
import '../providers/state_providers.dart';

class PageTitle extends StatelessWidget {
  final String text;
  final bool autoSize;
  final List<Widget>? actions;
  final bool checkConnectivity;

  const PageTitle({
    super.key,
    required this.text,
    this.autoSize = false,
    this.actions,
    this.checkConnectivity = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Center(
        child: SizedBox(
          height: 50.0,
          width: MediaQuery.of(context).size.width > 599
              ? 600.0
              : MediaQuery.of(context).size.width * 0.9,
          child: Row(
            children: [
              _buildTitle(),
              if (checkConnectivity) ...[
                const SizedBox(width: kPadding / 2),
                _buildConnectivityIndicator(context),
              ],
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(width: kPadding),
                const Spacer(),
                ...actions!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  AutoSizeText _buildTitle() {
    return AutoSizeText(
      text,
      maxFontSize: 30.0,
      minFontSize: 26.0,
      style: TextStyle(
        fontSize: autoSize ? null : 30.0,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildConnectivityIndicator(BuildContext context) {
    return Consumer(
      builder: (context, ref, indicator) {
        return !ref.watch(hasConnectionProvider)
            ? indicator!
            : const SizedBox();
      },
      child: GestureDetector(
        onTap: () => _showAlert(context),
        child: Icon(
          EvaIcons.wifiOffOutline,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  void _showAlert(BuildContext context) {
    showOkAlertDialog(
      context: context,
      title: 'page_title_connectivity_error_title'.tr(),
      message: 'page_title_connectivity_error_message'.tr(args: [kAppName]),
    );
  }
}
