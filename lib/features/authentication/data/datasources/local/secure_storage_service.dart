import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  static const _keyToken = 'auth_token';

  // Save token to secure storage
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  // Retrieve token from secure storage
  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  // Delete token from secure storage
  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }
}
