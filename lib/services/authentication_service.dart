import 'package:firebase_auth/firebase_auth.dart';

class AuthenticationService {
  AuthenticationService._();

  static FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<User> authenticationStream() {
    return _auth.authStateChanges();
  }

  static Future<String> signInUser(
      String name, String password, String planCode) async {
    final email = '$name@$planCode.io';
    return (await _auth.signInWithEmailAndPassword(
            email: email, password: password))
        .user
        .uid;
  }

  static Future<String> registerUser(
      String name, String password, String planCode) async {
    final email = '$name@$planCode.io';

    return (await _auth.createUserWithEmailAndPassword(
            email: email, password: password))
        .user
        .uid;
  }
}
