import 'package:flutter/material.dart';

import '../../theme/app_gradients.dart';

/// Full-bleed blue → white → red gradient behind a screen's content — the
/// backdrop every [GlassSurface] and [GlassButton] is designed to sit on.
/// Used as the outermost widget inside each screen's Scaffold body.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: child,
    );
  }
}
