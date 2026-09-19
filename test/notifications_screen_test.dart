import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:momcare_mobile/features/notifications/providers/notifications_provider.dart';
import 'package:momcare_mobile/screens/settings/notifications_screen.dart';

void main() {
  // Seeded directly via a provider override, per the "no fabricated
  // notifications in production" rule — the notifier itself always starts
  // empty; only tests construct AppNotification instances.
  Widget wrap({List<AppNotification> initial = const []}) {
    return ProviderScope(
      overrides: [
        notificationsProvider.overrideWith(
          (ref) => NotificationsNotifier(initial: initial),
        ),
      ],
      child: const MaterialApp(home: NotificationsScreen()),
    );
  }

  AppNotification note({
    String id = '1',
    String title = 'Reminder saved',
    String message =
        'Your Prenatal vitamins reminder was saved on this device.',
    NotificationCategory category = NotificationCategory.medicine,
    bool isRead = false,
    DateTime? timestamp,
    NotificationTarget target = NotificationTarget.none,
  }) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      timestamp:
          timestamp ?? DateTime.now().subtract(const Duration(minutes: 5)),
      category: category,
      isRead: isRead,
      target: target,
    );
  }

  group('empty state', () {
    testWidgets('shows when there are no notifications', (tester) async {
      await tester.pumpWidget(wrap());

      expect(find.text('No notifications yet'), findsOneWidget);
      expect(find.textContaining('caught up'), findsOneWidget);
    });

    testWidgets('does not imply push delivery is currently active', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());

      expect(find.textContaining('Preview only'), findsWidgets);
      expect(find.textContaining('Push notification sent'), findsNothing);
    });
  });

  group('notification list', () {
    testWidgets('renders a notification with its title and message', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(initial: [note()]));

      expect(find.text('Reminder saved'), findsOneWidget);
      expect(find.textContaining('Prenatal vitamins'), findsOneWidget);
      expect(find.text('No notifications yet'), findsNothing);
    });

    testWidgets(
      'unread notification is visibly distinct and exposes that via text, not color alone',
      (tester) async {
        await tester.pumpWidget(wrap(initial: [note(isRead: false)]));

        // A visible "New" text pill exists — the unread cue is readable
        // text, not only a color/shape difference.
        expect(find.text('New'), findsOneWidget);
      },
    );

    testWidgets('a read notification has no "New" pill', (tester) async {
      await tester.pumpWidget(wrap(initial: [note(isRead: true)]));

      expect(find.text('New'), findsNothing);
    });
  });

  group('read state', () {
    testWidgets('tapping an unread notification marks it read', (tester) async {
      await tester.pumpWidget(wrap(initial: [note(isRead: false)]));
      expect(find.text('New'), findsOneWidget);

      await tester.tap(find.text('Reminder saved'));
      await tester.pumpAndSettle();

      // Detail sheet opened, showing the full message.
      expect(find.textContaining('Prenatal vitamins'), findsWidgets);

      // Close it and confirm the underlying card lost its unread pill.
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.text('New'), findsNothing);
    });

    testWidgets('mark all as read clears every unread notification', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          initial: [
            note(id: '1', title: 'First', isRead: false),
            note(id: '2', title: 'Second', isRead: false),
          ],
        ),
      );

      expect(find.text('New'), findsNWidgets(2));
      expect(find.textContaining('2 unread'), findsOneWidget);

      await tester.tap(find.text('Mark all as read'));
      await tester.pump();

      expect(find.text('New'), findsNothing);
      expect(find.textContaining('unread'), findsNothing);
    });

    testWidgets('mark-all action is not shown when nothing is unread', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(initial: [note(isRead: true)]));

      expect(find.text('Mark all as read'), findsNothing);
    });
  });

  group('delete / dismiss', () {
    testWidgets('deleting requires confirmation and keeps it if cancelled', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(initial: [note()]));

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete this notification?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Reminder saved'), findsOneWidget);
    });

    testWidgets(
      'confirming removes the notification and returns to empty state when it was the last one',
      (tester) async {
        await tester.pumpWidget(wrap(initial: [note()]));

        await tester.tap(find.byTooltip('Delete'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete'));
        await tester.pump();
        await tester.pump();

        expect(find.text('No notifications yet'), findsOneWidget);
        expect(find.textContaining('dismissed'), findsOneWidget);
      },
    );
  });

  group('filtering', () {
    testWidgets('category chips narrow the visible list', (tester) async {
      await tester.pumpWidget(
        wrap(
          initial: [
            note(
              id: '1',
              title: 'Medicine note',
              category: NotificationCategory.medicine,
            ),
            note(
              id: '2',
              title: 'Care note',
              category: NotificationCategory.care,
            ),
          ],
        ),
      );

      expect(find.text('Medicine note'), findsOneWidget);
      expect(find.text('Care note'), findsOneWidget);

      // Category chips carry their own keys — "Medicine" also appears as
      // the notification card's own category pill, so text alone is
      // ambiguous.
      await tester.tap(
        find.byKey(const ValueKey('notification_filter_medicine')),
      );
      await tester.pump();

      expect(find.text('Medicine note'), findsOneWidget);
      expect(find.text('Care note'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('notification_filter_all')));
      await tester.pump();

      expect(find.text('Medicine note'), findsOneWidget);
      expect(find.text('Care note'), findsOneWidget);
    });
  });
}
