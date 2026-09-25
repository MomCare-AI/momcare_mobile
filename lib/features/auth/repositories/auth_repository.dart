import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

/// A backend rejection with a message worth showing the patient directly —
/// distinct from a network/timeout failure, which the caller should word
/// differently ("check your connection", not a validation complaint).
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Wraps the three "Patient Signup" endpoints from the backend's own
/// Postman collection (MomCare Platform > Patient Signup). Deliberately
/// thin — no retry logic, no caching; each method is one POST, and the
/// caller (AuthNotifier) owns the resulting state.
class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  /// POST /api/auth/patient/register/ — creates an unverified account.
  /// No tokens come back; she still has to verify her email.
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      await _dio.post(
        '/api/auth/patient/register/',
        data: {
          'email': email,
          'password': password,
          'first_name': firstName,
          if (lastName != null && lastName.trim().isNotEmpty)
            'last_name': lastName.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
      );
    } on DioException catch (e) {
      throw AuthException(
        _messageFor(
          e,
          fallback:
              "Couldn't create your account. Check your details and try again.",
        ),
      );
    }
  }

  /// POST /api/auth/patient/verify-email/ — the six-digit code emailed at
  /// registration. Success returns a real access token; this is what
  /// actually signs her in for the first time.
  Future<String> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post(
        '/api/auth/patient/verify-email/',
        data: {'email': email, 'code': code},
      );
      final access = response.data is Map
          ? response.data['access'] as String?
          : null;
      if (access == null) {
        throw const AuthException(
          "Verification succeeded but no session was returned. Please try signing in.",
        );
      }
      return access;
    } on DioException catch (e) {
      // Per the backend's own documented behavior: wrong, expired, already
      // used, or exhausted all return the same generic 400 message,
      // deliberately — which code failed is not information worth handing
      // back to whoever is submitting codes.
      throw AuthException(
        _messageFor(
          e,
          fallback:
              "That code didn't work. It may be wrong, expired, or already used.",
        ),
      );
    }
  }

  /// POST /api/auth/patient/resend-verification/ — always answers as if it
  /// worked (the backend's own anti-enumeration design), so there is no
  /// real "wrong email" error path here, only a network-failure one.
  Future<void> resendVerification({required String email}) async {
    try {
      await _dio.post(
        '/api/auth/patient/resend-verification/',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw AuthException(
        _messageFor(
          e,
          fallback:
              "Couldn't request a new code. Check your connection and try again.",
        ),
      );
    }
  }

  /// DRF's validation errors are typically `{"field": ["message"]}` or
  /// `{"detail": "message"}` — try both shapes before giving up and using
  /// the caller-supplied, honestly generic fallback rather than surfacing
  /// raw JSON.
  String _messageFor(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) return detail;
      for (final value in data.values) {
        if (value is List && value.isNotEmpty && value.first is String) {
          return value.first as String;
        }
        if (value is String && value.trim().isNotEmpty) return value;
      }
    }
    return fallback;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});
