import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The blue → white → red gradient behind every screen in the glassmorphism
/// redesign, and the translucent tint every [GlassSurface]/[GlassButton]
/// fills with. One place to change the look app-wide.
class AppGradients {
  AppGradients._();

  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brand, Color(0xFFF3F6FF), AppColors.accentRed],
    stops: [0.0, 0.55, 1.0],
  );

  static const primaryButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.brand, AppColors.accentRed],
  );

  /// White-forward translucent fill for frosted glass surfaces. [opacity]
  /// controls how see-through the glass is; [tint] optionally blends in a
  /// semantic color (e.g. amber for a caution card) without losing the
  /// glass look.
  static LinearGradient glassTint({double opacity = 0.55, Color? tint}) {
    final base = tint ?? Colors.white;
    final high = (opacity + 0.2).clamp(0.0, 1.0);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.alphaBlend(
          base.withValues(alpha: tint != null ? 0.35 : 0),
          Colors.white,
        ).withValues(alpha: high),
        Color.alphaBlend(
          base.withValues(alpha: tint != null ? 0.35 : 0),
          Colors.white,
        ).withValues(alpha: opacity),
      ],
    );
  }
}
