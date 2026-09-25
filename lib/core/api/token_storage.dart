import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keychain/Keystore-backed access-token storage — the first real use of
/// `flutter_secure_storage` in this app (declared as a dependency from the
/// start, unused until the first real auth flow needed it).
///
/// Only the access token lives here. The refresh token the backend issues
/// is an HttpOnly cookie (a browser-session mechanism) — a mobile client
/// needs its own cookie-jar handling to use it, which is a deliberate,
/// separate piece of work for whenever token refresh / "stay signed in
/// past the access token's own lifetime" is actually built. Until then, an
/// expired access token just means signing in again.
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'auth_access_token';

  Future<void> saveAccessToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> clear() {
    return _storage.delete(key: _accessTokenKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(const FlutterSecureStorage());
});
