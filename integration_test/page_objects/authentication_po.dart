import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/screens/authentication/authentication_keys.dart';

class AuthenticationPo {
  const AuthenticationPo(this.tester);

  final WidgetTester tester;

  Future<void> enterCode(String code) async {
    final input = find.byKey(AuthenticationKeys.inputCode);
    await tester.ensureVisible(input);
    await tester.enterText(input, code);
    await tester.pumpAndSettle();
  }

  Future<void> enterPlanName(String name) async {
    final input = find.byKey(AuthenticationKeys.inputPlanName);
    await tester.ensureVisible(input);
    await tester.enterText(input, name);

    final planNext = find.byKey(AuthenticationKeys.buttonPlanNameNext);
    await tester.ensureVisible(planNext);
    await tester.tap(planNext);
    await tester.pumpAndSettle();
  }

  Future<void> enterLoginCredentialsAndTapJoin() async {
    final buttonGroupLogin = find.byKey(AuthenticationKeys.buttonGroupLogin);
    await tester.ensureVisible(buttonGroupLogin);
    await tester.tap(buttonGroupLogin);
    await tester.pumpAndSettle();

    final inputMail = find.byKey(AuthenticationKeys.inputMail);
    await tester.ensureVisible(inputMail);
    await tester.enterText(inputMail, 'name');

    final inputPassword = find.byKey(AuthenticationKeys.inputMail);
    await tester.ensureVisible(inputPassword);
    await tester.enterText(inputPassword, 'name');

    final buttonJoin = find.byKey(AuthenticationKeys.buttonJoin);
    await tester.ensureVisible(buttonJoin);
    await tester.tap(buttonJoin);
    await tester.pumpAndSettle();
  }
}
