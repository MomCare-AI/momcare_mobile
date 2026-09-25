import 'package:flutter_test/flutter_test.dart';

import 'package:momcare_mobile/core/api/token_storage.dart';
import 'package:momcare_mobile/features/auth/providers/auth_provider.dart';
import 'package:momcare_mobile/features/auth/repositories/auth_repository.dart';

/// Fakes both collaborators directly rather than going through Dio/secure
/// storage — AuthNotifier's own orchestration (state transitions, what it
/// does with a returned token) is what these tests check, not the network
/// or platform-channel layers underneath, which are covered separately in
/// auth_repository_test.dart.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository();

  bool registerShouldFail = false;
  bool verifyShouldFail = false;
  bool resendShouldFail = false;
  String tokenToReturn = 'a-real-jwt';
  int resendCallCount = 0;

  @override
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
    String? phone,
  }) async {
    if (registerShouldFail) {
      throw const AuthException('Couldn\'t create your account.');
    }
  }

  @override
  Future<String> verifyEmail({
    required String email,
    required String code,
  }) async {
    if (verifyShouldFail) {
      throw const AuthException("That code didn't work.");
    }
    return tokenToReturn;
  }

  @override
  Future<void> resendVerification({required String email}) async {
    resendCallCount++;
    if (resendShouldFail) {
      throw const AuthException('Could not resend.');
    }
  }
}

class _FakeTokenStorage implements TokenStorage {
  String? saved;

  @override
  Future<void> saveAccessToken(String token) async {
    saved = token;
  }

  @override
  Future<String?> readAccessToken() async => saved;

  @override
  Future<void> clear() async {
    saved = null;
  }
}

void main() {
  late _FakeAuthRepository repository;
  late _FakeTokenStorage tokenStorage;
  late AuthNotifier notifier;

  setUp(() {
    repository = _FakeAuthRepository();
    tokenStorage = _FakeTokenStorage();
    notifier = AuthNotifier(repository, tokenStorage);
  });

  group('register', () {
    test(
      'moves to awaitingVerification and remembers the email on success',
      () async {
        final result = await notifier.register(
          email: 'ayesha@example.test',
          password: 'HerOwnPick!2026',
          firstName: 'Ayesha',
        );

        expect(result, isTrue);
        expect(notifier.state.status, AuthStatus.awaitingVerification);
        expect(notifier.state.pendingEmail, 'ayesha@example.test');
      },
    );

    test('moves to error with the repository message on failure', () async {
      repository.registerShouldFail = true;

      final result = await notifier.register(
        email: 'ayesha@example.test',
        password: 'HerOwnPick!2026',
        firstName: 'Ayesha',
      );

      expect(result, isFalse);
      expect(notifier.state.status, AuthStatus.error);
      expect(notifier.state.errorMessage, "Couldn't create your account.");
    });
  });

  group('verifyEmail', () {
    test('does nothing if there is no pending email', () async {
      final result = await notifier.verifyEmail(code: '123456');
      expect(result, isFalse);
      expect(notifier.state.status, AuthStatus.idle);
    });

    test('saves the token and becomes authenticated on success', () async {
      await notifier.register(
        email: 'ayesha@example.test',
        password: 'HerOwnPick!2026',
        firstName: 'Ayesha',
      );

      final result = await notifier.verifyEmail(code: '123456');

      expect(result, isTrue);
      expect(notifier.state.status, AuthStatus.authenticated);
      expect(tokenStorage.saved, 'a-real-jwt');
    });

    test(
      'returns to awaitingVerification with an error on a bad code',
      () async {
        await notifier.register(
          email: 'ayesha@example.test',
          password: 'HerOwnPick!2026',
          firstName: 'Ayesha',
        );
        repository.verifyShouldFail = true;

        final result = await notifier.verifyEmail(code: '000000');

        expect(result, isFalse);
        expect(notifier.state.status, AuthStatus.awaitingVerification);
        expect(notifier.state.errorMessage, "That code didn't work.");
        expect(
          tokenStorage.saved,
          isNull,
          reason: 'a failed verification must never store a token',
        );
      },
    );
  });

  group('resendVerification', () {
    test('calls the repository with the pending email', () async {
      await notifier.register(
        email: 'ayesha@example.test',
        password: 'HerOwnPick!2026',
        firstName: 'Ayesha',
      );

      final result = await notifier.resendVerification();

      expect(result, isTrue);
      expect(repository.resendCallCount, 1);
    });

    test('does nothing if there is no pending email', () async {
      final result = await notifier.resendVerification();
      expect(result, isFalse);
      expect(repository.resendCallCount, 0);
    });
  });
}
