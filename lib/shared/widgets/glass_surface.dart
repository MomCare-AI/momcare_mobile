import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_gradients.dart';

/// The one frosted-glass container used everywhere a card, panel, or sheet
/// is needed — backdrop blur + a translucent white gradient fill + a soft
/// white border, designed to sit on top of [AppGradients.background].
/// Changing the glass look app-wide means editing this file, not each
/// screen that uses it.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.opacity = 0.55,
    this.blurSigma = 18,
    this.tint,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double opacity;
  final double blurSigma;

  /// Optional semantic tint (e.g. amber for a caution notice) blended into
  /// the glass fill — keeps meaning-carrying colors distinguishable while
  /// staying visually consistent with the rest of the glass UI.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: AppGradients.glassTint(opacity: opacity, tint: tint),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          // RepaintBoundary works around a real rendering bug found on a
          // budget test device (Infinix X6525D, entry-level GPU): an
          // Image.asset child painted directly under BackdropFilter came
          // out completely invisible while text/icon children on the same
          // screen rendered fine — a known Skia/driver interaction where
          // BackdropFilter can fail to composite a raster image child.
          // Forcing the child into its own compositing layer fixes it.
          child: RepaintBoundary(child: child),
        ),
      ),
    );
  }
}
