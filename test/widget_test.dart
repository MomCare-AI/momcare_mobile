import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:momcare_mobile/main.dart';
import 'package:momcare_mobile/shared/widgets/gradient_background.dart';

void main() {
  testWidgets('app launches and shows the splash screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MomCareApp()));
    await tester.pump();

    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);
    // The splash screen's background is now the app-wide glassmorphism
    // gradient rather than a flat color — assert the wrapper is present
    // instead of a specific Scaffold.backgroundColor.
    expect(find.byType(GradientBackground), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // Replace the widget tree so the splash screen disposes and cancels
    // its navigation Timer, rather than letting it leak past this test's
    // teardown.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
