import 'package:flutter/material.dart';

/// Mirrors the locked design tokens in `frontend/src/app/portal.css`.
/// Keep these two files in sync by hand — there is no shared source yet.
class AppColors {
  AppColors._();

  static const brand = Color(0xFF4662E8);
  static const brandHover = Color(0xFF3B56D4);
  static const brandActive = Color(0xFF5B73EC);
  static const brandWash = Color(0xFFEEF1FF);

  static const ink = Color(0xFF193B4D);
  static const body = Color(0xFF607582);
  static const faint = Color(0xFF677783);

  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFEFF3F4);
  static const border = Color(0xFFE2E9EC);
  static const borderSoft = Color(0xFFE8EEF0);

  static const stable = Color(0xFF2F8A72);
  static const stableSoft = Color(0xFFEAF5F1);
  static const stableBorder = Color(0xFFCBE8DD);

  static const moderate = Color(0xFFC98A2E);
  static const moderateSoft = Color(0xFFFFF5E3);
  static const moderateBorder = Color(0xFFF1D9A8);

  static const high = Color(0xFFD65F58);
  static const highSoft = Color(0xFFFCEDEC);
  static const highBorder = Color(0xFFF2C7C4);

  static const critical = Color(0xFFB94343);
  static const criticalSoft = Color(0xFFFBE5E5);
  static const criticalBorder = Color(0xFFEBC0C0);

  /// Decorative accent for the app-wide glassmorphism gradient background
  /// (blue → white → red). Deliberately a distinct color from
  /// [critical]/[high] — those carry clinical risk meaning on vitals/alerts
  /// screens and must never be reused for a purely decorative gradient.
  static const accentRed = Color(0xFFFF6B6B);
}
