import 'package:flutter/foundation.dart';

/// Where the backend API lives — mirrors the web frontend's own
/// dev/production base-URL resolution (frontend/src/core/api/apiBase.ts).
class ApiConfig {
  ApiConfig._();

  static const String _prodBaseUrl = 'https://api.momcare.solutions';

  /// No local Django dev server exists to point at yet (would need
  /// `manage.py runserver 0.0.0.0:8000` running on a reachable LAN IP,
  /// separate backend-side work with its own go-ahead). Until then, debug
  /// builds hit the same live, deployed API as production — confirmed
  /// already served over real HTTPS, so no cleartext network-security-config
  /// exception is needed. Point this at a real LAN IP once a local backend
  /// exists to develop against without touching the live deploy.
  static const String _devBaseUrl = _prodBaseUrl;

  static String get baseUrl => kReleaseMode ? _prodBaseUrl : _devBaseUrl;
}
