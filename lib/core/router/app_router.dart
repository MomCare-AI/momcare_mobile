import 'package:go_router/go_router.dart';

import '../../features/auth/screens/auth_screen.dart';
import '../../features/exercise/screens/exercise_screen.dart';
import '../../features/guest/screens/guest_home_screen.dart';
import '../../features/hospitals/screens/hospital_discovery_screen.dart';
import '../../features/nutrition/screens/nutrition_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/pregnancy_education/screens/pregnancy_education_screen.dart';
import '../../screens/main_home_screen.dart';
import '../../screens/splash_screen.dart';

/// Flat on purpose — the 4 guest destinations are real, top-level routes,
/// but anything deeper inside a feature (e.g. a specific exercise's detail
/// screen) is a plain Navigator.push from within that feature, not a
/// separate top-level path. Grows as features/ gets more real screens —
/// see docs/patient-app-plan.md. The invite-accept deep link (§7 of that
/// plan) will add a route here once app_links is wired in, not before.
final appRouter = GoRouter(
  initialLocation: SplashScreen.path,
  routes: [
    GoRoute(
      path: SplashScreen.path,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: OnboardingScreen.path,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: MainHomeScreen.path,
      builder: (context, state) => const MainHomeScreen(),
    ),
    GoRoute(
      path: AuthScreen.registerPath,
      builder: (context, state) => const AuthScreen(initialTab: AuthTab.register),
    ),
    GoRoute(
      path: AuthScreen.loginPath,
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: GuestHomeScreen.path,
      builder: (context, state) => const GuestHomeScreen(),
    ),
    GoRoute(
      path: HospitalDiscoveryScreen.path,
      builder: (context, state) => const HospitalDiscoveryScreen(),
    ),
    GoRoute(
      path: NutritionScreen.path,
      builder: (context, state) => const NutritionScreen(),
    ),
    GoRoute(
      path: ExerciseScreen.path,
      builder: (context, state) => const ExerciseScreen(),
    ),
    GoRoute(
      path: PregnancyEducationScreen.path,
      builder: (context, state) => const PregnancyEducationScreen(),
    ),
  ],
);
