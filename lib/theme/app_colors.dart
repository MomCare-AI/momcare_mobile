import 'package:flutter/material.dart';

/// Premium, calm, and clinically trustworthy palette for MomCare.
class AppColors {
  AppColors._();

  // --- Core Brand Colors ---
  /// Deep Teal - Primary brand color, conveys trust and medical professionalism.
  static const primary = Color(0xFF08695D);

  /// White - Used for cards and surfaces.
  static const surface = Color(0xFFFFFFFF);

  /// Soft Background - App-wide background color to reduce eye strain.
  static const background = Color(0xFFF5F7F9);

  // --- Text Colors ---
  /// Primary Text - High contrast dark blue-grey for main content.
  static const textPrimary = Color(0xFF1A2B3C);

  /// Secondary Text - Subdued color for descriptions, timestamps, and subtitles.
  static const textSecondary = Color(0xFF6B7A8B);

  // --- Functional / Legacy Aliases ---
  // These are kept to ensure old screens don't break during the transition.
  static const ink = textPrimary;
  static const body = textSecondary;
  static const border = Color(0xFFE2E8F0);

  // Status colors
  static const stable = Color(0xFF10B981); // Emerald
  static const moderate = Color(0xFFF59E0B); // Amber
  static const high = Color(0xFFEF4444); // Red

  // Legacy mappings from previous iterations
  static const brand = primary;
  static const brandWash = background;
  static const surfaceSubtle = background;
  static const faint = border;
  static const accentRed = high;
  static const accentPink = Color(0xFFFDA4AF);
  static const accentSage = Color(0xFF86EFAC);
  static const primaryPurple =
      primary; // Remapped the old purple FAB to the new Deep Teal
}
