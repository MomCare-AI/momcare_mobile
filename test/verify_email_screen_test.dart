import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:momcare_mobile/core/api/token_storage.dart';
import 'package:momcare_mobile/features/auth/providers/auth_provider.dart';
import 'package:momcare_mobile/features/auth/repositories/auth_repository.dart';
import 'package:momcare_mobile/features/auth/screens/verify_email_screen.dart';

/// Seeds a chosen outcome without ever touching Dio/secure storage —
/// this screen's own wiring (form validation, error display, navigation
/// on success) is what these tests check, not the network layer, which is
/// covered separately in auth_repository_test.dart / auth_provider_test.dart.
class _FakeAuthRepository implements AuthRepository {
  bool verifyShouldFail = false;

  @override
  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
    String? phone,
  }) async {}

  @override
  Future<String> verifyEmail({
    required String email,
    required String code,
  }) async {
    if (verifyShouldFail) {
      throw const AuthException(
        "That code didn't work. It may be wrong, expired, or already used.",
      );
    }
    return 'a-real-jwt';
  }

  @override
  Future<void> resendVerification({required String email}) async {}
}

class _FakeTokenStorage implements TokenStorage {
  @override
  Future<void> saveAccessToken(String token) async {}

  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<void> clear() async {}
}

void main() {
  Widget wrap({required AuthRepository repository}) {
    final router = GoRouter(
      initialLocation: '/verify',
      routes: [
        GoRoute(
          path: '/verify',
          builder: (context, state) =>
              const VerifyEmailScreen(email: 'ayesha@example.test'),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              const Scaffold(body: Text('Home Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        // Seeded as "just registered, waiting for the code" — the real
        // state the screen is always reached in, since register() is what
        // sets pendingEmail. Passing `email` to the widget only controls
        // the display text; verifyEmail()/resendVerification() on the
        // notifier act on pendingEmail, not the widget's constructor arg.
        authProvider.overrideWith((ref) {
          final notifier = AuthNotifier(repository, _FakeTokenStorage());
          notifier.state = notifier.state.copyWith(
            status: AuthStatus.awaitingVerification,
            pendingEmail: 'ayesha@example.test',
          );
          return notifier;
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('shows the email the code was sent to', (tester) async {
    await tester.pumpWidget(wrap(repository: _FakeAuthRepository()));

    expect(find.textContaining('ayesha@example.test'), findsOneWidget);
  });

  testWidgets('rejects a code that is not 6 digits', (tester) async {
    await tester.pumpWidget(wrap(repository: _FakeAuthRepository()));

    await tester.enterText(find.byType(TextFormField), '123');
    await tester.tap(find.text('Verify'));
    await tester.pump();

    expect(find.text('Enter the 6-digit code'), findsOneWidget);
  });

  testWidgets('a correct code navigates to home', (tester) async {
    await tester.pumpWidget(wrap(repository: _FakeAuthRepository()));

    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.text('Home Screen'), findsOneWidget);
  });

  testWidgets('a wrong code shows the honest generic error and stays put', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(repository: _FakeAuthRepository()..verifyShouldFail = true),
    );

    await tester.enterText(find.byType(TextFormField), '000000');
    await tester.tap(find.text('Verify'));
    await tester.pump();

    expect(
      find.text(
        "That code didn't work. It may be wrong, expired, or already used.",
      ),
      findsOneWidget,
    );
    expect(find.text('Home Screen'), findsNothing);
  });
}
