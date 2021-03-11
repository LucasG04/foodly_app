import 'package:auto_size_text/auto_size_text.dart';
import 'package:email_validator/email_validator.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodly/services/authentication_service.dart';
import 'package:foodly/widgets/main_button.dart';
import 'package:foodly/widgets/main_text_field.dart';
import 'package:foodly/widgets/progress_button.dart';

import '../../constants.dart';

class ResetPasswordModal extends StatefulWidget {
  final String email;

  ResetPasswordModal([this.email]);

  @override
  _ResetPasswordModalState createState() => _ResetPasswordModalState();
}

class _ResetPasswordModalState extends State<ResetPasswordModal> {
  TextEditingController _emailController;
  ButtonState _buttonState;
  String _errorText;
  bool _showSuccess = false;

  @override
  void initState() {
    _emailController = new TextEditingController(text: widget.email ?? '');
    _buttonState = ButtonState.normal;

    super.initState();
  }

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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AutoSizeText(
                    'PASSWORT ZURÜCKSETZEN',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  GestureDetector(
                    child: Icon(EvaIcons.closeOutline),
                    onTap: () => Navigator.maybePop(context),
                  ),
                ],
              ),
            ),
          ),
          MainTextField(
            controller: _emailController,
            title: 'E-Mail-Adresse',
            placeholder: 'tony@gmail.com',
            errorText: _errorText,
            onSubmit: _resetPassword,
          ),
          SizedBox(height: kPadding),
          _showSuccess
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      EvaIcons.checkmarkCircle2Outline,
                      color: kSuccessColor,
                    ),
                    SizedBox(width: kPadding),
                    Flexible(
                      child: Text(
                        'Wir haben dir eine E-Mail zum Zurücksetzen von deinem Passwort geschickt.',
                      ),
                    ),
                  ],
                )
              : SizedBox(),
          SizedBox(
            height: kPadding * 2 + MediaQuery.of(context).viewInsets.bottom,
          ),
          Center(
            child: MainButton(
              text: 'Zurücksetzen',
              isProgress: true,
              buttonState: _buttonState,
              onTap: _resetPassword,
            ),
          ),
          SizedBox(height: kPadding * 2),
        ],
      ),
    );
  }

  void _resetPassword() async {
    if (_emailController.text != null &&
        EmailValidator.validate(_emailController.text) &&
        !_showSuccess) {
      setState(() {
        _buttonState = ButtonState.inProgress;
      });

      try {
        await AuthenticationService.resetPassword(_emailController.text);
      } catch (e) {
        _handleFirebaseResetException(e);
        return;
      }

      setState(() {
        _buttonState = ButtonState.normal;
        _errorText = null;
        _showSuccess = true;
      });

      await Future.delayed(const Duration(seconds: 30));

      setState(() {
        _showSuccess = false;
      });
    } else {
      setState(() {
        _errorText = 'Bitte gib eine richtige E-Mail ein.';
        _buttonState = ButtonState.error;
      });
    }
  }

  void _handleFirebaseResetException(dynamic exception) {
    if (exception is FirebaseAuthException) {
      if (exception.code == 'user-not-found') {
        _errorText = 'Diese E-Mail ist nicht vergeben.';
      } else {
        _errorText =
            'Zurücksetzen nicht möglich. Bitte versuche es später erneut.';
      }
    } else {
      _errorText =
          'Zurücksetzen nicht möglich. Bitte versuche es später erneut.';
    }
    setState(() {
      _buttonState = ButtonState.error;
    });
  }
}
