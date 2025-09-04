import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:email_validator/email_validator.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
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
import '../../utils/firebase_auth_providers.dart';
import '../../utils/widget_utils.dart';
import '../../widgets/main_button.dart';
import '../../widgets/main_text_field.dart';
import '../../widgets/progress_button.dart';
import '../../widgets/toggle_tab/flutter_toggle_tab.dart';
import 'authentication_keys.dart';
import 'reset_password_modal.dart';
import 'select_plan_modal.dart';

class LoginView extends ConsumerStatefulWidget {
  final bool? isCreatingPlan;
  final Plan? plan;
  final void Function() navigateBack;

  const LoginView({
    required this.isCreatingPlan,
    required this.plan,
    required this.navigateBack,
    super.key,
  });

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  static final _log = Logger('LoginView');

  ButtonState? _buttonState;
  late bool _isRegistering;
  late bool _forgotPlan;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late FocusNode _passwordFocusNode;

  String? _emailErrorText;
  String? _passwordErrorText;
  String? _unknownErrorText;

  @override
  void initState() {
    _buttonState = ButtonState.normal;
    _forgotPlan = widget.plan == null;
    _isRegistering =
        !_forgotPlan; // default `true`, but if user forgot plan then not registering

    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _passwordFocusNode = FocusNode();

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
        children: [
          SizedBox(height: kPadding + MediaQuery.of(context).padding.top),
          FlutterToggleTab(
            width: 50,
            borderRadius: 15,
            selectedTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            unSelectedTextStyle: const TextStyle(
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
            buttonKeys: _forgotPlan
                ? [AuthenticationKeys.buttonGroupLogin]
                : [
                    AuthenticationKeys.buttonGroupRegister,
                    AuthenticationKeys.buttonGroupLogin
                  ],
          ),
          const SizedBox(height: kPadding * 2),
          Align(
            alignment: Alignment.bottomLeft,
            child: Wrap(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _isRegistering
                      ? Text(
                          '${'login_register_leading'.tr()} ',
                          key: const ValueKey<int>(0),
                          style: _titleTextStyle,
                        )
                      : Text(
                          '${'login_login_leading'.tr()} ',
                          key: const ValueKey<int>(1),
                          style: _titleTextStyle,
                        ),
                ),
                Text(
                  widget.isCreatingPlan!
                      ? 'login_cta_create'
                      : 'login_cta_join',
                  style: _titleTextStyle.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ).tr(),
              ],
            ),
          ),
          const SizedBox(height: kPadding),
          AutofillGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MainTextField(
                  key: AuthenticationKeys.inputMail,
                  controller: _emailController,
                  title: 'login_mail_title'.tr(),
                  textInputAction: TextInputAction.next,
                  errorText: _emailErrorText,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  onSubmit: () => _passwordFocusNode.requestFocus(),
                  autofillHints: [
                    AutofillHints.email,
                    // ignore: prefer_if_elements_to_conditional_expressions
                    _isRegistering
                        ? AutofillHints.newUsername
                        : AutofillHints.username,
                  ],
                ),
                MainTextField(
                  key: AuthenticationKeys.inputPassword,
                  controller: _passwordController,
                  title: 'login_password_title'.tr(),
                  textInputAction: TextInputAction.go,
                  obscureText: true,
                  errorText: _passwordErrorText,
                  focusNode: _passwordFocusNode,
                  onSubmit: _authWithEmail,
                  autofillHints: _isRegistering
                      ? [AutofillHints.newPassword]
                      : [AutofillHints.password],
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: !_isRegistering
                ? SizedBox(
                    width: double.infinity,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showPasswordReset,
                        child: Text(
                          'login_forgot_password',
                          style:
                              TextStyle(color: Theme.of(context).primaryColor),
                        ).tr(),
                      ),
                    ),
                  )
                : const TextButton(
                    onPressed: null,
                    child: Text(''),
                  ),
          ),
          const SizedBox(height: kPadding / 2),
          if (Platform.isIOS || Platform.isMacOS)
            SignInWithAppleButton(onPressed: _authWithApple),
          SizedBox(
            height: size.height * 0.1,
            child: _unknownErrorText != null
                ? Row(
                    children: [
                      const Icon(EvaIcons.alertTriangleOutline,
                          color: Colors.red),
                      const SizedBox(width: kPadding),
                      Expanded(
                        child: Text(
                          _unknownErrorText ?? '',
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    ],
                  )
                : const SizedBox(),
          ),
          const Spacer(),
          LayoutBuilder(builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MainButton(
                  key: AuthenticationKeys.buttonLoginBack,
                  iconData: Icons.arrow_back_ios_new_rounded,
                  width: constraints.maxWidth * 0.25,
                  onTap: widget.navigateBack,
                  isSecondary: true,
                ),
                SizedBox(
                  width: constraints.maxWidth * 0.65,
                  child: Center(
                    child: MainButton(
                      key: AuthenticationKeys.buttonJoin,
                      text: 'login_join'.tr(),
                      width: constraints.maxWidth * 0.65,
                      onTap: _authWithEmail,
                      isProgress: true,
                      buttonState: _buttonState,
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: kPadding * 2),
        ],
      ),
    );
  }

  TextStyle get _titleTextStyle => const TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.w700,
      );

  bool _validateEmail() {
    if (!EmailValidator.validate(_emailController.text)) {
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

    TextInput.finishAutofillContext();
    try {
      final userId = await (_isRegistering && !_forgotPlan
          ? AuthenticationService.registerUser(
              _emailController.text, _passwordController.text)
          : AuthenticationService.signInUser(
              _emailController.text, _passwordController.text));
      await _processAuthentication(userId, FirebaseAuthProvider.password);
    } catch (e) {
      _handleMailAuthException(e);
    }
  }

  Future<void> _authWithApple() async {
    _prepareAuth();

    try {
      final userId = await AuthenticationService.signInWithApple();
      await _processAuthentication(userId, FirebaseAuthProvider.apple);
    } catch (e) {
      if (!mounted) {
        return;
      }
      _log.severe('ERR! _authWithApple', e);
      setState(() {
        _unknownErrorText = 'login_error_unknown'.tr();
        _buttonState = ButtonState.error;
      });
    }
  }

  void _prepareAuth() {
    _resetErrors();
    setState(() {
      _buttonState = ButtonState.inProgress;
    });
    BasicUtils.clearAllProvider(ref);
  }

  Future<void> _processAuthentication(String? userId, String platform) async {
    if (userId == null || userId.isEmpty) {
      throw Exception('No user id.');
    }

    Plan? plan;
    if (_forgotPlan) {
      plan = await _showPlanSelect(userId);
      if (plan == null) {
        await AuthenticationService.signOut();
        throw Exception('No plan selected.');
      }
    } else {
      plan = widget.isCreatingPlan!
          ? await PlanService.createPlan(widget.plan!.name)
          : await PlanService.getPlanById(widget.plan!.id);
    }

    if (plan != null && !plan.users!.contains(userId)) {
      if (plan.locked != null && plan.locked!) {
        setState(() {
          _unknownErrorText = 'login_error_plan_locked'.tr();
          _buttonState = ButtonState.error;
        });
        return;
      }
      plan.users!.add(userId);
      plan.lastUserJoined = DateTime.now();
      await PlanService.updatePlan(plan);
    }

    FoodlyUser foodlyUser;
    if (_isRegistering) {
      foodlyUser = await FoodlyUserService.createUserWithId(userId);
    } else {
      foodlyUser = (await FoodlyUserService.getUserById(userId))!;
    }

    foodlyUser.plans!.add(plan!.id);
    await FoodlyUserService.addPlanIdToUser(userId, plan.id);

    setState(() {
      _buttonState = ButtonState.normal;
    });

    if (!mounted) {
      return;
    }
    if (_isRegistering) {
      FirebaseAnalytics.instance.logSignUp(signUpMethod: platform);
    } else {
      FirebaseAnalytics.instance.logLogin(loginMethod: platform);
    }
    ref.read(planProvider.notifier).state = plan;
    ref.read(userProvider.notifier).state = foodlyUser;
    AutoRouter.of(context).replace(const HomeScreenRoute());
  }

  void _resetErrors() {
    setState(() {
      _emailErrorText = null;
      _passwordErrorText = null;
      _unknownErrorText = null;
      _buttonState = ButtonState.normal;
    });
  }

  void _handleMailAuthException(dynamic exception) {
    if (exception != null && exception is FirebaseAuthException) {
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
    WidgetUtils.showFoodlyBottomSheet<void>(
      context: context,
      builder: (_) => ResetPasswordModal(_emailController.text),
    );
  }

  Future<Plan?> _showPlanSelect(String userId) {
    return showModalBottomSheet(
      shape: const RoundedRectangleBorder(
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
