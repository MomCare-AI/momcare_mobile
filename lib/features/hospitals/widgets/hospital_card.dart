import 'package:flutter/material.dart';

import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/glass_surface.dart';
import '../../../theme/app_colors.dart';

/// Generic on purpose — used both for MomCare's own sample hospitals and
/// for real OpenStreetMap results (`RealHospital`), which have no MomCare
/// account and so need a different action (directions, not "join").
class HospitalCard extends StatelessWidget {
  const HospitalCard({
    super.key,
    required this.name,
    required this.address,
    this.distanceKm,
    this.onTap,
    this.actionLabel = 'View details',
    this.onActionPressed,
  });

  final String name;
  final String address;
  final double? distanceKm;
  final VoidCallback? onTap;
  final String actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final distanceText = distanceKm != null
        ? '${distanceKm!.toStringAsFixed(1)} km away · '
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: GlassSurface(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$distanceText$address',
                style: const TextStyle(color: AppColors.faint, fontSize: 13),
              ),
              if (onActionPressed != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    label: actionLabel,
                    variant: GlassButtonVariant.outlined,
                    onPressed: onActionPressed!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
