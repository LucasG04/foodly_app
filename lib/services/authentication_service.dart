import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

class AuthenticationService {
  AuthenticationService._();

  static final log = Logger('AuthenticationService');
  static FirebaseAuth _auth = FirebaseAuth.instance;
  static User get currentUser => _auth.currentUser;

  static Stream<User> authenticationStream() {
    log.finer('Stream authStateChanges');
    return _auth.authStateChanges();
  }

  static Future<String> signInUser(String email, String password) async {
    log.finer('Call signInWithEmailAndPassword with $email');
    return (await _auth.signInWithEmailAndPassword(
            email: email, password: password))
        .user
        .uid;
  }

  static Future<String> registerUser(String email, String password) async {
    log.finer('Call createUserWithEmailAndPassword with $email');
    return (await _auth.createUserWithEmailAndPassword(
            email: email, password: password))
        .user
        .uid;
  }

  static Future<void> signOut() async {
    log.finer('Call signOut');
    return _auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    log.finer('Call resetPassword with $email');
    return _auth.sendPasswordResetEmail(email: email);
  }
}
