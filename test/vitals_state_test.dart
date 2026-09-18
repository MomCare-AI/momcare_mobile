import 'package:flutter_test/flutter_test.dart';

import 'package:momcare_mobile/features/vitals/models/vital_reading.dart';
import 'package:momcare_mobile/features/vitals/providers/vitals_provider.dart';

void main() {
  // Deliberately not using sampleVitalReadings here — these readings are
  // hand-built per test so each case's intent is visible without cross-
  // referencing the sample data file.
  group('latestValueOf', () {
    test('returns the newest non-null value, not the single latest reading',
        () {
      final now = DateTime.now();
      final state = VitalsState(
        status: VitalsStatus.loaded,
        readings: [
          // Newest first, matching real backend + repository ordering.
          VitalReading(
            id: 'newest',
            recordedAt: now,
            source: VitalSource.device,
            // No hemoglobin on the newest reading — a band doesn't report it.
          ),
          VitalReading(
            id: 'older',
            recordedAt: now.subtract(const Duration(days: 5)),
            source: VitalSource.manual,
            hemoglobin: 11.5,
          ),
        ],
      );

      // The naive "read the latest reading only" bug this test guards
      // against would return null here instead of 11.5.
      expect(state.latestValueOf((r) => r.hemoglobin), 11.5);
    });

    test('returns null when no reading ever carried the vital', () {
      final state = VitalsState(
        status: VitalsStatus.loaded,
        readings: [
          VitalReading(
            id: 'r1',
            recordedAt: DateTime.now(),
            source: VitalSource.device,
            heartRate: 78,
          ),
        ],
      );

      expect(state.latestValueOf((r) => r.hemoglobin), isNull);
    });
  });

  group('latestBloodPressureReading', () {
    test('skips a reading missing either half of the pair', () {
      final now = DateTime.now();
      final state = VitalsState(
        status: VitalsStatus.loaded,
        readings: [
          // Newest reading has heart rate but no BP pair at all.
          VitalReading(
            id: 'newest',
            recordedAt: now,
            source: VitalSource.device,
            heartRate: 80,
          ),
          // Older reading has a real, complete BP pair.
          VitalReading(
            id: 'older',
            recordedAt: now.subtract(const Duration(hours: 6)),
            source: VitalSource.device,
            systolicBp: 120,
            diastolicBp: 78,
          ),
        ],
      );

      final result = state.latestBloodPressureReading;
      expect(result, isNotNull);
      expect(result!.id, 'older');
    });

    test('never combines two different readings\' halves', () {
      // A reading with only systolic (no diastolic) should never be treated
      // as a usable blood-pressure reading, even if an older one has a
      // diastolic value — the pair must come from the same event.
      final now = DateTime.now();
      final state = VitalsState(
        status: VitalsStatus.loaded,
        readings: [
          VitalReading(
            id: 'systolic-only',
            recordedAt: now,
            source: VitalSource.device,
            systolicBp: 130,
          ),
          VitalReading(
            id: 'diastolic-only',
            recordedAt: now.subtract(const Duration(hours: 1)),
            source: VitalSource.device,
            diastolicBp: 82,
          ),
        ],
      );

      expect(state.latestBloodPressureReading, isNull);
    });
  });
}
