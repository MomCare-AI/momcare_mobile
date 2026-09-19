import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:momcare_mobile/screens/settings/care_partner_screen.dart';

void main() {
  // Clipboard.setData has no default mock in the test binding — without
  // this, the SystemChannels.platform call never resolves, leaving
  // _copy()'s await stuck forever (no exception, no SnackBar, nothing).
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') return null;
        return null;
      });

  Widget wrap() {
    return const ProviderScope(child: MaterialApp(home: CarePartnerScreen()));
  }

  group('empty state', () {
    testWidgets('shows the invite explanation and action', (tester) async {
      await tester.pumpWidget(wrap());

      expect(find.text('Invite a care partner'), findsOneWidget);
      expect(find.text('Invite care partner'), findsOneWidget);
      // No invitation exists yet, so nothing implying one does.
      expect(find.text('Invitation ready'), findsNothing);
    });
  });

  group('creating an invitation', () {
    testWidgets(
      'tapping Invite generates a MOM-XXXXX code and shows the ready state',
      (tester) async {
        await tester.pumpWidget(wrap());

        await tester.tap(find.text('Invite care partner'));
        await tester.pump();

        expect(find.text('Invitation ready'), findsOneWidget);
        expect(find.textContaining('Invite a care partner'), findsNothing);

        final codeFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data != null &&
              RegExp(r'^MOM-[A-Z0-9]{5}$').hasMatch(widget.data!),
        );
        expect(codeFinder, findsOneWidget);
      },
    );

    testWidgets(
      'copying the invitation shows honest "copied" feedback, not "sent"',
      (tester) async {
        await tester.pumpWidget(wrap());
        await tester.tap(find.text('Invite care partner'));
        await tester.pump();

        await tester.tap(find.text('Copy invitation'));
        // pumpAndSettle() is the wrong tool here — SnackBar has its own
        // auto-dismiss Timer (4s default), and pump(duration) advances the
        // fake clock enough to fire it, so pumpAndSettle() would simulate
        // straight through the SnackBar's entire visible lifecycle and see
        // it already gone. Two bare pump()s (no duration) flush the
        // Clipboard.setData platform-channel microtask and render the
        // SnackBar's entrance frame without advancing time toward dismissal.
        await tester.pump();
        await tester.pump();

        expect(find.text('Invitation copied'), findsOneWidget);
        // The screen's own explanation honestly says "hasn't been sent" —
        // that's correct copy. What must never appear is a false positive
        // claim that it *was* sent.
        expect(find.textContaining('Invitation sent'), findsNothing);
      },
    );
  });

  group('cancelling an invitation', () {
    testWidgets('requires confirmation and keeps the invitation if declined', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('Invite care partner'));
      await tester.pump();

      await tester.tap(find.text('Cancel invitation').first);
      await tester.pump();

      expect(find.text('Cancel invitation?'), findsOneWidget);

      await tester.tap(find.text('Keep it'));
      await tester.pump();

      // Still on the ready state — declining the dialog changed nothing.
      expect(find.text('Invitation ready'), findsOneWidget);
    });

    testWidgets('confirming returns to the empty state with honest wording', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('Invite care partner'));
      await tester.pump();

      await tester.tap(find.text('Cancel invitation').first);
      await tester.pump();

      // Two "Cancel invitation" texts now exist (the row and the dialog's
      // destructive action) — the dialog's is the last one in the tree.
      await tester.tap(find.text('Cancel invitation').last);
      await tester.pump();

      expect(find.text('Invite a care partner'), findsOneWidget);
      expect(find.text('Invitation ready'), findsNothing);
      expect(
        find.text('Invitation removed from this preview.'),
        findsOneWidget,
      );
      // Never implies a server-side cancellation.
      expect(find.textContaining('server'), findsNothing);
    });
  });

  group('accessibility', () {
    testWidgets('invitation code is exposed as one meaningful semantic label', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('Invite care partner'));
      await tester.pump();

      final semanticsHandle = tester.ensureSemantics();
      final codeSemantics = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label != null,
      );
      final hasCodeLabel = tester
          .widgetList<Semantics>(codeSemantics)
          .any((w) => w.properties.label!.startsWith('Invitation code MOM-'));
      expect(hasCodeLabel, isTrue);
      semanticsHandle.dispose();
    });
  });
}
