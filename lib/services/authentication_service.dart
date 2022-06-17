import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../utils/firebase_auth_providers.dart';
import 'foodly_user_service.dart';

class AuthenticationService {
  AuthenticationService._();

  static final _log = Logger('AuthenticationService');
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static User? get currentUser => _auth.currentUser;

  static Stream<User?> authenticationStream() {
    _log.finer('Stream authStateChanges');
    return _auth.authStateChanges();
  }

  static Future<String> signInUser(String email, String password) async {
    _log.finer('Call signInWithEmailAndPassword with $email');
    return (await _auth.signInWithEmailAndPassword(
            email: email, password: password))
        .user!
        .uid;
  }

  static Future<String> registerUser(String email, String password) async {
    _log.finer('Call createUserWithEmailAndPassword with $email');
    return (await _auth.createUserWithEmailAndPassword(
            email: email, password: password))
        .user!
        .uid;
  }

  static Future<void> signOut() async {
    _log.finer('Call signOut');
    return _auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    _log.finer('Call resetPassword with $email');
    return _auth.sendPasswordResetEmail(email: email);
  }

  static Future<void> deleteAccount() async {
    _log.finer('Call deleteAccount');
    if (_auth.currentUser == null) {
      return;
    }
    try {
      FoodlyUserService.deleteUserById(_auth.currentUser!.uid);
    } catch (e) {
      _log.severe(
          'ERR! deleteAccount at deleteUserById with ${_auth.currentUser!.uid}',
          e);
    }
    return _auth.currentUser!.delete();
  }

  static Future<UserCredential?> reauthenticateApple() async {
    if (_auth.currentUser == null ||
        !userHasAuthProvider(FirebaseAuthProvider.apple)) {
      return null;
    }

    final credential = await _getAppleOAuthCredential();
    return _auth.currentUser!.reauthenticateWithCredential(credential);
  }

  static Future<UserCredential?> reauthenticatePassword(String password) async {
    if (_auth.currentUser == null ||
        !userHasAuthProvider(FirebaseAuthProvider.password)) {
      return null;
    }

    final credential = EmailAuthProvider.credential(
      email: _auth.currentUser!.email ?? '',
      password: password,
    );
    return _auth.currentUser!.reauthenticateWithCredential(credential);
  }

  static bool userHasAuthProvider(String providerId) {
    if (_auth.currentUser == null) {
      return false;
    }
    return _auth.currentUser!.providerData
        .any((e) => e.providerId == providerId);
  }

  /// Generates a cryptographically secure random nonce, to be included in a
  /// credential request.
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation.
  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<OAuthCredential> _getAppleOAuthCredential() async {
    // To prevent replay attacks with the credential returned from Apple, we
    // include a nonce in the credential request. When signing in with
    // Firebase, the nonce in the id token returned by Apple, is expected to
    // match the sha256 hash of `rawNonce`.
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    // Request credential for the currently signed in Apple account.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
      ],
      nonce: nonce,
    );

    // Create an `OAuthCredential` from the credential returned by Apple.
    return OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );
  }

  static Future<String> signInWithApple() async {
    _log.finer('Call signInWithApple');
    final oauthCredential = await _getAppleOAuthCredential();

    // Sign in the user with Firebase. If the nonce we generated earlier does
    // not match the nonce in `appleCredential.identityToken`, sign in will fail.
    final credential = await _auth.signInWithCredential(oauthCredential);

    if (credential.user == null) {
      _log.severe(
          'ERR! "signInWithApple" signInWithCredential() returned no user.');
      throw Exception('signInWithCredential Failed');
    }

    return credential.user!.uid;
  }
}
