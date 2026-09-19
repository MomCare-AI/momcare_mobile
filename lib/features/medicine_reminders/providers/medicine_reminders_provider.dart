import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ReminderFrequency { onceDaily, twiceDaily, thriceDaily, specificDays }

extension ReminderFrequencyLabel on ReminderFrequency {
  String get label {
    switch (this) {
      case ReminderFrequency.onceDaily:
        return 'Once daily';
      case ReminderFrequency.twiceDaily:
        return 'Twice daily';
      case ReminderFrequency.thriceDaily:
        return 'Three times daily';
      case ReminderFrequency.specificDays:
        return 'Specific days';
    }
  }
}

/// Session-local only — no backend, no persistence across app restarts, no
/// OS notification scheduling. A reminder here represents what the patient
/// asked to be reminded about; it doesn't mean anything was actually
/// scheduled with the phone yet (see MedicineRemindersScreen's own
/// disclosure). Deliberately holds only what the user themselves entered —
/// no diagnosis, prescription ID, doctor ID, pharmacy, or refill count,
/// none of which exist anywhere in this app yet.
class MedicineReminder {
  const MedicineReminder({
    required this.id,
    required this.medicineName,
    this.instructions = '',
    required this.time,
    required this.frequency,
    this.specificDays = const <int>{},
    this.isActive = true,
  });

  final String id;
  final String medicineName;
  final String instructions;
  final TimeOfDay time;
  final ReminderFrequency frequency;

  /// DateTime.monday..DateTime.sunday (1..7) — only meaningful when
  /// frequency == specificDays.
  final Set<int> specificDays;
  final bool isActive;

  MedicineReminder copyWith({
    String? medicineName,
    String? instructions,
    TimeOfDay? time,
    ReminderFrequency? frequency,
    Set<int>? specificDays,
    bool? isActive,
  }) {
    return MedicineReminder(
      id: id,
      medicineName: medicineName ?? this.medicineName,
      instructions: instructions ?? this.instructions,
      time: time ?? this.time,
      frequency: frequency ?? this.frequency,
      specificDays: specificDays ?? this.specificDays,
      isActive: isActive ?? this.isActive,
    );
  }
}

class MedicineRemindersNotifier extends StateNotifier<List<MedicineReminder>> {
  MedicineRemindersNotifier() : super(const []);

  // Monotonic within a session — no backend id to defer to, and reminders
  // are never persisted past this session anyway.
  int _nextId = 0;
  String _newId() => '${DateTime.now().microsecondsSinceEpoch}_${_nextId++}';

  MedicineReminder add({
    required String medicineName,
    required String instructions,
    required TimeOfDay time,
    required ReminderFrequency frequency,
    Set<int> specificDays = const <int>{},
  }) {
    final reminder = MedicineReminder(
      id: _newId(),
      medicineName: medicineName,
      instructions: instructions,
      time: time,
      frequency: frequency,
      specificDays: specificDays,
    );
    state = [...state, reminder];
    return reminder;
  }

  void update(MedicineReminder updated) {
    state = [
      for (final r in state)
        if (r.id == updated.id) updated else r,
    ];
  }

  void remove(String id) {
    state = state.where((r) => r.id != id).toList();
  }

  void toggleActive(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(isActive: !r.isActive) else r,
    ];
  }
}

final medicineRemindersProvider =
    StateNotifierProvider<MedicineRemindersNotifier, List<MedicineReminder>>((
      ref,
    ) {
      return MedicineRemindersNotifier();
    });
