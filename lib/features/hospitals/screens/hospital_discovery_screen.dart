import 'package:flutter/material.dart';

import '../../../shared/widgets/gradient_background.dart';
import '../../../theme/app_colors.dart';
import '../models/hospital.dart';
import '../widgets/hospital_card.dart';
import '../widgets/map_placeholder.dart';

class HospitalDiscoveryScreen extends StatelessWidget {
  const HospitalDiscoveryScreen({super.key});

  static const path = '/guest/hospitals';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Find Nearby Hospitals'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
      ),
      body: GradientBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + kToolbarHeight + 16,
            20,
            20,
          ),
          children: [
            const MapPlaceholder(),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search hospitals',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            for (final hospital in sampleHospitals) HospitalCard(hospital: hospital),
          ],
        ),
      ),
    );
  }
}
