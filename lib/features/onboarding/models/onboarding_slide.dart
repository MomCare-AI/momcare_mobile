import 'package:flutter/widgets.dart';

/// Content for one onboarding slide. `imagePath` is nullable on purpose —
/// no real MomCare onboarding photography exists yet, so slides render a
/// clean icon placeholder until real assets are dropped in (just set
/// `imagePath`, nothing else about the screen needs to change).
class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.heroIcon,
    this.imagePath,
  });

  final String title;
  final String description;
  final IconData heroIcon;
  final String? imagePath;
}
