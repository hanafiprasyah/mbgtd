import 'package:firebase_auth/firebase_auth.dart';
import 'package:mbg_test/data/datasources/local/secure_storage_service.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final SecureStorageService _storage = SecureStorageService();

  // Expose the user stream
  Stream<User?> get user => _firebaseAuth.authStateChanges();

  // Login method
  Future<void> login(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // saving token Firebase
    final token = await credential.user?.getIdToken();

    // Save the token to secure storage
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
