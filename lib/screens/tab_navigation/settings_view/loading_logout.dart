import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../services/authentication_service.dart';
import '../../../widgets/small_circular_progress_indicator.dart';

class LoadingLogut extends StatefulWidget {
  const LoadingLogut();

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
                  TextButton(
                    onPressed: () => AuthenticationService.signOut(),
                    child: Text(
                      'settings_section_account_logout'.tr(),
                      style: TextStyle(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ],
              )
            : const SmallCircularProgressIndicator(),
      ),
    );
  }
}
