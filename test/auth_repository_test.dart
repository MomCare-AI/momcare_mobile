import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:momcare_mobile/features/auth/repositories/auth_repository.dart';

/// Same minimal fake adapter shape as real_hospitals_provider_test.dart —
/// dio exposes this seam itself, no mocking package needed.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter.json(Map<String, dynamic> body, {int statusCode = 200})
    : _statusCode = statusCode,
      _text = jsonEncode(body);

  _FakeAdapter.error(int statusCode, Map<String, dynamic> body)
    : _statusCode = statusCode,
      _text = jsonEncode(body);

  final int _statusCode;
  final String _text;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      _text,
      _statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('AuthRepository.register', () {
    test('succeeds silently on 201', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter.json({}, statusCode: 201);
      final repo = AuthRepository(dio);

      await repo.register(
        email: 'ayesha@example.test',
        password: 'HerOwnPick!2026',
        firstName: 'Ayesha',
      );
      // No exception thrown is the assertion.
    });

    test('surfaces a field-level validation message on 400', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter.error(400, {
          'email': ['This field must be unique.'],
        });
      final repo = AuthRepository(dio);

      await expectLater(
        repo.register(
          email: 'ayesha@example.test',
          password: 'HerOwnPick!2026',
          firstName: 'Ayesha',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'This field must be unique.',
          ),
        ),
      );
    });
  });

  group('AuthRepository.verifyEmail', () {
    test('returns the access token on success', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter.json({'access': 'a-real-jwt'});
      final repo = AuthRepository(dio);

      final token = await repo.verifyEmail(
        email: 'ayesha@example.test',
        code: '123456',
      );

      expect(token, 'a-real-jwt');
    });

    test('throws the generic wrong/expired/used message on 400', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter.error(400, {
          'detail': 'Invalid or expired code.',
        });
      final repo = AuthRepository(dio);

      await expectLater(
        repo.verifyEmail(email: 'ayesha@example.test', code: '000000'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthRepository.resendVerification', () {
    test('succeeds silently on 200', () async {
      final dio = Dio()..httpClientAdapter = _FakeAdapter.json({});
      final repo = AuthRepository(dio);

      await repo.resendVerification(email: 'ayesha@example.test');
    });
  });
}
