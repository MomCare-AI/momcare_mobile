import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Airbnb-style distance pill: what the map shows before you tap anything.
class DistancePill extends StatelessWidget {
  const DistancePill({
    super.key,
    required this.distanceKm,
    required this.isSelected,
  });

  final double distanceKm;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final label = '${distanceKm.toStringAsFixed(1)} km';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.black87,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}
