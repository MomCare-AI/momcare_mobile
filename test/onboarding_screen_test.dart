import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:momcare_mobile/features/onboarding/screens/onboarding_screen.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: OnboardingScreen.path,
        routes: [
          GoRoute(
            path: OnboardingScreen.path,
            builder: (context, state) => child,
          ),
          GoRoute(
            path: '/signup',
            builder: (context, state) =>
                const Scaffold(body: Text('sign up screen')),
          ),
          GoRoute(
            path: '/signin',
            builder: (context, state) =>
                const Scaffold(body: Text('sign in screen')),
          ),
          GoRoute(
            path: '/guest',
            builder: (context, state) =>
                const Scaffold(body: Text('guest home screen')),
          ),
        ],
      ),
    );
  }

  // Neither a bare pump() nor one big pump(duration) jump reliably settles
  // an animation-driven callback (a status-listener firing context.go(), or
  // a Material page transition's own AnimationController) — confirmed
  // empirically: a single pump(900ms) after tapping the ParticleButton left
  // "sign up screen" entirely absent from the tree, while stepping the same
  // total duration in 50ms increments consistently revealed it. Step
  // everything animation-related in small increments instead of guessing at
  // one big jump.
  Future<void> pumpInSteps(
    WidgetTester tester, {
    required Duration total,
    Duration step = const Duration(milliseconds: 50),
  }) async {
    var remaining = total;
    while (remaining > Duration.zero) {
      final thisStep = remaining < step ? remaining : step;
      await tester.pump(thisStep);
      remaining -= thisStep;
    }
  }

  // Onboarding is a single static screen now, not a swipeable carousel — the
  // "shows the first slide" / "swiping moves to the next slide" cases from
  // the old carousel design no longer apply to anything in the current
  // widget tree.
  //
  // AutoScrollingRow (the tag-pill rows) drives an indefinite Ticker that
  // never stops on its own, so pumpAndSettle() never returns on this screen
  // — every test below uses bounded pump() calls instead.
  //
  // The screen's content sits right at the default 800x600 test-surface
  // height, so the bottom action buttons render just past the visible
  // viewport inside the SingleChildScrollView — present in the tree
  // (find.text locates them) but not tappable until scrolled into view.
  // ensureVisible() before each tap, not a viewport-size assumption.

  testWidgets('shows the hero copy and all three actions', (tester) async {
    await tester.pumpWidget(wrap(const OnboardingScreen()));
    await tester.pump();

    expect(find.text("Let's make"), findsOneWidget);
    expect(find.text('your days'), findsOneWidget);
    expect(find.text('healthier'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('I Already Have an Account'), findsOneWidget);
    expect(find.text('Try as Guest'), findsOneWidget);
  });

  testWidgets('Get Started navigates to the sign-up screen', (tester) async {
    await tester.pumpWidget(wrap(const OnboardingScreen()));
    await tester.pump();

    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    // ParticleButton's 800ms disintegration animation, then the resulting
    // page transition — both need stepped time to settle.
    await pumpInSteps(tester, total: const Duration(milliseconds: 1000));
    await pumpInSteps(tester, total: const Duration(milliseconds: 400));

    expect(find.text('sign up screen'), findsOneWidget);
  });

  testWidgets('Sign In navigates to the sign-in screen', (tester) async {
    await tester.pumpWidget(wrap(const OnboardingScreen()));
    await tester.pump();

    await tester.ensureVisible(find.text('I Already Have an Account'));
    await tester.tap(find.text('I Already Have an Account'));
    await pumpInSteps(tester, total: const Duration(milliseconds: 400));

    expect(find.text('sign in screen'), findsOneWidget);
  });

  testWidgets('Try as Guest navigates to guest home', (tester) async {
    await tester.pumpWidget(wrap(const OnboardingScreen()));
    await tester.pump();

    await tester.ensureVisible(find.text('Try as Guest'));
    await tester.tap(find.text('Try as Guest'));
    await pumpInSteps(tester, total: const Duration(milliseconds: 400));

    expect(find.text('guest home screen'), findsOneWidget);
  });
}
