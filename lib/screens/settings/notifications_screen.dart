import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/notifications/providers/notifications_provider.dart';
import '../../features/vitals/screens/vitals_screen.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/app_colors.dart';
import 'care_partner_screen.dart';
import 'medicine_reminders_screen.dart';

IconData _categoryIcon(NotificationCategory category) {
  switch (category) {
    case NotificationCategory.medicine:
      return LucideIcons.pill;
    case NotificationCategory.care:
      return LucideIcons.heartHandshake;
    case NotificationCategory.general:
      return LucideIcons.bell;
  }
}

String _targetLabel(NotificationTarget target) {
  switch (target) {
    case NotificationTarget.medicineReminders:
      return 'Medicine Reminders';
    case NotificationTarget.vitals:
      return 'Vitals';
    case NotificationTarget.carePartner:
      return 'Care Partner';
    case NotificationTarget.none:
      return '';
  }
}

String _relativeTime(DateTime time) {
  final difference = DateTime.now().difference(time);
  if (difference.isNegative || difference.inSeconds < 60) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays == 1) return 'Yesterday';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return '${time.month}/${time.day}/${time.year}';
}

/// This screen is two things stacked together: the pre-existing local
/// notification *preference* (top card, unchanged) and the new
/// patient-facing notification *center* (list below it). They're related
/// but distinct — see the class-level notes on each section for why the
/// toggle isn't wired to the list.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _medicineReminders = true;
  NotificationCategory? _filter;

  void _openNotification(AppNotification notification) {
    ref.read(notificationsProvider.notifier).markRead(notification.id);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _NotificationDetailSheet(
        notification: notification,
        onOpenTarget: notification.target == NotificationTarget.none
            ? null
            : () {
                Navigator.of(sheetContext).pop();
                _navigateToTarget(notification.target);
              },
      ),
    );
  }

  void _navigateToTarget(NotificationTarget target) {
    final Widget screen;
    switch (target) {
      case NotificationTarget.medicineReminders:
        screen = const MedicineRemindersScreen();
        break;
      case NotificationTarget.vitals:
        screen = const VitalsScreen();
        break;
      case NotificationTarget.carePartner:
        screen = const CarePartnerScreen();
        break;
      case NotificationTarget.none:
        return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _confirmDelete(AppNotification notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete this notification?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          '"${notification.title}" will be removed from this list.',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: AppColors.high,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    ref.read(notificationsProvider.notifier).remove(notification.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${notification.title}" dismissed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(
      notificationsProvider.select(
        (list) => list.where((n) => !n.isRead).length,
      ),
    );

    final filtered = _filter == null
        ? notifications
        : notifications.where((n) => n.category == _filter).toList();
    final sorted = [...filtered]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: ClinicalCard(
                child: _ToggleRow(
                  icon: LucideIcons.pill,
                  title: 'Medicine reminders',
                  subtitle:
                      'Preference only — the reminder engine isn’t '
                      'active yet',
                  value: _medicineReminders,
                  onChanged: (v) => setState(() => _medicineReminders = v),
                ),
              ),
            ),
            Expanded(
              child: notifications.isEmpty
                  ? const _EmptyNotificationsState()
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  unreadCount == 0
                                      ? 'Recent'
                                      : 'Recent · $unreadCount unread',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              if (unreadCount > 0)
                                TextButton.icon(
                                  onPressed: () => ref
                                      .read(notificationsProvider.notifier)
                                      .markAllRead(),
                                  icon: const Icon(
                                    LucideIcons.checkCheck,
                                    size: 16,
                                  ),
                                  label: const Text('Mark all as read'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    minimumSize: const Size(48, 48),
                                    textStyle: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              _CategoryFilterChip(
                                key: const ValueKey('notification_filter_all'),
                                label: 'All',
                                selected: _filter == null,
                                onTap: () => setState(() => _filter = null),
                              ),
                              const SizedBox(width: 8),
                              for (final category
                                  in NotificationCategory.values) ...[
                                _CategoryFilterChip(
                                  key: ValueKey(
                                    'notification_filter_${category.name}',
                                  ),
                                  label: category.label,
                                  selected: _filter == category,
                                  onTap: () =>
                                      setState(() => _filter = category),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: _DisclosureBanner(),
                        ),
                        Expanded(
                          child: sorted.isEmpty
                              ? Center(
                                  child: Text(
                                    'No ${_filter!.label.toLowerCase()} notifications',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: sorted.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final notification = sorted[index];
                                    return _NotificationCard(
                                      notification: notification,
                                      onTap: () =>
                                          _openNotification(notification),
                                      onDelete: () =>
                                          _confirmDelete(notification),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A UI preference only — flipping it doesn't do anything yet, since the
/// actual reminder/scheduling engine is a separate, deferred task. The
/// subtitle says so explicitly rather than implying it's already wired up.
///
/// Deliberately NOT wired to the notification center below, nor to
/// medicineRemindersProvider's per-reminder `isActive` flags — this toggle
/// represents a future global "should MomCare notify me at all"
/// permission-style preference, separate from both a given reminder's own
/// active/inactive switch and from what's already in the local notification
/// list. Gating either by this toggle would be inventing a notification
/// engine's behavior, not representing one that exists.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 22, color: AppColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }
}

class _DisclosureBanner extends StatelessWidget {
  const _DisclosureBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.moderate.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Preview only — notification delivery and server synchronization '
        'aren’t connected yet.',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.moderate,
        ),
      ),
    );
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.bell, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You’re all caught up. New updates will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.moderate.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Preview only — delivery isn’t connected yet.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.moderate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    // Unread is communicated three ways at once — bold title, a tinted
    // card, and a visible "New" text pill — so it never depends on color
    // alone. The card's own tap target has no wrapping Semantics: its
    // visible text (title, "New" pill, message, category, time) already
    // reads correctly as one merged button via Flutter's default semantics,
    // same as _ReminderCard in medicine_reminders_screen.dart. Only the
    // delete button below gets its own explicit Semantics, since an
    // outer excludeSemantics here would otherwise swallow it.
    return Material(
      color: isUnread
          ? AppColors.primary.withValues(alpha: 0.05)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _categoryIcon(notification.category),
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'New',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _CategoryPill(label: notification.category.label),
                        const SizedBox(width: 8),
                        Text(
                          _relativeTime(notification.timestamp),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'Delete ${notification.title} notification',
                excludeSemantics: true,
                child: IconButton(
                  onPressed: onDelete,
                  icon: const Icon(LucideIcons.trash2, size: 18),
                  color: AppColors.textSecondary,
                  tooltip: 'Delete',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationDetailSheet extends StatelessWidget {
  const _NotificationDetailSheet({
    required this.notification,
    this.onOpenTarget,
  });

  final AppNotification notification;
  final VoidCallback? onOpenTarget;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _categoryIcon(notification.category),
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    notification.title,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Close',
                  excludeSemantics: true,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x, size: 18),
                    color: AppColors.textSecondary,
                    tooltip: 'Close',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              notification.message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _CategoryPill(label: notification.category.label),
                const SizedBox(width: 8),
                Text(
                  _relativeTime(notification.timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (onOpenTarget != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Open ${_targetLabel(notification.target)}',
                onPressed: onOpenTarget!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
