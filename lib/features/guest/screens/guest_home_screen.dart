import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/glass_surface.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../theme/app_colors.dart';
import '../../auth/screens/auth_screen.dart';
import '../../exercise/screens/exercise_screen.dart';
import '../../hospitals/screens/hospital_discovery_screen.dart';
import '../../nutrition/screens/nutrition_screen.dart';
import '../../pregnancy_education/screens/pregnancy_education_screen.dart';

/// This is the actual shell the authenticated patient app will keep once
/// signup/login exist — not a throwaway guest-only layout. The four
/// sections below (hospitals, nutrition, exercise, education) are meant to
/// stay in roughly this position; personalized sections get added
/// alongside them later, not by replacing this structure.
class GuestHomeScreen extends StatelessWidget {
  const GuestHomeScreen({super.key});

  static const path = '/guest';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              const Text(
                'MomCare',
                style: TextStyle(
                  color: AppColors.brand,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Explore pregnancy care',
                style: TextStyle(color: AppColors.body, fontSize: 15),
              ),
              const SizedBox(height: 24),
              _PrimaryAction(
                label: 'Find Hospitals',
                icon: Icons.local_hospital_outlined,
                onTap: () => context.push(HospitalDiscoveryScreen.path),
              ),
              const SizedBox(height: 28),
              _Section(
                title: 'Nutrition',
                buttonLabel: 'Nutrition plans',
                onTap: () => context.push(NutritionScreen.path),
              ),
              const SizedBox(height: 20),
              _Section(
                title: 'Exercise',
                buttonLabel: 'Pregnancy-safe exercises',
                onTap: () => context.push(ExerciseScreen.path),
              ),
              const SizedBox(height: 20),
              _Section(
                title: 'Learn',
                buttonLabel: 'Pregnancy education',
                onTap: () => context.push(PregnancyEducationScreen.path),
              ),
              const SizedBox(height: 28),
              Divider(color: Colors.white.withValues(alpha: 0.6)),
              const SizedBox(height: 20),
              GlassSurface(
                borderRadius: 20,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Guest mode',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Create an account to unlock personalized care',
                      style: TextStyle(color: AppColors.body, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        label: 'Create account',
                        onPressed: () => context.go(AuthScreen.registerPath),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GlassButton(label: label, icon: icon, onPressed: onTap),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.buttonLabel,
    required this.onTap,
  });

  final String title;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: GlassButton(
            label: buttonLabel,
            variant: GlassButtonVariant.outlined,
            onPressed: onTap,
          ),
        ),
      ],
    );
  }
}
