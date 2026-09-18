/// A real hospital pulled from OpenStreetMap (via the Overpass API), not
/// from MomCare's own database — these are not MomCare customers, so there
/// is no account, no appointment system, nothing to "request" here. The map
/// screen offers directions instead. See hospital_discovery_screen.dart.
class RealHospital {
  const RealHospital({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  /// Builds a [RealHospital] from one Overpass `out center;` element, or
  /// returns null if it has no usable coordinates.
  static RealHospital? fromOverpassElement(Map<String, dynamic> element) {
    final tags = (element['tags'] as Map<String, dynamic>?) ?? const {};

    double? lat = (element['lat'] as num?)?.toDouble();
    double? lon = (element['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) {
      final center = element['center'] as Map<String, dynamic>?;
      lat = (center?['lat'] as num?)?.toDouble();
      lon = (center?['lon'] as num?)?.toDouble();
    }
    if (lat == null || lon == null) return null;

    final addressParts = [
      tags['addr:housenumber'],
      tags['addr:street'],
      tags['addr:city'],
    ].whereType<String>().where((part) => part.trim().isNotEmpty).toList();

    return RealHospital(
      id: '${element['type']}_${element['id']}',
      name: (tags['name'] as String?)?.trim().isNotEmpty == true
          ? tags['name'] as String
          : 'Unnamed hospital',
      address: addressParts.isNotEmpty
          ? addressParts.join(', ')
          : 'Address not available',
      latitude: lat,
      longitude: lon,
    );
  }
}
