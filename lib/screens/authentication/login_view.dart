import 'package:auto_route/auto_route.dart';
import 'package:email_validator/email_validator.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_router.gr.dart';
import '../../constants.dart';
import '../../models/foodly_user.dart';
import '../../models/plan.dart';
import '../../providers/state_providers.dart';
import '../../services/authentication_service.dart';
import '../../services/foodly_user_service.dart';
import '../../services/plan_service.dart';
import '../../utils/basic_utils.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/progress_button.dart';
import '../../widgets/toggle_tab/flutter_toggle_tab.dart';
import 'reset_password_modal.dart';

class LoginView extends StatefulWidget {
  final bool isCreatingPlan;
  final Plan plan;
  final void Function() navigateBack;

  LoginView({
    @required this.isCreatingPlan,
    @required this.plan,
    @required this.navigateBack,
  });

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  ButtonState _buttonState;
  bool _isRegistering;

  TextEditingController _emailController;
  TextEditingController _passwordController;
  FocusNode _passwordFocusNode;
  String _emailErrorText;
  String _passwordErrorText;
  String _unknownErrorText;

  @override
  void initState() {
    _buttonState = ButtonState.normal;
    _isRegistering = true;

    _emailController = new TextEditingController();
    _passwordController = new TextEditingController();
    _passwordFocusNode = new FocusNode();

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
                    widget.isCreatingPlan
                        ? 'um den Plan zu erstellen'
                        : 'um dem Plan beizuteten',
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
            controller: _emailController,
            title: 'E-Mail-Adresse',
            textInputAction: TextInputAction.next,
            errorText: _emailErrorText,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            onSubmit: () => (_passwordFocusNode.requestFocus()),
          ),
          MainTextField(
            controller: _passwordController,
            title: 'Passwort',
            textInputAction: TextInputAction.go,
            obscureText: true,
            errorText: _passwordErrorText,
            focusNode: _passwordFocusNode,
            onSubmit: _authenticateUser,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: !_isRegistering
                ? Container(
                    width: double.infinity,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        child: Text('Passwort vergessen?'),
                        onPressed: _showPasswordReset,
                      ),
                    ),
                  )
                : TextButton(
                    child: Text(''),
                    onPressed: null,
                  ),
          ),
          Container(
            height: size.height * 0.1 +
                MediaQuery.of(context).viewInsets.bottom / 6,
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

  bool _validateEmail() {
    if (_emailController.text == null ||
        !EmailValidator.validate(_emailController.text)) {
      setState(() {
        _emailErrorText = 'Bitte gib eine richtige E-Mail ein.';
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

    if (_validateEmail() && _validatePassword()) {
      setState(() {
        _buttonState = ButtonState.inProgress;
      });

      try {
        BasicUtils.clearAllProvider(context);

        final String userId = _isRegistering
            ? await AuthenticationService.registerUser(
                _emailController.text, _passwordController.text)
            : await AuthenticationService.signInUser(
                _emailController.text, _passwordController.text);

        final Plan plan = widget.isCreatingPlan
            ? await PlanService.createPlan(widget.plan.name)
            : await PlanService.getPlanById(widget.plan.id);

        if (!plan.users.contains(userId)) {
          plan.users.add(userId);
          await PlanService.updatePlan(plan);
        }

        FoodlyUser foodlyUser;
        if (_isRegistering) {
          foodlyUser = await FoodlyUserService.createUserWithId(userId);
        } else {
          foodlyUser = await FoodlyUserService.getUserById(userId);
        }

        foodlyUser.oldPlans.add(plan.id);
        await FoodlyUserService.addOldPlanIdToUser(userId, plan.id);

        context.read(planProvider).state = plan;
        context.read(userProvider).state = foodlyUser;

        setState(() {
          _buttonState = ButtonState.normal;
        });

        ExtendedNavigator.root.replace(Routes.homeScreen);
      } catch (exception) {
        _handleAuthException(exception);
      }
    } else {
      setState(() {
        _buttonState = ButtonState.error;
      });
    }
  }

  void _resetErrors() {
    setState(() {
      _emailErrorText = null;
      _passwordErrorText = null;
      _unknownErrorText = null;
      _buttonState = ButtonState.normal;
    });
  }

  void _handleAuthException(dynamic exception) {
    if (exception is FirebaseAuthException) {
      if (exception.code == 'weak-password') {
        _passwordErrorText =
            'Das Passwort ist zu leicht. Es muss mindestens 6 Zeichen lang sein.';
      } else if (exception.code == 'email-already-in-use') {
        _emailErrorText = 'Es gibt bereits ein Konto mit dieser E-Mail.';
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

  void _showPasswordReset() {
    showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      context: context,
      isScrollControlled: true,
      builder: (context) => ResetPasswordModal(_emailController.text),
    );
  }
}
