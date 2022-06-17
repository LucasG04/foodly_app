import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants.dart';
import '../../services/authentication_service.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/progress_button.dart';

/// Reauthenticates the user with password.
///
/// Returns `true` (via Navigator), if the authentication was successful.
class SettingsReauthenticateModal extends StatefulWidget {
  const SettingsReauthenticateModal({Key? key}) : super(key: key);

  @override
  State<SettingsReauthenticateModal> createState() =>
      _SettingsReauthenticateModalState();
}

class _SettingsReauthenticateModalState
    extends State<SettingsReauthenticateModal> {
  final TextEditingController _passwordController = TextEditingController();
  final AutoDisposeStateProvider<ButtonState> _$buttonState =
      StateProvider.autoDispose((_) => ButtonState.normal);
  final AutoDisposeStateProvider<String?> _$errorText =
      StateProvider.autoDispose((_) => null);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width > 599
        ? 580.0
        : MediaQuery.of(context).size.width * 0.8;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (MediaQuery.of(context).size.width - width) / 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: kPadding),
              child: const Text(
                'settings_reauthenticate_title',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ).tr(),
            ),
          ),
          const SizedBox(height: kPadding * 2),
          Consumer(builder: (context, watch, _) {
            final errorText = watch(_$errorText).state;
            return MainTextField(
              controller: _passwordController,
              title: 'settings_reauthenticate_input_title'.tr(),
              placeholder: '********',
              textInputAction: TextInputAction.go,
              obscureText: true,
              errorText: errorText?.tr(),
              onSubmit: _reauthenticate,
            );
          }),
          const SizedBox(height: kPadding * 2),
          Center(
            child: Consumer(builder: (context, watch, _) {
              final buttonState = watch(_$buttonState).state;
              return MainButton(
                text: 'settings_reauthenticate_action'.tr(),
                isProgress: true,
                buttonState: buttonState,
                onTap: _reauthenticate,
              );
            }),
          ),
          SizedBox(
            height: MediaQuery.of(context).viewInsets.bottom == 0
                ? kPadding * 2
                : MediaQuery.of(context).viewInsets.bottom,
          ),
        ],
      ),
    );
  }

  Future<void> _reauthenticate() async {
    context.read(_$buttonState).state = ButtonState.inProgress;
    context.read(_$errorText).state = null;

    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      context.read(_$buttonState).state = ButtonState.error;
      context.read(_$errorText).state =
          'settings_reauthenticate_input_error_empty';
    }

    try {
      await AuthenticationService.reauthenticate(password);
    } catch (e) {
      if (e is FirebaseAuthException) {
        context.read(_$buttonState).state = ButtonState.error;
        context.read(_$errorText).state =
            'settings_reauthenticate_input_error_wrong';
      }
    }

    if (!mounted) {
      return;
    }

    context.read(_$buttonState).state = ButtonState.normal;
    context.read(_$errorText).state = null;
    Navigator.of(context).pop(true);
  }
}
