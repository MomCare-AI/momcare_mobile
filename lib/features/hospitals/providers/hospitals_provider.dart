import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/hospital.dart';
import 'location_provider.dart';

const double _kmPerDegreeLat = 111.0;

double _kmPerDegreeLon(double atLatitude) =>
    111.320 * cos(atLatitude * pi / 180);

/// Turns a hospital's north/east offset (km) into a real LatLng near
/// [origin] — see Hospital's own doc comment for why this is relative
/// rather than a fixed real-world coordinate.
LatLng _resolvePosition(LatLng origin, Hospital hospital) {
  final dLat = hospital.offsetNorthKm / _kmPerDegreeLat;
  final dLon = hospital.offsetEastKm / _kmPerDegreeLon(origin.latitude);
  return LatLng(origin.latitude + dLat, origin.longitude + dLon);
}

final nearbyHospitalsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final locationState = ref.watch(locationProvider);
  final userLocation = locationState.currentLocation;

  if (userLocation == null) {
    return [];
  }

  // Resolve each hospital's position relative to the live location, then
  // calculate its distance the same way regardless of where that turns out
  // to be.
  final hospitalsWithDistance = sampleHospitals.map((hospital) {
    final position = _resolvePosition(userLocation, hospital);
    final distanceMeters = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      position.latitude,
      position.longitude,
    );
    return {
      'hospital': hospital,
      'position': position,
      'distanceKm': distanceMeters / 1000.0,
    };
  }).toList();

  // Sort by distance (closest first)
  hospitalsWithDistance.sort(
    (a, b) => (a['distanceKm'] as double).compareTo(b['distanceKm'] as double),
  );

  return hospitalsWithDistance;
});
