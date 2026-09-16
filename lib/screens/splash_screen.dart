import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/onboarding/screens/onboarding_screen.dart';
import '../shared/widgets/glass_surface.dart';
import '../shared/widgets/gradient_background.dart';

/// First screen shown on launch — the app's blue/white/red gradient behind
/// a frosted glass disc holding the same MomCare logo used on the web
/// (frontend/public/avatars/logo.png). A video-based splash was tried and
/// dropped after real-device testing kept showing distracting artifacts
/// between the native splash, a static logo, and the video's own logo
/// reveal — see docs/patient-app-plan.md §10. Simple and reliable beat
/// elaborate; the native splash (pre-Flutter) stays a plain icon regardless.
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
      body: GradientBackground(
        child: Center(
          child: GlassSurface(
            borderRadius: 140,
            padding: const EdgeInsets.all(36),
            child: Image.asset(
              'assets/images/momcare_logo.png',
              width: 180,
            ),
          ),
        ),
      ),
    );
  }
}
