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
        ],
      ),
    );
  }

  testWidgets('shows the first slide, three dots, and both actions', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const OnboardingScreen()));

    expect(find.text('Continuous care,\nwherever you are'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Already have an account? Sign In'), findsOneWidget);
  });

  testWidgets('swiping moves to the next slide', (tester) async {
    await tester.pumpWidget(wrap(const OnboardingScreen()));

    expect(find.text('Continuous care,\nwherever you are'), findsOneWidget);

    // Drag from near the top of the screen — the bottom-anchored text/dots/
    // buttons overlay grew taller (added "Try as Guest") and now covers the
    // PageView's own default hit-test point, so a drag centered on-screen
    // hits the overlay instead of swiping the page.
    await tester.dragFrom(const Offset(400, 60), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('Your risk,\nexplained clearly'), findsOneWidget);
    expect(find.text('Continuous care,\nwherever you are'), findsNothing);
  });

  testWidgets('Get Started navigates to the sign-up screen', (tester) async {
    await tester.pumpWidget(wrap(const OnboardingScreen()));

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('sign up screen'), findsOneWidget);
  });

  testWidgets('Sign In navigates to the sign-in screen', (tester) async {
    await tester.pumpWidget(wrap(const OnboardingScreen()));

    await tester.tap(find.text('Already have an account? Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('sign in screen'), findsOneWidget);
  });
}
