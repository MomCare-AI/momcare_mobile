import 'package:flutter/material.dart';

/// Synced to the web app's own locked brand palette (frontend's
/// `src/app/portal.css` — the clinical portal design system, not the
/// marketing landing page, since that's the same "product" mood this app
/// shares). Token *names* here predate that sync and stay put so no
/// consumer code needs to change; only the values were brought in line.
/// The onboarding "Get Started" screen is deliberately excluded — it uses
/// its own raw `Colors.pink`/`Colors.black`, not these tokens, by design.
class AppColors {
  AppColors._();

  // --- Core Brand Colors ---
  /// Brand blue — matches portal.css's --c-teal (#4662e8). The web brand
  /// itself moved off teal/green to this blue in its own 2026 color-system
  /// pass; this was previously a Deep Teal (#08695D) never carried over.
  static const primary = Color(0xFF4662E8);
  static const primaryHover = Color(0xFF3B56D4);
  static const primaryActive = Color(0xFF5B73EC);

  /// White - Used for cards and surfaces.
  static const surface = Color(0xFFFFFFFF);

  /// Soft Background - App-wide background color to reduce eye strain.
  /// Matches portal.css's --c-ground.
  static const background = Color(0xFFF6F8F9);

  // --- Text Colors ---
  /// Primary Text - matches portal.css's --c-ink.
  static const textPrimary = Color(0xFF193B4D);

  /// Secondary Text - matches portal.css's --c-body.
  static const textSecondary = Color(0xFF607582);

  // --- Functional / Legacy Aliases ---
  // These are kept to ensure old screens don't break during the transition.
  static const ink = textPrimary;
  static const body = textSecondary;

  /// Matches portal.css's --c-border.
  static const border = Color(0xFFE2E9EC);

  // Status colors — matches portal.css's clinical-state tokens (muted,
  // professional tones; meaning only, never decoration — see that file's
  // own note on why these aren't more saturated).
  static const stable = Color(0xFF2F8A72);
  static const moderate = Color(0xFFC98A2E);
  static const high = Color(0xFFD65F58);

  // Legacy mappings from previous iterations
  static const brand = primary;

  /// A light brand-tinted wash for icon backgrounds/soft highlights —
  /// matches portal.css's --c-teal-wash. Previously aliased straight to
  /// `background` (a plain neutral gray), which made call sites asking for
  /// a "wash" get no tint at all.
  static const brandWash = Color(0xFFEEF1FF);

  /// Matches portal.css's --c-surface-subtle.
  static const surfaceSubtle = Color(0xFFEFF3F4);

  /// Muted caption/meta-text color — matches portal.css's dedicated
  /// --c-faint. Previously aliased to `border`, which is a near-white gray
  /// meant for hairlines, not text; anything using this for icon or label
  /// color was rendering close to invisible on a white surface.
  static const faint = Color(0xFF677783);
  static const accentRed = high;

  /// Matches portal.css's --c-coral accent. Previously a standalone pink
  /// (#FDA4AF) with no web equivalent — the web has no pink in its brand
  /// system, only this coral. Name kept for backward compatibility (same
  /// pattern as `primaryPurple` below).
  static const accentPink = Color(0xFFF28C82);
  static const accentSage = Color(0xFF86EFAC);
  static const primaryPurple =
      primary; // Remapped the old purple FAB to the new brand blue
}
