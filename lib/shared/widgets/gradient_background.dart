import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// DEPRECATED: Use standard Scaffold backgroundColor instead.
/// This is a shim to prevent compilation errors during the UX migration.
class GradientBackground extends StatelessWidget {
  final Widget child;
  
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: child,
    );
  }
}
