import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:email_validator/email_validator.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'select_plan_modal.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
  bool _forgotPlan;

  TextEditingController _emailController;
  TextEditingController _passwordController;
  FocusNode _passwordFocusNode;
  String _emailErrorText;
  String _passwordErrorText;
  String _unknownErrorText;

  @override
  void initState() {
    _buttonState = ButtonState.normal;
    _forgotPlan = widget.plan == null;
    _isRegistering =
        !_forgotPlan; // default `true`, but if user forgot plan then not registering

    _emailController = new TextEditingController();
    _passwordController = new TextEditingController();
    _passwordFocusNode = new FocusNode();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final contentWidth = BasicUtils.contentWidth(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (MediaQuery.of(context).size.width - contentWidth) / 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: kPadding + MediaQuery.of(context).padding.top),
          FlutterToggleTab(
            width: 50,
            borderRadius: 15,
            initialIndex: 0,
            selectedTextStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            unSelectedTextStyle: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w400,
            ),
            labels: _forgotPlan
                ? ['login_title_login'.tr()]
                : ['login_title_register'.tr(), 'login_title_login'.tr()],
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
                            'login_register_leading'.tr() + ' ',
                            key: ValueKey<int>(0),
                            style: _titleTextStyle,
                          )
                        : Text(
                            'login_login_leading'.tr() + ' ',
                            key: ValueKey<int>(1),
                            style: _titleTextStyle,
                          ),
                  ),
                  Text(
                    widget.isCreatingPlan
                        ? 'login_cta_create'
                        : 'login_cta_join',
                    style: _titleTextStyle.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ).tr(),
                ],
              ),
            ),
          ),
          SizedBox(height: kPadding),
          MainTextField(
            controller: _emailController,
            title: 'login_mail_title'.tr(),
            textInputAction: TextInputAction.next,
            errorText: _emailErrorText,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            onSubmit: () => (_passwordFocusNode.requestFocus()),
          ),
          MainTextField(
            controller: _passwordController,
            title: 'login_password_title'.tr(),
            textInputAction: TextInputAction.go,
            obscureText: true,
            errorText: _passwordErrorText,
            focusNode: _passwordFocusNode,
            onSubmit: _authWithEmail,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: !_isRegistering
                ? Container(
                    width: double.infinity,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        child: Text('login_forgot_password').tr(),
                        onPressed: _showPasswordReset,
                      ),
                    ),
                  )
                : TextButton(
                    child: Text(''),
                    onPressed: null,
                  ),
          ),
          SizedBox(height: kPadding / 2),
          SignInWithAppleButton(onPressed: _authWithApple),
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
          LayoutBuilder(builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MainButton(
                  iconData: Icons.arrow_back_ios_new_rounded,
                  width: constraints.maxWidth * 0.25,
                  onTap: widget.navigateBack,
                  isSecondary: true,
                ),
                MainButton(
                  text: 'login_join'.tr(),
                  width: constraints.maxWidth * 0.65,
                  onTap: _authWithEmail,
                  isProgress: true,
                  buttonState: _buttonState,
                ),
              ],
            );
          }),
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
        _emailErrorText = 'login_error_wrong_mail'.tr();
      });
      return false;
    }
    return true;
  }

  bool _validatePassword() {
    if (_passwordController.text.isEmpty ||
        _passwordController.text.length < 6) {
      setState(() {
        _passwordErrorText = 'login_error_password'.tr();
      });
      return false;
    }
    return true;
  }

  Future<void> _authWithEmail() async {
    _prepareAuth();
    if (!_validateEmail() || !_validatePassword()) {
      setState(() {
        _buttonState = ButtonState.error;
      });
      return;
    }

    try {
      final userId = await (_isRegistering && !_forgotPlan
          ? AuthenticationService.registerUser(
              _emailController.text, _passwordController.text)
          : AuthenticationService.signInUser(
              _emailController.text, _passwordController.text));
      await _processAuthentication(userId);
    } catch (e) {
      _handleAuthException(e);
    }
  }

  Future<void> _authWithApple() async {
    _prepareAuth();

    try {
      final userId = await AuthenticationService.signInWithApple();
      await _processAuthentication(userId);
    } catch (e) {
      _handleAuthException(e);
    }
  }

  void _prepareAuth() {
    _resetErrors();
    setState(() {
      _buttonState = ButtonState.inProgress;
    });
    BasicUtils.clearAllProvider(context);
  }

  Future<void> _processAuthentication(String userId) async {
    if (userId == null || userId.isEmpty) {
      throw Exception('No user id.');
    }

    Plan plan;
    if (_forgotPlan) {
      plan = await _showPlanSelect(userId);
      if (plan == null) {
        await AuthenticationService.signOut();
        throw Exception('No plan selected.');
      }
    } else {
      plan = widget.isCreatingPlan
          ? await PlanService.createPlan(widget.plan.name)
          : await PlanService.getPlanById(widget.plan.id);
    }

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

    context.router.replace(HomeScreenRoute());
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
        _passwordErrorText = 'login_error_password_weak'.tr();
      } else if (exception.code == 'email-already-in-use') {
        _emailErrorText = 'login_error_mail_in_use'.tr();
      } else {
        _unknownErrorText = 'login_error_unknown'.tr();
      }
    } else {
      _unknownErrorText = 'login_error_unknown'.tr();
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

  Future<Plan> _showPlanSelect(userId) {
    return showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.0),
        ),
      ),
      context: context,
      isScrollControlled: true,
      builder: (_) => SelectPlanModal(userId),
    );
  }
}
