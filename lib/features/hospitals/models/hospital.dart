/// Local sample data only — no backend integration this phase (see
/// docs/patient-app-plan.md §3a: real hospital search needs geocoding that
/// doesn't exist in the schema yet). Deliberately generic names/addresses,
/// not real hospitals, so nobody mistakes this for live data.
class Hospital {
  const Hospital({
    required this.name,
    required this.distanceLabel,
    required this.address,
  });

  final String name;
  final String distanceLabel;
  final String address;
}

const sampleHospitals = [
  Hospital(
    name: 'Sample Hospital 1',
    distanceLabel: '1.2 km away',
    address: 'Placeholder address, City',
  ),
  Hospital(
    name: 'Sample Hospital 2',
    distanceLabel: '3.4 km away',
    address: 'Placeholder address, City',
  ),
  Hospital(
    name: 'Sample Hospital 3',
    distanceLabel: '5.1 km away',
    address: 'Placeholder address, City',
  ),
];
