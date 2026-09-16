import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';

enum GlassButtonVariant { primary, outlined }

/// Replaces ElevatedButton/OutlinedButton across the app for the
/// glassmorphism redesign. [GlassButtonVariant.primary] fills with the
/// blue → red brand gradient; [GlassButtonVariant.outlined] is a frosted,
/// mostly-transparent pill for secondary actions. Wrap in
/// `SizedBox(width: double.infinity, child: GlassButton(...))` for a
/// full-width button, same as the ElevatedButton pattern it replaces.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = GlassButtonVariant.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final GlassButtonVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == GlassButtonVariant.primary;
    final textColor = isPrimary ? Colors.white : AppColors.ink;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              decoration: BoxDecoration(
                gradient: isPrimary
                    ? AppGradients.primaryButton
                    : AppGradients.glassTint(opacity: 0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isPrimary ? 0.5 : 0.7),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: textColor),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
