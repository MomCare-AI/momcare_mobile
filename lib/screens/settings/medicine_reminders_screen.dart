import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/medicine_reminders/providers/medicine_reminders_provider.dart';
import '../../theme/app_colors.dart';
import 'add_edit_reminder_screen.dart';

const _dayShortLabels = {
  DateTime.monday: 'Mon',
  DateTime.tuesday: 'Tue',
  DateTime.wednesday: 'Wed',
  DateTime.thursday: 'Thu',
  DateTime.friday: 'Fri',
  DateTime.saturday: 'Sat',
  DateTime.sunday: 'Sun',
};

String _scheduleLabel(MedicineReminder reminder) {
  if (reminder.frequency != ReminderFrequency.specificDays) {
    return reminder.frequency.label;
  }
  if (reminder.specificDays.isEmpty) return reminder.frequency.label;
  final sortedDays = reminder.specificDays.toList()..sort();
  return sortedDays.map((d) => _dayShortLabels[d]).join(', ');
}

/// Full frontend lifecycle over session-local state (medicineRemindersProvider)
/// — no backend, no OS notification scheduling. See the persistent
/// disclosure banner below and each screen's own doc comments for why.
class MedicineRemindersScreen extends ConsumerWidget {
  const MedicineRemindersScreen({super.key});

  Future<void> _openAdd(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddEditReminderScreen()),
    );
    if (saved == true && context.mounted) {
      _showSavedSnackBar(context);
    }
  }

  Future<void> _openEdit(
    BuildContext context,
    MedicineReminder reminder,
  ) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddEditReminderScreen(existing: reminder),
      ),
    );
    if (saved == true && context.mounted) {
      _showSavedSnackBar(context);
    }
  }

  void _showSavedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Reminder saved. Phone notifications aren’t connected yet.',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    MedicineReminder reminder,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete this reminder?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          '"${reminder.medicineName}" will be removed from this preview.',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
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

    if (confirmed != true || !context.mounted) return;
    ref.read(medicineRemindersProvider.notifier).remove(reminder.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${reminder.medicineName}" deleted.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(medicineRemindersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Medicine Reminders',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (reminders.isNotEmpty)
            IconButton(
              tooltip: 'Add reminder',
              icon: const Icon(LucideIcons.plus),
              color: AppColors.primary,
              onPressed: () => _openAdd(context),
            ),
        ],
      ),
      body: SafeArea(
        child: reminders.isEmpty
            ? _EmptyState(onAdd: () => _openAdd(context))
            : Column(
                children: [
                  const _DisclosureBanner(),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: reminders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final reminder = reminders[index];
                        return _ReminderCard(
                          reminder: reminder,
                          onTap: () => _openEdit(context, reminder),
                          onToggleActive: () => ref
                              .read(medicineRemindersProvider.notifier)
                              .toggleActive(reminder.id),
                          onDelete: () =>
                              _confirmDelete(context, ref, reminder),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DisclosureBanner extends StatelessWidget {
  const _DisclosureBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppColors.moderate.withValues(alpha: 0.12),
      child: Text(
        'Preview only — reminders are stored on this device for this '
        'session. Phone notification scheduling isn’t connected yet.',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.moderate,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.pill, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No medicine reminders yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a reminder for a medicine, vitamin, or supplement to '
              'keep track of your schedule.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.moderate.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Preview only — phone notifications aren’t '
                'connected yet.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.moderate,
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Add Reminder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  textStyle: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.onTap,
    required this.onToggleActive,
    required this.onDelete,
  });

  final MedicineReminder reminder;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // Local Material + InkWell rather than ClinicalCard — ClinicalCard's own
    // onTap is a plain GestureDetector with no ripple over an opaque
    // background (same reason Settings' accent card built its own wrapper
    // instead), and editing a reminder is this card's primary action.
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.medicineName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: reminder.isActive
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (reminder.instructions.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        reminder.instructions,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reminder.time.format(context),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _scheduleLabel(reminder),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Semantics(
                    label:
                        '${reminder.isActive ? 'Active' : 'Inactive'}, '
                        '${reminder.medicineName} reminder',
                    child: Switch(
                      value: reminder.isActive,
                      onChanged: (_) => onToggleActive(),
                      activeThumbColor: AppColors.primary,
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Delete ${reminder.medicineName} reminder',
                    excludeSemantics: true,
                    child: IconButton(
                      onPressed: onDelete,
                      icon: const Icon(LucideIcons.trash2, size: 18),
                      color: AppColors.high,
                      tooltip: 'Delete',
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
