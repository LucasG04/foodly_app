import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/screens/authentication/auth_error.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

void main() {
  FirebaseAuthException firebase(String code) =>
      FirebaseAuthException(code: code);

  SignInWithAppleAuthorizationException apple(AuthorizationErrorCode code) =>
      SignInWithAppleAuthorizationException(code: code, message: '');

  test('cancels are not errors', () {
    expect(authErrorMessage(const PlanSelectCancelled()), isNull);
    expect(authErrorMessage(apple(AuthorizationErrorCode.canceled)), isNull);
  });

  test('maps known errors to their field and message', () {
    final cases = {
      const PlanLockedException(): (
        field: AuthErrorField.general,
        key: 'login_error_plan_locked'
      ),
      firebase('weak-password'): (
        field: AuthErrorField.password,
        key: 'login_error_password_weak'
      ),
      firebase('email-already-in-use'): (
        field: AuthErrorField.email,
        key: 'login_error_mail_in_use'
      ),
      firebase('invalid-email'): (
        field: AuthErrorField.email,
        key: 'login_error_wrong_mail'
      ),
      firebase('too-many-requests'): (
        field: AuthErrorField.general,
        key: 'login_error_too_many_requests'
      ),
      firebase('network-request-failed'): (
        field: AuthErrorField.general,
        key: 'login_error_network'
      ),
    };
    cases.forEach((error, expected) {
      expect(authErrorMessage(error), expected, reason: '$error');
    });
  });

  test('wrong credentials share one message across Firebase codes', () {
    for (final code in [
      'invalid-credential',
      'wrong-password',
      'user-not-found'
    ]) {
      expect(
        authErrorMessage(firebase(code)),
        (field: AuthErrorField.general, key: 'login_error_credentials'),
        reason: code,
      );
    }
  });

  test('everything else is unknown', () {
    for (final error in [
      firebase('user-disabled'),
      apple(AuthorizationErrorCode.failed),
      Exception('No user id.'),
      StateError('boom'),
    ]) {
      expect(
        authErrorMessage(error),
        (field: AuthErrorField.general, key: unknownAuthErrorKey),
        reason: '$error',
      );
    }
  });
}
