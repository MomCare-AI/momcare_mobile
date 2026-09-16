import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/glass_surface.dart';
import '../../../theme/app_colors.dart';
import '../../auth/screens/auth_screen.dart';
import '../../guest/screens/guest_home_screen.dart';
import '../models/onboarding_slide.dart';
import '../widgets/onboarding_slide_view.dart';

/// The three onboarding slides. Slide 3's copy is a deliberate, clearly
/// temporary placeholder — its real clinical message/imagery hasn't been
/// provided yet, and it must not be invented (docs/patient-app-plan.md's
/// own "don't guess" rule applies to content, not just API contracts).
const _slides = [
  OnboardingSlide(
    heroIcon: Icons.monitor_heart_outlined,
    imagePath: 'assets/images/onboard/pexels-mart-production-7088841.jpg',
    title: 'Continuous care,\nwherever you are',
    description:
        'Vitals from your wearable reach your care team automatically — '
        'no need to remember to check in.',
  ),
  OnboardingSlide(
    heroIcon: Icons.insights_outlined,
    imagePath: 'assets/images/onboard/pexels-thirdman-7659876.jpg',
    title: 'Your risk,\nexplained clearly',
    description:
        'Every reading is reviewed and graded, so you and your care team '
        'both know when something needs attention.',
  ),
  OnboardingSlide(
    // TODO(product): replace with the real slide 3 content once provided —
    // deliberately generic so nothing clinical is invented here. Image is
    // real (user-supplied), only the copy is a placeholder.
    heroIcon: Icons.favorite_outline,
    imagePath: 'assets/images/onboard/pexels-cottonbro-5853666.jpg',
    title: 'More, on the way',
    description: 'This slide is a placeholder for content not yet provided.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const path = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  void _goToSignUp() {
    context.go(AuthScreen.registerPath);
  }

  void _goToSignIn() {
    context.go(AuthScreen.loginPath);
  }

  void _continueAsGuest() {
    context.go(GuestHomeScreen.path);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status-bar icons — the photo fills the whole screen, behind
      // the status bar and behind the action buttons, so dark icons could
      // disappear against it.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        // The image is the entire screen (Stack, not a Column with a
        // separate footer section) — everything in the foreground (text,
        // dots, buttons) is ONE bottom-anchored group below, not split
        // across two independent bottom-aligned widgets (that overlapped
        // each other — a real bug found on a real device).
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemBuilder: (context, index) =>
                  OnboardingSlideView(slide: _slides[index]),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: GlassSurface(
                    borderRadius: 28,
                    opacity: 0.6,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.body,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _Dots(count: _slides.length, current: _currentPage),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: GlassButton(
                            label: 'Get Started',
                            onPressed: _goToSignUp,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _goToSignIn,
                          child: const Text('Already have an account? Sign In'),
                        ),
                        TextButton(
                          onPressed: _continueAsGuest,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.faint,
                          ),
                          child: const Text('Try as Guest'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            // These sit on the light glass panel now, not the photo
            // directly, so brand-colored dots read correctly.
            color: active ? AppColors.brand : AppColors.brand.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
