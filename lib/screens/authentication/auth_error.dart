import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// The user closed the plan picker, which is not an error.
class PlanSelectCancelled implements Exception {
  const PlanSelectCancelled();
}

class PlanLockedException implements Exception {
  const PlanLockedException();
}

enum AuthErrorField { email, password, general }

/// Translation key for errors without a specific message; worth logging.
const unknownAuthErrorKey = 'login_error_unknown';

/// Where to show [error] and its translation key, or null for a cancel.
({AuthErrorField field, String key})? authErrorMessage(Object error) =>
    switch (error) {
      PlanSelectCancelled() ||
      SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.canceled
      ) =>
        null,
      PlanLockedException() => (
          field: AuthErrorField.general,
          key: 'login_error_plan_locked'
        ),
      FirebaseAuthException(code: 'weak-password') => (
          field: AuthErrorField.password,
          key: 'login_error_password_weak'
        ),
      FirebaseAuthException(code: 'email-already-in-use') => (
          field: AuthErrorField.email,
          key: 'login_error_mail_in_use'
        ),
      FirebaseAuthException(code: 'invalid-email') => (
          field: AuthErrorField.email,
          key: 'login_error_wrong_mail'
        ),
      FirebaseAuthException(
        code: 'invalid-credential' || 'wrong-password' || 'user-not-found'
      ) =>
        (field: AuthErrorField.general, key: 'login_error_credentials'),
      FirebaseAuthException(code: 'too-many-requests') => (
          field: AuthErrorField.general,
          key: 'login_error_too_many_requests'
        ),
      FirebaseAuthException(code: 'network-request-failed') => (
          field: AuthErrorField.general,
          key: 'login_error_network'
        ),
      _ => (field: AuthErrorField.general, key: unknownAuthErrorKey),
    };
