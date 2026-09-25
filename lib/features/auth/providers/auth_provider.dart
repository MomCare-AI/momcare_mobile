import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/token_storage.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus {
  idle,
  submittingRegister,
  awaitingVerification,
  verifying,
  authenticated,
  error,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.idle,
    this.pendingEmail,
    this.errorMessage,
  });

  final AuthStatus status;

  /// The address currently going through verification — carried from a
  /// successful register() into verifyEmail()/resendVerification() so the
  /// verify-email screen doesn't need to pass it around separately.
  final String? pendingEmail;
  final String? errorMessage;

  /// errorMessage is not preserved across transitions unless explicitly
  /// re-passed — same shape as RealHospitalsState.copyWith, so a fresh
  /// attempt doesn't carry a stale error into a new loading/success state.
  AuthState copyWith({
    AuthStatus? status,
    String? pendingEmail,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      errorMessage: errorMessage,
    );
  }
}

/// Real backend auth — distinct from accountProfileProvider, which is
/// deliberately local/session-only placeholder data for Settings. This one
/// actually calls Ahmed's API and stores a real access token.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository, this._tokenStorage) : super(const AuthState());

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    String? lastName,
    String? phone,
  }) async {
    state = state.copyWith(status: AuthStatus.submittingRegister);
    try {
      await _repository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      state = state.copyWith(
        status: AuthStatus.awaitingVerification,
        pendingEmail: email,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Check your connection and try again.',
      );
      return false;
    }
  }

  Future<bool> verifyEmail({required String code}) async {
    final email = state.pendingEmail;
    if (email == null) return false;
    state = state.copyWith(status: AuthStatus.verifying);
    try {
      final accessToken = await _repository.verifyEmail(
        email: email,
        code: code,
      );
      await _tokenStorage.saveAccessToken(accessToken);
      state = state.copyWith(status: AuthStatus.authenticated);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.awaitingVerification,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.awaitingVerification,
        errorMessage: 'Check your connection and try again.',
      );
      return false;
    }
  }

  /// Always reports success on the happy path — the backend itself always
  /// answers 200 regardless of whether the email had a pending signup
  /// (anti-enumeration, its own documented behavior), so there is nothing
  /// more specific to report back here either.
  Future<bool> resendVerification() async {
    final email = state.pendingEmail;
    if (email == null) return false;
    try {
      await _repository.resendVerification(email: email);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Check your connection and try again.',
      );
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(tokenStorageProvider),
  );
});
