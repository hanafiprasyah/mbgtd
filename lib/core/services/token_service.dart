import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/datasources/local/secure_storage_service.dart';

class TokenService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SecureStorageService _storage = SecureStorageService();

  Future<void> refreshToken() async {
    try {
      final user = _auth.currentUser;

      if (user == null) return;

      final token = await user.getIdToken(true);

      if (token != null) {
        await _storage.saveToken(token);
      }
    } catch (e) {
      // refresh failed? logout.
      await _auth.signOut();
      await _storage.deleteToken();
    }
  }
}
