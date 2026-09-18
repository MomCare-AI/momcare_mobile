import 'package:flutter/material.dart';
import 'primary_button.dart';

enum GlassButtonVariant { primary, secondary, outlined }

/// DEPRECATED: Use PrimaryButton instead.
/// This is a shim to prevent compilation errors during the UX migration.
class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final GlassButtonVariant variant;
  final bool isLoading;

  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GlassButtonVariant.primary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: label,
      onPressed: isLoading ? () {} : onPressed,
      isDestructive: false,
    );
  }
}
