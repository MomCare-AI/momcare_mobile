import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/medicine_reminders/providers/medicine_reminders_provider.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/app_colors.dart';

const _dayLabels = {
  DateTime.monday: 'Mon',
  DateTime.tuesday: 'Tue',
  DateTime.wednesday: 'Wed',
  DateTime.thursday: 'Thu',
  DateTime.friday: 'Fri',
  DateTime.saturday: 'Sat',
  DateTime.sunday: 'Sun',
};

/// Add and Edit share one screen — pass an existing reminder to edit it,
/// or leave it null to create a new one. Pops `true` on a successful save
/// so the list screen can show its own SnackBar (this screen is gone by
/// the time that would need to show).
class AddEditReminderScreen extends ConsumerStatefulWidget {
  const AddEditReminderScreen({super.key, this.existing});

  final MedicineReminder? existing;

  @override
  ConsumerState<AddEditReminderScreen> createState() =>
      _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends ConsumerState<AddEditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _instructionsController;

  TimeOfDay? _time;
  ReminderFrequency? _frequency;
  final Set<int> _specificDays = {};

  bool _isActive = true;
  String? _timeError;
  String? _frequencyError;
  String? _daysError;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.medicineName);
    _instructionsController = TextEditingController(
      text: existing?.instructions,
    );
    _time = existing?.time;
    _frequency = existing?.frequency;
    if (existing != null) {
      _specificDays.addAll(existing.specificDays);
      _isActive = existing.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a medicine name';
    }
    return null;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _time = picked;
        _timeError = null;
      });
    }
  }

  void _selectFrequency(ReminderFrequency frequency) {
    setState(() {
      _frequency = frequency;
      _frequencyError = null;
      if (frequency != ReminderFrequency.specificDays) {
        _specificDays.clear();
        _daysError = null;
      }
    });
  }

  void _toggleDay(int day) {
    setState(() {
      if (_specificDays.contains(day)) {
        _specificDays.remove(day);
      } else {
        _specificDays.add(day);
      }
      if (_specificDays.isNotEmpty) _daysError = null;
    });
  }

  void _save() {
    // TextFormField validation (medicine name) via the Form itself; time
    // and frequency aren't Form fields (a time picker and choice chips
    // aren't FormField-shaped), so they're validated the same way here,
    // just manually rather than through Form.validate().
    final formValid = _formKey.currentState!.validate();

    setState(() {
      _timeError = _time == null ? 'Select a time' : null;
      _frequencyError = _frequency == null ? 'Select a frequency' : null;
      _daysError =
          _frequency == ReminderFrequency.specificDays && _specificDays.isEmpty
          ? 'Select at least one day'
          : null;
    });

    if (!formValid ||
        _timeError != null ||
        _frequencyError != null ||
        _daysError != null) {
      return;
    }

    final notifier = ref.read(medicineRemindersProvider.notifier);
    final name = _nameController.text.trim();
    final instructions = _instructionsController.text.trim();

    if (_isEditing) {
      notifier.update(
        widget.existing!.copyWith(
          medicineName: name,
          instructions: instructions,
          time: _time,
          frequency: _frequency,
          specificDays: Set.of(_specificDays),
          isActive: _isActive,
        ),
      );
    } else {
      notifier.add(
        medicineName: name,
        instructions: instructions,
        time: _time!,
        frequency: _frequency!,
        specificDays: Set.of(_specificDays),
      );
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Reminder' : 'Add Reminder',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('Medicine name'),
                _TextField(
                  controller: _nameController,
                  hintText: 'e.g. Prenatal vitamins',
                  textCapitalization: TextCapitalization.words,
                  validator: _validateName,
                ),
                const SizedBox(height: 20),
                _FieldLabel('Dosage / instructions (optional)'),
                _TextField(
                  controller: _instructionsController,
                  hintText: 'e.g. 1 tablet after breakfast',
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 20),
                _FieldLabel('Time'),
                _TimePickerField(
                  time: _time,
                  onTap: _pickTime,
                  errorText: _timeError,
                ),
                const SizedBox(height: 20),
                _FieldLabel('Frequency'),
                _FrequencyPicker(
                  selected: _frequency,
                  onSelect: _selectFrequency,
                  errorText: _frequencyError,
                ),
                if (_frequency == ReminderFrequency.specificDays) ...[
                  const SizedBox(height: 16),
                  _FieldLabel('Days'),
                  _DayPicker(
                    selected: _specificDays,
                    onToggle: _toggleDay,
                    errorText: _daysError,
                  ),
                ],
                const SizedBox(height: 20),
                _ActiveRow(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: _isEditing ? 'Save Changes' : 'Save Reminder',
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hintText,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.high, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.high, width: 2),
        ),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.time,
    required this.onTap,
    this.errorText,
  });

  final TimeOfDay? time;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: time == null
              ? 'Select reminder time'
              : 'Reminder time, ${time!.format(context)}',
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasError ? AppColors.high : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      time?.format(context) ?? 'Select a time',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: time == null
                            ? FontWeight.w400
                            : FontWeight.w600,
                        color: time == null
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.access_time,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText!,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.high),
            ),
          ),
      ],
    );
  }
}

class _FrequencyPicker extends StatelessWidget {
  const _FrequencyPicker({
    required this.selected,
    required this.onSelect,
    this.errorText,
  });

  final ReminderFrequency? selected;
  final ValueChanged<ReminderFrequency> onSelect;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final frequency in ReminderFrequency.values)
              _ChoiceChip(
                label: frequency.label,
                selected: selected == frequency,
                onTap: () => onSelect(frequency),
              ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText!,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.high),
            ),
          ),
      ],
    );
  }
}

class _DayPicker extends StatelessWidget {
  const _DayPicker({
    required this.selected,
    required this.onToggle,
    this.errorText,
  });

  final Set<int> selected;
  final ValueChanged<int> onToggle;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in _dayLabels.entries)
              _ChoiceChip(
                label: entry.value,
                selected: selected.contains(entry.key),
                onTap: () => onToggle(entry.key),
              ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText!,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.high),
            ),
          ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
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
            constraints: const BoxConstraints(minHeight: 40),
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

class _ActiveRow extends StatelessWidget {
  const _ActiveRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Active',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
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
