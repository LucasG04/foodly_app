import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../services/authentication_service.dart';
import 'small_circular_progress_indicator.dart';

class LoadingLogut extends StatefulWidget {
  const LoadingLogut({Key? key}) : super(key: key);

  @override
  _LoadingLogutState createState() => _LoadingLogutState();
}

class _LoadingLogutState extends State<LoadingLogut> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<void>(
        future: Future.delayed(const Duration(seconds: 10)),
        builder: (context, snapshot) => snapshot.connectionState ==
                ConnectionState.done
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SmallCircularProgressIndicator(),
                  const SizedBox(height: kPadding),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kPadding),
                    child: const Text(
                      'help_loading_logout',
                      textAlign: TextAlign.center,
                    ).tr(),
                  ),
                  const SizedBox(height: kPadding / 2),
                  TextButton(
                    onPressed: () => AuthenticationService.signOut(),
                    child: Text(
                      'settings_section_account_logout'.tr(),
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _sendSupportMail,
                    icon: const Icon(EvaIcons.paperPlaneOutline),
                    label: Text(
                      'help_loading_logout_mail'.tr(),
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ],
              )
            : const SmallCircularProgressIndicator(),
      ),
    );
  }

  Future<void> _sendSupportMail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'lucasg04@yahoo.com',
    );

    if (await canLaunch(uri.toString())) {
      await launch(uri.toString());
    }
  }
}
