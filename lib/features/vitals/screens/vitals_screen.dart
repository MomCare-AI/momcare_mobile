import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../shared/widgets/clinical_card.dart';
import '../../../theme/app_colors.dart';
import '../models/vital_reading.dart';
import '../providers/vitals_provider.dart';

/// A single relative-time helper rather than pulling in `intl` for one
/// screen — see CLAUDE.md: don't add a package a small function can do.
String _relativeTime(DateTime when) {
  final diff = DateTime.now().difference(when);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  if (diff.inDays == 1) return 'Yesterday';
  return '${diff.inDays} days ago';
}

String _timeOfDay(DateTime when) {
  final hour = when.hour % 12 == 0 ? 12 : when.hour % 12;
  final minute = when.minute.toString().padLeft(2, '0');
  final period = when.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

class VitalsScreen extends ConsumerWidget {
  const VitalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vitalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Vitals',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Persistent, not part of the scrolling content — see
            // docs/PRODUCT_RULES.md: a fabrication-risk disclaimer that
            // scrolls out of view the moment you look at the actual numbers
            // doesn't do its job. This stays on screen the whole time.
            _buildSampleDataBanner(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(vitalsProvider.notifier).fetch(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(state),
                      const SizedBox(height: 16),
                      _buildTimeFilters(ref, state.timeRange),
                      if (state.isRefreshing) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.border,
                          minHeight: 2,
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildBody(state),
                      const SizedBox(height: 80), // Padding for BottomNav
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleDataBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: AppColors.moderate.withValues(alpha: 0.12),
      child: Text(
        'Sample data — not yet connected',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.moderate,
        ),
      ),
    );
  }

  Widget _buildHeader(VitalsState state) {
    final latest = state.readings.isNotEmpty ? state.readings.first : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your health measurements',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          latest != null
              ? 'Last updated ${_relativeTime(latest.recordedAt)}'
              : 'No measurements yet',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeFilters(WidgetRef ref, VitalsTimeRange selected) {
    Widget chip(String label, VitalsTimeRange range) {
      final isActive = range == selected;
      return Material(
        color: isActive ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => ref.read(vitalsProvider.notifier).setTimeRange(range),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            // 44pt minimum tap target (Apple HIG / Material accessibility) —
            // the visible pill stays compact, only the hit area grows.
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('Today', VitalsTimeRange.today),
        const SizedBox(width: 12),
        chip('Week', VitalsTimeRange.week),
        const SizedBox(width: 12),
        chip('Month', VitalsTimeRange.month),
      ],
    );
  }

  Widget _buildBody(VitalsState state) {
    switch (state.status) {
      case VitalsStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 64),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      case VitalsStatus.error:
        return _buildMessage(
          icon: LucideIcons.wifiOff,
          title: 'Something went wrong',
          message: state.errorMessage ?? 'Could not load your vitals.',
        );
      case VitalsStatus.empty:
        return _buildMessage(
          icon: LucideIcons.heartPulse,
          title: 'No readings yet',
          message: 'Nothing has been recorded for this time range.',
        );
      case VitalsStatus.loaded:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKeyMeasurements(state),
            const SizedBox(height: 32),
            _buildTimeline(state.readings),
          ],
        );
    }
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMeasurements(VitalsState state) {
    final bpReading = state.latestBloodPressureReading;
    final heartRate = state.latestValueOf((r) => r.heartRate);
    final tempF = state.latestValueOf((r) => r.bodyTempF);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: bpReading != null
              ? _buildMeasurementCard(
                  'Blood Pressure',
                  '${bpReading.systolicBp!.toStringAsFixed(0)}/${bpReading.diastolicBp!.toStringAsFixed(0)}',
                  'mmHg',
                )
              : _buildEmptyMeasurementCard('Blood Pressure'),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: heartRate != null
              ? _buildMeasurementCard(
                  'Heart Rate',
                  heartRate.toStringAsFixed(0),
                  'BPM',
                )
              : _buildEmptyMeasurementCard('Heart Rate'),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: tempF != null
              ? _buildMeasurementCard(
                  'Temperature',
                  tempF.toStringAsFixed(1),
                  '°F',
                )
              : _buildEmptyMeasurementCard('Temperature'),
        ),
      ],
    );
  }

  // Title and value+unit are each wrapped in FittedBox(scaleDown) rather
  // than left to wrap naturally — three cards sharing a row leaves each one
  // only ~100dp wide, and a plain Text at these font sizes wraps mid-word
  // ("Temperature" -> "Temperatur"/"e") or mid-number ("118/76" -> "/7"/"6")
  // once the compound BP value or a longer vital name shows up. Shrinking to
  // fit handles any label/value/unit length generically instead of hardcoding
  // "Temperature" or "76" specifically, and keeps everything on one line.
  Widget _buildMeasurementCard(String title, String value, String unit) {
    return ClinicalCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMeasurementCard(String title) {
    return ClinicalCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No reading',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.border,
            ),
          ),
        ],
      ),
    );
  }

  /// One entry per reading *event*, not per vital type — a real reading can
  /// carry several vitals at once (see VitalReading's own doc comment), so
  /// splitting them into separate timeline rows would imply an asynchrony
  /// between them that the source data doesn't have.
  Widget _buildTimeline(List<VitalReading> readings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent readings",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        // Skip a reading event that carries no vitals at all — nothing to
        // show would otherwise render as a blank line between the
        // timestamp and source, which reads as a bug, not as "empty".
        for (final reading in readings.where((r) => !r.isEmpty)) ...[
          _buildTimelineItem(reading),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildTimelineItem(VitalReading reading) {
    final parts = <String>[];
    if (reading.hasBloodPressure) {
      parts.add(
        'BP ${reading.systolicBp!.toStringAsFixed(0)}/${reading.diastolicBp!.toStringAsFixed(0)}',
      );
    }
    if (reading.heartRate != null) {
      parts.add('HR ${reading.heartRate!.toStringAsFixed(0)} BPM');
    }
    if (reading.bodyTempF != null) {
      parts.add('${reading.bodyTempF!.toStringAsFixed(1)}°F');
    }
    if (reading.hemoglobin != null) {
      parts.add('Hb ${reading.hemoglobin!.toStringAsFixed(1)} g/dL');
    }
    if (reading.bloodGlucose != null) {
      parts.add('Glucose ${reading.bloodGlucose!.toStringAsFixed(0)} mg/dL');
    }
    if (reading.stressScore != null) {
      parts.add('Stress ${reading.stressScore!.toStringAsFixed(0)}/10');
    }
    if (reading.physActivityScore != null) {
      parts.add('Activity ${reading.physActivityScore!.toStringAsFixed(0)}/10');
    }

    final isDevice = reading.source == VitalSource.device;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 68,
          child: Text(
            _timeOfDay(reading.recordedAt),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 2,
          height: 44,
          color: AppColors.border,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                parts.join(' · '),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    isDevice ? LucideIcons.bluetooth : LucideIcons.userPlus,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isDevice ? 'Connected device' : 'Manual entry',
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
      ],
    );
  }
}
