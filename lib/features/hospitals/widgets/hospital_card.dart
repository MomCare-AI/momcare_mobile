import 'package:flutter/material.dart';

import '../../../shared/widgets/account_required_gate.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/glass_surface.dart';
import '../../../theme/app_colors.dart';
import '../models/hospital.dart';

class HospitalCard extends StatelessWidget {
  const HospitalCard({super.key, required this.hospital});

  final Hospital hospital;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassSurface(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hospital.name,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${hospital.distanceLabel} · ${hospital.address}',
              style: const TextStyle(color: AppColors.faint, fontSize: 13),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                label: 'Request to Join',
                variant: GlassButtonVariant.outlined,
                onPressed: () => showAccountRequiredGate(
                  context,
                  message:
                      'Create an account to request joining ${hospital.name}.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
