import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/onboarding/screens/onboarding_screen.dart';
import '../theme/app_colors.dart';

/// First screen shown on launch — a plain circular disc holding the same
/// MomCare logo used on the web (frontend/public/avatars/logo.png). A
/// video-based splash was tried and dropped after real-device testing kept
/// showing distracting artifacts between the native splash, a static logo,
/// and the video's own logo reveal — see docs/patient-app-plan.md §10.
/// Simple and reliable beat elaborate; the native splash (pre-Flutter)
/// stays a plain icon regardless.
///
/// Built with real widgets directly, not GradientBackground/GlassSurface —
/// those are deprecated shims (see CLAUDE.md's known debt) that silently
/// drop the borderRadius this screen needs: GlassSurface forwards only
/// padding/child to ClinicalCard, which hardcodes a 16px corner radius with
/// no way to override it, so the intended circular glass disc was
/// silently rendering as a small rounded-corner card instead.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const path = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) context.go(OnboardingScreen.path);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset('assets/images/momcare_logo.png', width: 180),
        ),
      ),
    );
  }
}
