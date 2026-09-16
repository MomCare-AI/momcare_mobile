import 'package:flutter/material.dart';

import '../shared/widgets/glass_surface.dart';
import '../shared/widgets/gradient_background.dart';
import '../theme/app_colors.dart';

/// Stands in for the real login/dashboard flow until Phase 1 (see
/// docs/patient-app-plan.md) is built against Ahmed's real endpoints.
/// Deliberately says so rather than faking a screen that doesn't work yet.
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  static const path = '/home';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: GlassSurface(
                borderRadius: 24,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.construction_rounded,
                      color: AppColors.brand,
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Basic structure only',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The invite-based login and the read-only dashboard '
                      '(pregnancy status, risk level, vitals, alerts, care team) '
                      'come next, once the backend endpoints in '
                      'docs/patient-app-plan.md exist.',
                      style: TextStyle(color: AppColors.body, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
