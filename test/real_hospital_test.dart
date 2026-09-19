import 'package:flutter_test/flutter_test.dart';

import 'package:momcare_mobile/features/hospitals/models/real_hospital.dart';

void main() {
  group('RealHospital.fromOverpassElement', () {
    test('parses a node with lat/lon directly on the element', () {
      final hospital = RealHospital.fromOverpassElement({
        'type': 'node',
        'id': 123,
        'lat': 33.7211,
        'lon': 73.0828,
        'tags': {'name': 'Poly Clinic Hospital', 'addr:city': 'Islamabad'},
      });

      expect(hospital, isNotNull);
      expect(hospital!.id, 'node_123');
      expect(hospital.name, 'Poly Clinic Hospital');
      expect(hospital.address, 'Islamabad');
      expect(hospital.latitude, 33.7211);
      expect(hospital.longitude, 73.0828);
    });

    test('parses a way using its center object, not top-level lat/lon', () {
      final hospital = RealHospital.fromOverpassElement({
        'type': 'way',
        'id': 456,
        'center': {'lat': 33.71, 'lon': 73.05},
        'tags': {'name': 'Some Hospital'},
      });

      expect(hospital, isNotNull);
      expect(hospital!.id, 'way_456');
      expect(hospital.latitude, 33.71);
      expect(hospital.longitude, 73.05);
    });

    test('returns null when neither lat/lon nor center exist', () {
      final hospital = RealHospital.fromOverpassElement({
        'type': 'node',
        'id': 789,
        'tags': {'name': 'No Coordinates Hospital'},
      });

      expect(hospital, isNull);
    });

    test('falls back to "Unnamed hospital" when the name tag is missing', () {
      final hospital = RealHospital.fromOverpassElement({
        'type': 'node',
        'id': 1,
        'lat': 1.0,
        'lon': 1.0,
        'tags': <String, dynamic>{},
      });

      expect(hospital!.name, 'Unnamed hospital');
    });

    test('falls back to "Unnamed hospital" when the name is blank', () {
      final hospital = RealHospital.fromOverpassElement({
        'type': 'node',
        'id': 1,
        'lat': 1.0,
        'lon': 1.0,
        'tags': {'name': '   '},
      });

      expect(hospital!.name, 'Unnamed hospital');
    });

    test(
      'falls back to "Address not available" when no address tags exist',
      () {
        final hospital = RealHospital.fromOverpassElement({
          'type': 'node',
          'id': 1,
          'lat': 1.0,
          'lon': 1.0,
          'tags': {'name': 'X Hospital'},
        });

        expect(hospital!.address, 'Address not available');
      },
    );

    test('joins only the address parts that are actually present', () {
      final hospital = RealHospital.fromOverpassElement({
        'type': 'node',
        'id': 1,
        'lat': 1.0,
        'lon': 1.0,
        'tags': {
          'name': 'X Hospital',
          // No addr:housenumber — should not produce an empty leading part.
          'addr:street': 'Jinnah Avenue',
          'addr:city': 'Islamabad',
        },
      });

      expect(hospital!.address, 'Jinnah Avenue, Islamabad');
    });

    test('has no tags key at all (real-world Overpass shape)', () {
      // Overpass sometimes omits "tags" entirely rather than sending {}.
      final hospital = RealHospital.fromOverpassElement({
        'type': 'node',
        'id': 1,
        'lat': 1.0,
        'lon': 1.0,
      });

      expect(hospital, isNotNull);
      expect(hospital!.name, 'Unnamed hospital');
      expect(hospital.address, 'Address not available');
    });
  });
}
