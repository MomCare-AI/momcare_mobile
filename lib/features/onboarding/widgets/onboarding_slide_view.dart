import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/onboarding_slide.dart';

/// The full-bleed photo background + legibility scrim for one onboarding
/// page. Deliberately renders ONLY the background — the title/description/
/// dots/buttons all live together in one stack in [OnboardingScreen] itself,
/// so they can be positioned as a single sequence instead of two
/// independent bottom-anchored groups overlapping each other (a real bug
/// found on a real device the first time this was split the other way).
class OnboardingSlideView extends StatelessWidget {
  const OnboardingSlideView({super.key, required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _Background(slide: slide),
        // Scrim: transparent at top, darkening toward the bottom where the
        // text/dots/buttons sit, so they stay readable over any photo.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xE60B1B2B)],
              stops: [0.4, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

/// The full-bleed photo, or a restrained icon-on-brand-wash placeholder if
/// no image is set — deliberately not the MomCare logo repeated three
/// times.
class _Background extends StatelessWidget {
  const _Background({required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final imagePath = slide.imagePath;
    if (imagePath == null) {
      return ColoredBox(
        color: AppColors.brandWash,
        child: Center(
          child: Icon(
            slide.heroIcon,
            size: 96,
            color: AppColors.brand,
            semanticLabel: slide.title,
          ),
        ),
      );
    }

    // Source photos are camera-resolution (up to ~4160x6240px). Decoding
    // them at full size caused a real, reproducible glitch on a real device
    // (an image intermittently failing to render), so the decode size needs
    // capping — but only ONE dimension. Passing both cacheWidth and
    // cacheHeight forces the decoder to resize to exactly those dimensions,
    // distorting (stretching) the bitmap whenever the target ratio (the
    // screen's, very tall) doesn't match the source's own ratio (~2:3) —
    // that stretched bitmap is what BoxFit.cover then crops, which is
    // exactly a visible "stretching" bug found on a real device. Capping
    // width alone lets height scale proportionally, so the decoded bitmap
    // is never distorted, only downsampled.
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final cacheWidth = (MediaQuery.of(context).size.width * dpr).round();

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      // Portrait photos into a much taller screen shape means a lot of
      // width gets cropped — anchoring the crop toward the top keeps faces
      // in frame instead of an arbitrary centered crop.
      alignment: Alignment.topCenter,
      cacheWidth: cacheWidth,
      errorBuilder: (context, error, stackTrace) => ColoredBox(
        color: AppColors.brandWash,
        child: Center(
          child: Icon(
            slide.heroIcon,
            size: 96,
            color: AppColors.brand,
            semanticLabel: slide.title,
          ),
        ),
      ),
    );
  }
}
