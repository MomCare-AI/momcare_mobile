import 'package:flutter/foundation.dart';

/// Where the backend API lives — mirrors the web frontend's own
/// dev/production base-URL resolution (frontend/src/core/api/apiBase.ts).
class ApiConfig {
  ApiConfig._();

  static const String _prodBaseUrl = 'https://api.momcare.solutions';

  /// 10.0.2.2 is the Android emulator's alias for the host machine's own
  /// localhost. A real physical device on the same network needs the
  /// host's actual LAN IP instead — not solved yet, since there's no
  /// feature that actually calls the API yet to need it.
  static const String _devBaseUrl = 'http://10.0.2.2:8000';

  static String get baseUrl => kReleaseMode ? _prodBaseUrl : _devBaseUrl;
}
