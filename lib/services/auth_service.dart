import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'Account nahi mila';
      if (e.code == 'wrong-password') return 'Password galat hai';
      return 'Error: ${e.message}';
    }
  }

  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') return 'Password zyada strong banao';
      if (e.code == 'email-already-in-use') return 'Email already use mein hai';
      return 'Error: ${e.message}';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}