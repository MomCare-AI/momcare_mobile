import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/real_hospital.dart';

enum RealHospitalsStatus { idle, loading, loaded, error }

class RealHospitalsState {
  const RealHospitalsState({
    required this.status,
    this.hospitals = const [],
    this.errorMessage,
  });

  final RealHospitalsStatus status;

  /// Each entry: {'hospital': RealHospital, 'distanceKm': double}.
  final List<Map<String, dynamic>> hospitals;
  final String? errorMessage;

  RealHospitalsState copyWith({
    RealHospitalsStatus? status,
    List<Map<String, dynamic>>? hospitals,
    String? errorMessage,
  }) {
    return RealHospitalsState(
      status: status ?? this.status,
      hospitals: hospitals ?? this.hospitals,
      errorMessage: errorMessage,
    );
  }
}

/// Queries OpenStreetMap's Overpass API for real `amenity=hospital` points
/// near a location — no API key, no billing account, no MomCare backend.
/// See docs/patient-app-plan.md §3a: these are real-world hospitals, not
/// MomCare accounts, so there is no appointment relationship to offer here.
class RealHospitalsNotifier extends StateNotifier<RealHospitalsState> {
  RealHospitalsNotifier({Dio? dio})
    : _dio = dio ?? Dio(),
      super(const RealHospitalsState(status: RealHospitalsStatus.idle));

  final Dio _dio;

  Future<void> fetchNearby(LatLng center, {double radiusMeters = 5000}) async {
    state = state.copyWith(status: RealHospitalsStatus.loading);

    final query =
        '[out:json][timeout:25];'
        '('
        'node["amenity"="hospital"](around:$radiusMeters,${center.latitude},${center.longitude});'
        'way["amenity"="hospital"](around:$radiusMeters,${center.latitude},${center.longitude});'
        ');'
        'out center;';

    try {
      // overpass-api.de (the "main" public instance) returns a bare 406 to
      // every request from this network, with no Overpass-specific error
      // body — confirmed independently of this app via curl. kumi.systems
      // is a different public mirror of the same OSM data that works.
      final response = await _dio.post(
        'https://overpass.kumi.systems/api/interpreter',
        data: {'data': query},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final elements =
          ((response.data as Map<String, dynamic>)['elements'] as List)
              .cast<Map<String, dynamic>>();

      final hospitals = elements
          .map(RealHospital.fromOverpassElement)
          .whereType<RealHospital>()
          .toList();

      final withDistance = hospitals.map((hospital) {
        final distanceMeters = Geolocator.distanceBetween(
          center.latitude,
          center.longitude,
          hospital.latitude,
          hospital.longitude,
        );
        return {'hospital': hospital, 'distanceKm': distanceMeters / 1000.0};
      }).toList();

      withDistance.sort(
        (a, b) =>
            (a['distanceKm'] as double).compareTo(b['distanceKm'] as double),
      );

      state = state.copyWith(
        status: RealHospitalsStatus.loaded,
        hospitals: withDistance,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Overpass fetch failed: $e');
      state = state.copyWith(
        status: RealHospitalsStatus.error,
        errorMessage:
            'Could not load nearby hospitals. Check your connection and try again.',
      );
    }
  }
}

final realHospitalsProvider =
    StateNotifierProvider<RealHospitalsNotifier, RealHospitalsState>((ref) {
      return RealHospitalsNotifier();
    });
