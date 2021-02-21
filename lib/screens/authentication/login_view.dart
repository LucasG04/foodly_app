import 'package:auto_route/auto_route.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';

import '../../app_router.gr.dart';
import '../../constants.dart';
import '../../services/authentication_service.dart';
import '../../services/plan_service.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/progress_button.dart';

class LoginView extends StatefulWidget {
  final String planId;
  final void Function() navigateBack;

  LoginView({this.planId, this.navigateBack});

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  ButtonState _buttonState;
  bool _isRegistering;

  TextEditingController _nameController;
  TextEditingController _passwordController;
  String _nameErrorText;
  String _passwordErrorText;
  String _unknownErrorText;

  @override
  void initState() {
    _buttonState = ButtonState.normal;
    _isRegistering = true;

    _nameController = new TextEditingController();
    _passwordController = new TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final contentWidth = size.width > 599 ? 600 : size.width * 0.9;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (MediaQuery.of(context).size.width - contentWidth) / 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: kPadding + MediaQuery.of(context).padding.top),
          FlutterToggleTab(
            width: 80,
            // width: contentWidth * 0.6 > 250 ? 250 : contentWidth * 0.6,
            borderRadius: 15,
            initialIndex: 0,
            selectedTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            unSelectedTextStyle: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            labels: ['Registrieren', 'Anmelden'],
            // icons: [Icons.person,Icons.pregnant_woman],
            selectedLabelIndex: (index) {
              setState(() {
                _isRegistering = index == 0;
              });
            },
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Wrap(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _isRegistering
                        ? Text(
                            'Registriere dich ',
                            key: ValueKey<int>(0),
                            style: _titleTextStyle,
                          )
                        : Text(
                            'Melde dich an ',
                            key: ValueKey<int>(1),
                            style: _titleTextStyle,
                          ),
                  ),
                  Text(
                    'um dem Plan beizuteten',
                    style: _titleTextStyle.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: kPadding),
          MainTextField(
            controller: _nameController,
            title: 'Benutzername',
            textInputAction: TextInputAction.next,
            errorText: _nameErrorText,
          ),
          MainTextField(
            controller: _passwordController,
            title: 'Passwort',
            textInputAction: TextInputAction.go,
            obscureText: true,
            errorText: _passwordErrorText,
          ),
          Container(
            height: size.height * 0.1,
            child: _unknownErrorText != null
                ? Row(
                    children: [
                      Icon(EvaIcons.alertTriangleOutline, color: Colors.red),
                      SizedBox(width: kPadding),
                      Expanded(
                        child: Text(
                          _unknownErrorText ?? '',
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                    ],
                  )
                : SizedBox(),
          ),
          MainButton(
            text: 'Beitreten',
            onTap: _authenticateUser,
            isProgress: true,
            buttonState: _buttonState,
          ),
          SizedBox(height: kPadding),
          MainButton(
            text: 'Zurück',
            onTap: widget.navigateBack,
            isSecondary: true,
          ),
          SizedBox(height: kPadding * 2),
        ],
      ),
    );
  }

  TextStyle get _titleTextStyle => TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.w700,
      );

  bool _validateName() {
    if (_nameController.text.isEmpty || _nameController.text.length < 3) {
      setState(() {
        _nameErrorText = 'Dein Name muss mindestens 3 Zeichen enthalten';
      });
      return false;
    }
    return true;
  }

  bool _validatePassword() {
    if (_passwordController.text.isEmpty ||
        _passwordController.text.length < 6) {
      setState(() {
        _passwordErrorText =
            'Dein Passwort muss mindestens 6 Zeichen enthalten';
      });
      return false;
    }
    return true;
  }

  void _authenticateUser() async {
    _resetErrors();

    if (_validateName() && _validatePassword()) {
      setState(() {
        _buttonState = ButtonState.inProgress;
      });

      String userId;
      final plan = widget.planId == null
          ? await PlanService.createPlan()
          : await PlanService.getPlanById(widget.planId);

      try {
        if (_isRegistering) {
          userId = await AuthenticationService.registerUser(
              _nameController.text, _passwordController.text, plan.code);
        } else {
          userId = await AuthenticationService.signInUser(
              _nameController.text, _passwordController.text, plan.code);
        }
      } catch (exception) {
        _handleAuthException(exception);
      }

      plan.users.add(userId);
      await PlanService.updatePlan(plan);

      ExtendedNavigator.root.replace(Routes.homeScreen);

      setState(() {
        _buttonState = ButtonState.normal;
      });
    } else {
      setState(() {
        _buttonState = ButtonState.error;
      });
    }
  }

  void _resetErrors() {
    setState(() {
      _nameErrorText = null;
      _passwordErrorText = null;
      _unknownErrorText = null;
      _buttonState = ButtonState.normal;
    });
  }

  void _handleAuthException(dynamic exception) {
    if (exception is FirebaseAuthException) {
      if (exception.code == 'weak-password') {
        print('The password provided is too weak.');
        _passwordErrorText =
            'Passwort ist zu leicht. Es muss mindestens 6 Zeichen lang sein.';
      } else if (exception.code == 'email-already-in-use') {
        _nameErrorText = 'Name ist bereits vergeben.';
      } else {
        _unknownErrorText =
            'Anmeldung nicht möglich. Bitte versuche es später erneut.';
      }
    } else {
      _unknownErrorText =
          'Anmeldung nicht möglich. Bitte versuche es später erneut.';
    }
    setState(() {
      _buttonState = ButtonState.error;
    });
  }
}
