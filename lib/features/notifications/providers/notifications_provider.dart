import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NotificationCategory { medicine, care, general }

extension NotificationCategoryLabel on NotificationCategory {
  String get label {
    switch (this) {
      case NotificationCategory.medicine:
        return 'Medicine';
      case NotificationCategory.care:
        return 'Care';
      case NotificationCategory.general:
        return 'General';
    }
  }
}

/// Where tapping a notification's "Open" action should go — only ever an
/// already-existing frontend screen. `none` means the notification has no
/// further destination; its detail is the message itself.
enum NotificationTarget { none, medicineReminders, vitals, carePartner }

/// Session-local only — no backend, no push delivery, no persistence across
/// app restarts. Represents something the frontend itself wants the patient
/// to see (e.g. "you created a reminder"), not a clinical event received
/// from a server, since no such server integration exists yet.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.category,
    this.isRead = false,
    this.target = NotificationTarget.none,
  });

  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationCategory category;
  final bool isRead;
  final NotificationTarget target;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      category: category,
      isRead: isRead ?? this.isRead,
      target: target,
    );
  }
}

/// Starts empty and stays empty until something in the app explicitly adds
/// to it — there is no seed data. No real event source exists yet (no
/// backend, no push delivery, no OS-scheduled reminder firing), so an
/// honestly-empty list is the correct default rather than fabricated
/// clinical activity. Tests construct their own [AppNotification]s and seed
/// this notifier directly via its constructor.
class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier({List<AppNotification> initial = const []})
    : super(initial);

  void markRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }

  void remove(String id) {
    state = state.where((n) => n.id != id).toList();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>((ref) {
      return NotificationsNotifier();
    });
