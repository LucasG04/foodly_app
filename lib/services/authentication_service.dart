import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationService {
  AuthenticationService._();

  static FirebaseAuth _auth = FirebaseAuth.instance;

  static User get currentUser => _auth.currentUser;

  static Stream<User> authenticationStream() {
    return _auth.authStateChanges();
  }

  static Future<String> signInUser(String email, String password) async {
    return (await _auth.signInWithEmailAndPassword(
            email: email, password: password))
        .user
        .uid;
  }

  static Future<String> registerUser(String email, String password) async {
    return (await _auth.createUserWithEmailAndPassword(
            email: email, password: password))
        .user
        .uid;
  }

  static Future<void> signOut() async {
    return _auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    return _auth.sendPasswordResetEmail(email: email);
  }
}
