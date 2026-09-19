import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:momcare_mobile/screens/settings/medicine_reminders_screen.dart';

void main() {
  Widget wrap() {
    return const ProviderScope(
      child: MaterialApp(home: MedicineRemindersScreen()),
    );
  }

  /// The add/edit form is taller than the default 800x600 test surface —
  /// Save sits below the fold once every field is visible, so it needs
  /// scrolling into view before a tap will actually hit it.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
  }

  /// Fills the add-reminder form with valid data and taps Save. Accepts the
  /// time picker's default initial time via its own "OK" button rather than
  /// interacting with the dial — the exact time isn't what these tests are
  /// checking, just that a time was genuinely selected.
  Future<void> fillValidReminder(
    WidgetTester tester, {
    String name = 'Prenatal vitamins',
    String frequencyLabel = 'Once daily',
  }) async {
    await tester.enterText(find.byType(TextFormField).first, name);

    await tester.tap(find.text('Select a time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(frequencyLabel));
    await tester.pump();
  }

  group('empty state', () {
    testWidgets('shows initially, with the Add Reminder CTA', (tester) async {
      await tester.pumpWidget(wrap());

      expect(find.text('No medicine reminders yet'), findsOneWidget);
      expect(find.text('Add Reminder'), findsOneWidget);
    });

    testWidgets('the disclosure is visible even with no reminders', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());

      expect(find.textContaining('Preview only'), findsOneWidget);
      expect(find.textContaining('notifications aren'), findsOneWidget);
    });

    testWidgets('Add Reminder CTA opens the add flow', (tester) async {
      await tester.pumpWidget(wrap());

      await tester.tap(find.text('Add Reminder'));
      await tester.pumpAndSettle();

      expect(find.text('Add Reminder'), findsWidgets); // AppBar title + CTA
      expect(find.text('Medicine name'), findsOneWidget);
    });
  });

  group('validation', () {
    testWidgets('empty medicine name fails validation', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('Add Reminder'));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Save Reminder'));
      await tester.pump();

      expect(find.text('Enter a medicine name'), findsOneWidget);
      // Still on the add screen — nothing was saved.
      expect(find.text('No medicine reminders yet'), findsNothing);
    });

    testWidgets('missing time and frequency both fail validation', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('Add Reminder'));
      await tester.pumpAndSettle();

      // Settle the text field's own focus-triggered scroll before scrolling
      // to Save — otherwise the two scroll animations race and the tap can
      // land before Save is actually in view.
      await tester.enterText(find.byType(TextFormField).first, 'Iron');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Save Reminder'));
      await tester.pump();

      // "Select a time" is also the time field's own empty-state label, so
      // a real validation error renders it twice (label + error message).
      expect(find.text('Select a time'), findsNWidgets(2));
      expect(find.text('Select a frequency'), findsOneWidget);
    });

    testWidgets('specific-days frequency requires at least one day selected', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('Add Reminder'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Iron');
      await tester.tap(find.text('Select a time'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Specific days'));
      await tester.pump();

      await tapVisible(tester, find.text('Save Reminder'));
      await tester.pump();

      expect(find.text('Select at least one day'), findsOneWidget);

      await tester.tap(find.text('Wed'));
      await tapVisible(tester, find.text('Save Reminder'));
      await tester.pumpAndSettle();

      // Saved successfully this time — back on the list, showing "Wed".
      expect(find.text('No medicine reminders yet'), findsNothing);
      expect(find.textContaining('Wed'), findsOneWidget);
    });
  });

  group('creating a reminder', () {
    testWidgets('a valid reminder can be created and appears in the list', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('Add Reminder'));
      await tester.pumpAndSettle();

      await fillValidReminder(tester);
      await tapVisible(tester, find.text('Save Reminder'));
      await tester.pumpAndSettle();

      expect(find.text('No medicine reminders yet'), findsNothing);
      expect(find.text('Prenatal vitamins'), findsOneWidget);
      expect(
        find.text('Reminder saved. Phone notifications aren’t connected yet.'),
        findsOneWidget,
      );
    });
  });

  group('editing a reminder', () {
    testWidgets('edit updates the reminder in place', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('Add Reminder'));
      await tester.pumpAndSettle();
      await fillValidReminder(tester);
      await tapVisible(tester, find.text('Save Reminder'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Prenatal vitamins'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Reminder'), findsWidgets);
      // Existing value is pre-filled.
      expect(find.text('Prenatal vitamins'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'Iron tablets');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Iron tablets'), findsOneWidget);
      expect(find.text('Prenatal vitamins'), findsNothing);
    });
  });

  group('active/inactive toggle', () {
    testWidgets('toggling updates state immediately', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('Add Reminder'));
      await tester.pumpAndSettle();
      await fillValidReminder(tester);
      await tapVisible(tester, find.text('Save Reminder'));
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);

      await tester.tap(switchFinder);
      await tester.pump();

      expect(tester.widget<Switch>(switchFinder).value, isFalse);
    });
  });

  group('deleting a reminder', () {
    testWidgets('requires confirmation and keeps the reminder if cancelled', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('Add Reminder'));
      await tester.pumpAndSettle();
      await fillValidReminder(tester);
      await tapVisible(tester, find.text('Save Reminder'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete this reminder?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Prenatal vitamins'), findsOneWidget);
    });

    testWidgets('confirming removes the reminder and returns to empty state', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('Add Reminder'));
      await tester.pumpAndSettle();
      await fillValidReminder(tester);
      await tapVisible(tester, find.text('Save Reminder'));
      await tester.pumpAndSettle();
      // The "Reminder saved" SnackBar from above is still showing (its own
      // 4s auto-dismiss timer never elapsed under pumpAndSettle — see the
      // note by fillValidReminder). ScaffoldMessenger queues rather than
      // replaces a new SnackBar while one is still up, so the "...deleted."
      // SnackBar below would never actually appear unless this one is let
      // through its full auto-dismiss first.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('No medicine reminders yet'), findsOneWidget);
      expect(find.textContaining('deleted'), findsOneWidget);
    });
  });
}
