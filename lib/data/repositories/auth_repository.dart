import 'package:firebase_auth/firebase_auth.dart';
import '../datasources/local/secure_storage_service.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final SecureStorageService _storage = SecureStorageService();

  Stream<User?> get user => _firebaseAuth.authStateChanges();

  Future<void> login(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // saving token Firebase
    final token = await credential.user?.getIdToken();

    if (token != null) {
      await _storage.saveToken(token);
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _storage.deleteToken();
  }

  Future<bool> hasToken() async {
    final token = await _storage.getToken();
    return token != null;
  }
}
