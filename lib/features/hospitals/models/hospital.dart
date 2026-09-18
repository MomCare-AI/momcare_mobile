/// Local sample data only — no backend integration this phase (see
/// docs/patient-app-plan.md §3a: real hospital search needs geocoding that
/// doesn't exist in the schema yet). Deliberately generic names/addresses,
/// not real hospitals, so nobody mistakes this for live data.
///
/// Positioned as an offset in km from wherever the tester's real GPS is,
/// not fixed real-world coordinates — a fixed Islamabad location looked
/// "broken" (no hospitals visible) the moment testing happened from Kahuta,
/// 30km away. Relative placement means it always looks genuinely nearby,
/// regardless of where the device actually is.
class Hospital {
  const Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.offsetNorthKm,
    required this.offsetEastKm,
  });

  final String id;
  final String name;
  final String address;

  /// Offset from the device's live location, in kilometres.
  final double offsetNorthKm;
  final double offsetEastKm;
}

// Some dummy hospitals spread out a bit around wherever "here" is.
const sampleHospitals = [
  Hospital(
    id: 'h1',
    name: 'Maternal & Women\'s Care Center',
    address: '123 Health Ave, North District',
    offsetNorthKm: 1.2,
    offsetEastKm: 0.6,
  ),
  Hospital(
    id: 'h2',
    name: 'City General Hospital',
    address: '456 Medical Parkway, West End',
    offsetNorthKm: -0.8,
    offsetEastKm: -1.6,
  ),
  Hospital(
    id: 'h3',
    name: 'Hope Maternity Clinic',
    address: '789 Care Blvd, South Side',
    offsetNorthKm: 2.1,
    offsetEastKm: 1.4,
  ),
];
