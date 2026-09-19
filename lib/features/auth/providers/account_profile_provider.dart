import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session-local account info only — no backend, no persistence across app
/// restarts. Exists because AuthScreen's own registration form already
/// collects a name and email but discards them on submit (see its _submit()
/// comments); this gives Settings' Account & Security something real, if
/// limited, to show and edit instead of a static placeholder.
class AccountProfile {
  const AccountProfile({this.fullName = '', this.email = ''});

  final String fullName;
  final String email;

  bool get isEmpty => fullName.isEmpty && email.isEmpty;

  AccountProfile copyWith({String? fullName, String? email}) {
    return AccountProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
    );
  }
}

class AccountProfileNotifier extends StateNotifier<AccountProfile> {
  AccountProfileNotifier() : super(const AccountProfile());

  void update({required String fullName, required String email}) {
    state = state.copyWith(fullName: fullName, email: email);
  }

  /// Used by Delete Account — clears back to empty, same shape as a fresh
  /// app launch. Not a real account deletion (nothing exists to delete);
  /// this only clears the local, in-memory state this provider holds.
  void clear() {
    state = const AccountProfile();
  }
}

final accountProfileProvider =
    StateNotifierProvider<AccountProfileNotifier, AccountProfile>((ref) {
      return AccountProfileNotifier();
    });
