import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mbg_test/features/authentication/data/datasources/local/secure_storage_service.dart';

class TokenService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SecureStorageService _storage = SecureStorageService();

  /// calculates the duration until the next token refresh is needed
  Future<Duration> getNextRefreshDuration() async {
    final user = _auth.currentUser;
    if (user == null) return const Duration(minutes: 1);

    final result = await user.getIdTokenResult();
    final expiry = result.expirationTime;

    if (expiry == null) return const Duration(minutes: 1);

    final now = DateTime.now();
    final diff = expiry.difference(now);

    // refresh 5 min before token expired
    final refreshTime = diff - const Duration(minutes: 5);

    if (refreshTime.isNegative) {
      // fallback
      return const Duration(seconds: 10);
    }

    return refreshTime;
  }

  /// refresh + retry mechanism
  Future<bool> refreshTokenWithRetry({int maxRetry = 3}) async {
    int attempt = 0;
    int delaySeconds = 5;

    // retry loop with exponential backoff
    while (attempt < maxRetry) {
      try {
        final user = _auth.currentUser;
        if (user == null) return false;

        final token = await user.getIdToken(true);

        if (token != null) {
          await _storage.saveToken(token);
          return true;
        }
      } catch (_) {
        // retry on any error (network, server, etc.)
      }

      await Future.delayed(Duration(seconds: delaySeconds));
      // exponential backoff
      delaySeconds *= 2;
      attempt++;
    }

    // logout if total failure
    await _auth.signOut();
    await _storage.deleteToken();

    return false;
  }
}
