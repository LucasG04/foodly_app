import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/main.dart' as app;
import 'package:integration_test/integration_test.dart';

import 'page_objects/authentication_po.dart';
import 'page_objects/onboarding_po.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('e2e Tests', () {
    testWidgets('Authentication: Plan code input and login', (tester) async {
      await app.main();
      await tester.pumpAndSettle();
      final authPo = AuthenticationPo(tester);
      final onboardingPo = OnboardingPo(tester);

      await onboardingPo.skipOnboarding();

      await authPo.enterCode('91390326');
      await authPo.enterLoginCredentialsAndTapJoin();
    });
  });
}
