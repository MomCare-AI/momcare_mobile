import 'package:flutter/material.dart';
import 'clinical_card.dart';

/// DEPRECATED: Use ClinicalCard instead.
/// This is a shim to prevent compilation errors during the UX migration.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final dynamic borderRadius;
  final dynamic opacity;
  final dynamic tint;
  
  const GlassSurface({
    super.key, 
    required this.child,
    this.padding = const EdgeInsets.all(24.0),
    this.borderRadius,
    this.opacity,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return ClinicalCard(
      padding: padding,
      child: child,
    );
  }
}
