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
      super(const RealHospitalsState(status: RealHospitalsStatus.idle)) {
    // Dio's per-request Options only cover sendTimeout/receiveTimeout — the
    // *connection* phase (DNS + TCP/TLS handshake) has no cap unless set
    // here, on the client itself. Without this, an endpoint that's slow or
    // blocked to even connect to (not just slow to respond) can hang far
    // past the fallback loop's other timeouts, defeating the point of
    // having a second endpoint at all — confirmed on-device: kumi.systems
    // 429'd in ~1s, then osm.ch sat with no result for 40+ seconds.
    _dio.options.connectTimeout = const Duration(seconds: 8);
  }

  final Dio _dio;

  // overpass-api.de (the "main" public instance, and its lz4 mirror) returns
  // a bare 406 to every request from this network, with no Overpass-specific
  // error body — confirmed independently of this app via curl, so it's not
  // included here. kumi.systems and osm.ch are two different public mirrors
  // of the same OSM data that both work. Tried in order: public Overpass
  // instances rate-limit by IP, and mobile carriers commonly share one IP
  // across many subscribers (CGNAT) — confirmed via curl that kumi.systems
  // can 429 one caller while responding 200 to another at the same moment —
  // so a second, independently-run mirror is a real fallback, not a
  // theoretical one.
  static const _endpoints = [
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass.osm.ch/api/interpreter',
  ];

  // Basic in-memory cache of the last successful fetch — session-local,
  // same as everywhere else in this app (lost on app restart, never
  // persisted). Re-opening Hospital Discovery at essentially the same
  // location shouldn't re-hit a free, shared, rate-limited public API for
  // no reason; an explicit Retry (forceRefresh) or a real location change
  // always goes to the network regardless of this cache.
  LatLng? _cachedCenter;
  DateTime? _cachedAt;
  static const _cacheRadiusMeters = 500.0;
  static const _cacheTtl = Duration(minutes: 10);

  bool _hasFreshCacheFor(LatLng center) {
    if (state.status != RealHospitalsStatus.loaded) return false;
    final cachedCenter = _cachedCenter;
    final cachedAt = _cachedAt;
    if (cachedCenter == null || cachedAt == null) return false;
    final distance = Geolocator.distanceBetween(
      center.latitude,
      center.longitude,
      cachedCenter.latitude,
      cachedCenter.longitude,
    );
    if (distance > _cacheRadiusMeters) return false;
    return DateTime.now().difference(cachedAt) < _cacheTtl;
  }

  Future<void> fetchNearby(
    LatLng center, {
    double radiusMeters = 5000,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _hasFreshCacheFor(center)) return;

    state = state.copyWith(status: RealHospitalsStatus.loading);

    final query =
        '[out:json][timeout:25];'
        '('
        'node["amenity"="hospital"](around:$radiusMeters,${center.latitude},${center.longitude});'
        'way["amenity"="hospital"](around:$radiusMeters,${center.latitude},${center.longitude});'
        ');'
        'out center;';

    Object? lastError;
    for (final endpoint in _endpoints) {
      try {
        // Dio's own sendTimeout/receiveTimeout didn't reliably bound a real
        // on-device stall — confirmed empirically: a request to the second
        // mirror sat for 60+ seconds with the app in the foreground, no
        // success or failure, well past both configured timeouts (most
        // likely DNS resolution stalling in a way those timeouts don't
        // cover on that network). An explicit Future.timeout() here is a
        // hard backstop, independent of whatever Dio/dart:io is doing
        // internally — it always moves on to the next endpoint on schedule.
        final response = await _dio
            .post(
              endpoint,
              data: {'data': query},
              options: Options(
                contentType: Headers.formUrlEncodedContentType,
                sendTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            )
            .timeout(const Duration(seconds: 12));

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

        _cachedCenter = center;
        _cachedAt = DateTime.now();
        state = state.copyWith(
          status: RealHospitalsStatus.loaded,
          hospitals: withDistance,
        );
        return;
      } catch (e) {
        // ignore: avoid_print
        print('Overpass fetch failed ($endpoint): $e');
        lastError = e;
        // Try the next endpoint, if any are left.
      }
    }

    // Every endpoint failed.
    final rateLimited =
        lastError is DioException && lastError.response?.statusCode == 429;
    state = state.copyWith(
      status: RealHospitalsStatus.error,
      errorMessage: rateLimited
          ? 'Hospital search is busy right now. Please try again in a moment.'
          : 'Could not load nearby hospitals. Check your connection and try again.',
    );
  }
}

final realHospitalsProvider =
    StateNotifierProvider<RealHospitalsNotifier, RealHospitalsState>((ref) {
      return RealHospitalsNotifier();
    });
