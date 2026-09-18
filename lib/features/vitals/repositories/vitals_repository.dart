import '../models/vital_reading.dart';

/// No real backend endpoint exists yet for a patient to read their own
/// vitals — `core/monitoring/api/views.py::ReadingListCreateView` is
/// `IsHospitalStaff`-gated today, and a patient-scoped equivalent is named
/// but not built (docs/patient-app-plan.md §6). This repository returns
/// sample data shaped exactly like the real `VitalReadingSerializer`
/// contract, so wiring the real endpoint later is a change to this file
/// only — the provider and screen don't need to know the difference.
class VitalsRepository {
  Future<List<VitalReading>> fetchReadings({required DateTime since}) async {
    // Simulated latency so loading states are actually exercised rather than
    // resolving instantly every time.
    await Future.delayed(const Duration(milliseconds: 400));

    final readings = sampleVitalReadings
        .where((reading) => reading.recordedAt.isAfter(since))
        .toList();
    // Matches the real endpoint's own ordering (`-recorded_at`) — never
    // assume list-literal order is display order.
    readings.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return readings;
  }
}
