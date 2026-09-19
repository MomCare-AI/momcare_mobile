import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:momcare_mobile/main.dart';
import 'package:momcare_mobile/theme/app_colors.dart';

void main() {
  testWidgets('app launches and shows the splash screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MomCareApp()));
    await tester.pump();

    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);
    // GradientBackground/GlassSurface are deprecated shims the splash
    // screen no longer uses (see splash_screen.dart's own doc comment —
    // GlassSurface was silently dropping the borderRadius this screen
    // needs). Assert against what's actually there now: a plain Scaffold
    // background and the logo image.
    expect(
      tester.widget<Scaffold>(scaffoldFinder).backgroundColor,
      AppColors.background,
    );
    expect(find.byType(Image), findsOneWidget);

    // Replace the widget tree so the splash screen disposes and cancels
    // its navigation Timer, rather than letting it leak past this test's
    // teardown.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
