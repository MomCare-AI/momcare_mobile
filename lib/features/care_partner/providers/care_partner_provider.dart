import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CarePartnerStatus { none, invited }

/// Session-local invitation state only — no backend, no persistence across
/// app restarts, no second account. There is nothing here representing a
/// real care partner accepting anything; this only tracks whether *this*
/// device has generated a local invitation code.
class CarePartnerState {
  const CarePartnerState({
    this.status = CarePartnerStatus.none,
    this.invitationCode,
  });

  final CarePartnerStatus status;
  final String? invitationCode;

  bool get hasActiveInvitation =>
      status == CarePartnerStatus.invited && invitationCode != null;
}

class CarePartnerNotifier extends StateNotifier<CarePartnerState> {
  CarePartnerNotifier() : super(const CarePartnerState());

  void createInvitation() {
    state = CarePartnerState(
      status: CarePartnerStatus.invited,
      invitationCode: _generateCode(),
    );
  }

  /// Clears back to the empty state — same shape as before any invitation
  /// existed. Nothing is cancelled on a server; there is no server.
  void cancelInvitation() {
    state = const CarePartnerState();
  }

  // Excludes visually ambiguous characters (0/O, 1/I) so the code is easy to
  // read and type back in if ever needed. Randomly generated per call, not
  // hardcoded — but this is a local demo code, never a real backend token.
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    final suffix = List.generate(
      5,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    return 'MOM-$suffix';
  }
}

final carePartnerProvider =
    StateNotifierProvider<CarePartnerNotifier, CarePartnerState>((ref) {
      return CarePartnerNotifier();
    });
