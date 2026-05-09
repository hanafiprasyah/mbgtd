import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/datasources/local/secure_storage_service.dart';

class TokenService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SecureStorageService _storage = SecureStorageService();

  Timer? _refreshTimer;

  /// Start monitoring token lifecycle
  void start() {
    _scheduleRefresh();
  }

  void stop() {
    _refreshTimer?.cancel();
  }

  void _scheduleRefresh() async {
    final user = _auth.currentUser;

    if (user == null) return;

    final idTokenResult = await user.getIdTokenResult();

    final expiration = idTokenResult.expirationTime;

    if (expiration == null) return;

    final now = DateTime.now();
    final difference = expiration.difference(now);

    // refresh 5 minute before expired
    final refreshTime = difference - const Duration(minutes: 5);

    _refreshTimer?.cancel();

    _refreshTimer = Timer(refreshTime, () async {
      await _refreshToken();
    });
  }

  Future<void> _refreshToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final newToken = await user.getIdToken(true);

      if (newToken != null) {
        await _storage.saveToken(newToken);
        _scheduleRefresh(); // loop
      }
    } catch (e) {
      // logout on refresh failure
      await _auth.signOut();
      await _storage.deleteToken();
    }
  }
}
