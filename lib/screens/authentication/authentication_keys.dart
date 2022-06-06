import 'package:flutter/foundation.dart';

// ignore: avoid_classes_with_only_static_members
class AuthenticationKeys {
  static const String _prefix = 'authentication';

  static Key get buttonCreatePlan => const Key('${_prefix}_btn_create_plan');
  static Key get buttonForgotCode => const Key('${_prefix}_btn_forgot_code');
  static Key get buttonJoin => const Key('${_prefix}_btn_join');
  static Key get buttonNameBack => const Key('${_prefix}_btn_name_back');
  static Key get buttonLoginBack => const Key('${_prefix}_btn_login_back');
  static Key get buttonGroupRegister =>
      const Key('${_prefix}_btn_group_register');
  static Key get buttonGroupLogin => const Key('${_prefix}_btn_group_login');
  static Key get buttonPlanNameNext =>
      const Key('${_prefix}_btn_plan_name_next');

  static Key get inputCode => const Key('${_prefix}_input_code');
  static Key get inputPlanName => const Key('${_prefix}_plan_name');
  static Key get inputMail => const Key('${_prefix}_mail');
  static Key get inputPassword => const Key('${_prefix}_password');
}
