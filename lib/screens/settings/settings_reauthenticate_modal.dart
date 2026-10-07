import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../constants.dart';
import '../../services/authentication_service.dart';
import '../../utils/firebase_auth_providers.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/progress_button.dart';
import '../../widgets/sheet_header.dart';

/// Reauthenticates the user with password.
///
/// Returns `true` (via Navigator), if the authentication was successful.
class SettingsReauthenticateModal extends ConsumerStatefulWidget {
  const SettingsReauthenticateModal({super.key});

  @override
  _SettingsReauthenticateModalState createState() =>
      _SettingsReauthenticateModalState();
}

class _SettingsReauthenticateModalState
    extends ConsumerState<SettingsReauthenticateModal> {
  final TextEditingController _passwordController = TextEditingController();
  final AutoDisposeStateProvider<ButtonState> _$buttonState =
      StateProvider.autoDispose<ButtonState>((_) => ButtonState.normal);
  final AutoDisposeStateProvider<String?> _$errorText =
      StateProvider.autoDispose<String?>((_) => null);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width > 599
        ? 580.0
        : MediaQuery.sizeOf(context).width * 0.8;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (MediaQuery.sizeOf(context).width - width) / 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SheetHeader(
            title: context.tr('settings_reauthenticate_title'),
            padding: const EdgeInsets.only(top: kPadding, bottom: kPadding / 2),
          ),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyLarge,
              children: <TextSpan>[
                TextSpan(
                    text:
                        '${context.tr('settings_reauthenticate_description_1')} '),
                TextSpan(
                  text: AuthenticationService.currentUser?.email ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      ' ${context.tr('settings_reauthenticate_description_2')}',
                ),
              ],
            ),
          ),
          if (AuthenticationService.userHasAuthProvider(
              FirebaseAuthProvider.apple))
            ..._buildApple(),
          if (AuthenticationService.userHasAuthProvider(
              FirebaseAuthProvider.password))
            ..._buildPassword(),
          SizedBox(
            height: MediaQuery.viewInsetsOf(context).bottom == 0
                ? WidgetUtils.sheetBottomPadding(context)
                : MediaQuery.viewInsetsOf(context).bottom,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildApple() {
    return [
      const SizedBox(height: kPadding),
      SignInWithAppleButton(
        onPressed: () => _reauthenticate(FirebaseAuthProvider.apple),
      ),
    ];
  }

  List<Widget> _buildPassword() {
    return [
      const SizedBox(height: kPadding),
      Consumer(builder: (context, ref, _) {
        final errorText = ref.watch(_$errorText);
        return MainTextField(
          controller: _passwordController,
          title: context.tr('settings_reauthenticate_input_title'),
          placeholder: '********',
          textInputAction: TextInputAction.go,
          obscureText: true,
          errorText: errorText == null ? null : context.tr(errorText),
          errorMaxLines: 2,
          onSubmit: () => _reauthenticate(FirebaseAuthProvider.password),
        );
      }),
      const SizedBox(height: kPadding * 2),
      Center(
        child: Consumer(builder: (context, ref, _) {
          final buttonState = ref.watch(_$buttonState);
          return MainButton(
            text: context.tr('settings_reauthenticate_action'),
            isProgress: true,
            buttonState: buttonState,
            onTap: () => _reauthenticate(FirebaseAuthProvider.password),
          );
        }),
      ),
    ];
  }

  Future<void> _reauthenticate(String firebaseAuthProvider) async {
    ref.read(_$buttonState.notifier).state = ButtonState.inProgress;
    ref.read(_$errorText.notifier).state = null;

    bool successful = false;
    if (firebaseAuthProvider == FirebaseAuthProvider.password) {
      successful = await _authWithPassword();
    } else if (firebaseAuthProvider == FirebaseAuthProvider.apple) {
      successful = await _authWithApple();
    }

    if (!mounted || !successful) {
      return;
    }

    ref.read(_$buttonState.notifier).state = ButtonState.normal;
    ref.read(_$errorText.notifier).state = null;
    // mounted is check above
    // ignore: use_build_context_synchronously
    Navigator.of(context).pop(true);
  }

  Future<bool> _authWithPassword() async {
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      ref.read(_$buttonState.notifier).state = ButtonState.error;
      ref.read(_$errorText.notifier).state =
          'settings_reauthenticate_input_error_empty';
      return false;
    }

    try {
      await AuthenticationService.reauthenticatePassword(password);
    } catch (e) {
      if (e is FirebaseAuthException) {
        ref.read(_$buttonState.notifier).state = ButtonState.error;
        ref.read(_$errorText.notifier).state =
            'settings_reauthenticate_input_error_wrong';
        return false;
      }
    }
    return true;
  }

  Future<bool> _authWithApple() async {
    try {
      await AuthenticationService.reauthenticateApple();
    } catch (e) {
      if (e is FirebaseAuthException) {
        ref.read(_$buttonState.notifier).state = ButtonState.error;
        ref.read(_$errorText.notifier).state = null;
        return false;
      }
    }
    return true;
  }
}
