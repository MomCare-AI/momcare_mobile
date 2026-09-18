/// Mirrors the real backend's wide-format reading event as closely as the
/// app can today (`momcare_platform/core/monitoring/models.py::VitalReading`
/// and its serializer, read-only inspected — not modified — while planning
/// this feature). One row is one reading *event*, which may carry several
/// vitals at once; every field is independently nullable, matching the real
/// model exactly — a reading does not have to carry all of them every time.
///
/// Two corrections versus this screen's original mockup, both load-bearing:
/// temperature is Fahrenheit (the real model's own docstring: "never
/// Celsius"), and there is no SpO2 field anywhere in the real backend — it
/// was invented by the mockup and is dropped here.
///
/// `source` is exactly `device`/`manual`, matching `VitalReading.SOURCE_CHOICES`
/// — no named-clinician attribution exists in the real API response today
/// (`VitalReadingSerializer` doesn't expose `recorded_by`), so this app must
/// not invent one either.
enum VitalSource { device, manual }

class VitalReading {
  VitalReading({
    required this.id,
    required this.recordedAt,
    required this.source,
    this.systolicBp,
    this.diastolicBp,
    this.heartRate,
    this.bodyTempF,
    this.hemoglobin,
    this.bloodGlucose,
    this.stressScore,
    this.physActivityScore,
  });

  final String id;
  final DateTime recordedAt;
  final VitalSource source;
  final double? systolicBp;
  final double? diastolicBp;
  final double? heartRate;
  final double? bodyTempF;
  final double? hemoglobin;
  final double? bloodGlucose;
  final double? stressScore;
  final double? physActivityScore;

  /// The backend rejects a systolic with no diastolic (or vice versa) at
  /// write time — a pair always arrives together, or not at all.
  bool get hasBloodPressure => systolicBp != null && diastolicBp != null;

  bool get isEmpty =>
      systolicBp == null &&
      diastolicBp == null &&
      heartRate == null &&
      bodyTempF == null &&
      hemoglobin == null &&
      bloodGlucose == null &&
      stressScore == null &&
      physActivityScore == null;
}

/// Sample data only — no backend endpoint exists yet for a patient to read
/// their own vitals (docs/patient-app-plan.md §6: the real endpoint,
/// `ReadingListCreateView`, is `IsHospitalStaff`-gated today). Deliberately
/// generic values, same discipline as `hospitals/models/hospital.dart`'s
/// sample data — swapped for a real repository call once that endpoint and a
/// patient-scoped permission exist, not guessed at here.
final sampleVitalReadings = <VitalReading>[
  VitalReading(
    id: 'v3',
    recordedAt: DateTime.now().subtract(const Duration(minutes: 18)),
    source: VitalSource.device,
    heartRate: 78,
    systolicBp: 118,
    diastolicBp: 76,
  ),
  VitalReading(
    id: 'v2',
    recordedAt: DateTime.now().subtract(const Duration(hours: 3)),
    source: VitalSource.manual,
    bodyTempF: 98.4,
  ),
  VitalReading(
    id: 'v1',
    recordedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    source: VitalSource.device,
    heartRate: 82,
    systolicBp: 122,
    diastolicBp: 79,
    stressScore: 4,
  ),
  VitalReading(
    id: 'v0',
    recordedAt: DateTime.now().subtract(const Duration(days: 9)),
    source: VitalSource.manual,
    hemoglobin: 11.8,
  ),
];
