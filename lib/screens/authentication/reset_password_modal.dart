import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:email_validator/email_validator.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../services/authentication_service.dart';
import '../../utils/of_context_mixin.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/progress_button.dart';

class ResetPasswordModal extends StatefulWidget {
  final String? email;

  // ignore: use_key_in_widget_constructors
  const ResetPasswordModal([this.email]);

  @override
  State<ResetPasswordModal> createState() => _ResetPasswordModalState();
}

class _ResetPasswordModalState extends State<ResetPasswordModal>
    with OfContextMixin {
  TextEditingController? _emailController;
  ButtonState? _buttonState;
  String? _errorText;
  bool _showSuccess = false;

  @override
  void initState() {
    _emailController = TextEditingController(text: widget.email ?? '');
    _buttonState = ButtonState.normal;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = media.size.width > 599 ? 580.0 : media.size.width * 0.8;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (media.size.width - width) / 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: kPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: AutoSizeText(
                      'modal_password_reset_title'.tr().toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      minFontSize: 16,
                      maxLines: 1,
                    ),
                  ),
                  GestureDetector(
                    child: const Icon(EvaIcons.close),
                    onTap: () => Navigator.maybePop(context),
                  ),
                ],
              ),
            ),
          ),
          MainTextField(
            controller: _emailController,
            title: 'modal_password_reset_mail_title'.tr(),
            placeholder: 'tony@gmail.com',
            errorText: _errorText,
            onSubmit: _resetPassword,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: kPadding),
          if (_showSuccess)
            Row(
              // ignore: avoid_redundant_argument_values
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  EvaIcons.checkmarkCircle2Outline,
                  color: kSuccessColor,
                ),
                const SizedBox(width: kPadding),
                Flexible(
                  child: const Text(
                    'modal_password_reset_result_msg',
                  ).tr(),
                ),
              ],
            )
          else
            const SizedBox(),
          SizedBox(
            height: media.viewInsets.bottom == 0
                ? kPadding * 2
                : media.viewInsets.bottom > 60 // 60 for MainButton
                    ? media.viewInsets.bottom - 60
                    : media.viewInsets.bottom,
          ),
          Center(
            child: MainButton(
              text: 'modal_password_reset_reset'.tr(),
              isProgress: true,
              buttonState: _buttonState,
              onTap: _resetPassword,
            ),
          ),
          const SizedBox(height: kPadding * 2),
        ],
      ),
    );
  }

  void _resetPassword() async {
    if (EmailValidator.validate(_emailController!.text) && !_showSuccess) {
      setState(() {
        _buttonState = ButtonState.inProgress;
      });

      try {
        await AuthenticationService.resetPassword(_emailController!.text);
      } catch (e) {
        _handleFirebaseResetException(e);
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _buttonState = ButtonState.normal;
        _errorText = null;
        _showSuccess = true;
      });

      await Future<void>.delayed(const Duration(seconds: 30));

      if (!mounted) {
        return;
      }

      setState(() {
        _showSuccess = false;
      });
    } else {
      setState(() {
        _errorText = 'modal_password_reset_error_mail_invalid'.tr();
        _buttonState = ButtonState.error;
      });
    }
  }

  void _handleFirebaseResetException(dynamic exception) {
    if (exception is FirebaseAuthException) {
      if (exception.code == 'user-not-found') {
        _errorText = 'modal_password_reset_error_mail_not_found'.tr();
      } else {
        _errorText = 'modal_password_reset_error_unknown'.tr();
      }
    } else {
      _errorText = 'modal_password_reset_error_unknown'.tr();
    }
    setState(() {
      _buttonState = ButtonState.error;
    });
  }
}
