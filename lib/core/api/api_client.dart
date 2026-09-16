import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';

/// The shared Dio instance every repository will use once there's a real
/// endpoint to call. Deliberately minimal — no auth-token interceptor yet
/// (mirroring the web's authFetch.ts attach-token/refresh-on-401 pattern),
/// since there's no login flow yet to test that behavior against. Add it
/// alongside the auth feature, not ahead of it.
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
});
