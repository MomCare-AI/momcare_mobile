import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:momcare_mobile/features/hospitals/providers/real_hospitals_provider.dart';

/// A minimal fake HttpClientAdapter — no mocking package needed, dio
/// exposes this seam itself. Returns whatever the test configures,
/// regardless of the request, so these tests only exercise
/// RealHospitalsNotifier's own parsing/sorting/error-handling logic.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter.json(Map<String, dynamic> body, {int statusCode = 200})
    : _statusCode = statusCode,
      _text = jsonEncode(body),
      _throws = null;

  _FakeAdapter.throwing(Object error)
    : _statusCode = 0,
      _text = null,
      _throws = error;

  final int _statusCode;
  final String? _text;
  final Object? _throws;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (_throws != null) throw _throws;
    return ResponseBody.fromString(
      _text!,
      _statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const center = LatLng(33.7294, 73.0931);

  group('RealHospitalsNotifier.fetchNearby', () {
    test(
      'parses a real-shaped Overpass response and sorts by distance',
      () async {
        final dio = Dio()
          ..httpClientAdapter = _FakeAdapter.json({
            'elements': [
              // Farther one listed first in the raw response — sort must fix
              // this, not just pass through response order.
              {
                'type': 'node',
                'id': 1,
                'lat': 33.80, // several km further from `center`
                'lon': 73.10,
                'tags': {'name': 'Far Hospital'},
              },
              {
                'type': 'node',
                'id': 2,
                'lat': 33.7300, // very close to `center`
                'lon': 73.0935,
                'tags': {'name': 'Near Hospital'},
              },
            ],
          });

        final notifier = RealHospitalsNotifier(dio: dio);
        await notifier.fetchNearby(center);

        expect(notifier.state.status, RealHospitalsStatus.loaded);
        expect(notifier.state.hospitals, hasLength(2));
        expect(
          (notifier.state.hospitals[0]['hospital']).name,
          'Near Hospital',
          reason: 'Closer hospital must sort first regardless of API order',
        );
        expect(
          notifier.state.hospitals[0]['distanceKm'] <
              notifier.state.hospitals[1]['distanceKm'],
          isTrue,
        );
      },
    );

    test(
      'drops elements with no usable coordinates instead of crashing',
      () async {
        final dio = Dio()
          ..httpClientAdapter = _FakeAdapter.json({
            'elements': [
              {
                'type': 'node',
                'id': 1,
                'tags': {'name': 'No Coordinates'},
              },
              {
                'type': 'node',
                'id': 2,
                'lat': 33.73,
                'lon': 73.09,
                'tags': {'name': 'Has Coordinates'},
              },
            ],
          });

        final notifier = RealHospitalsNotifier(dio: dio);
        await notifier.fetchNearby(center);

        expect(notifier.state.status, RealHospitalsStatus.loaded);
        expect(notifier.state.hospitals, hasLength(1));
        expect(
          notifier.state.hospitals.single['hospital'].name,
          'Has Coordinates',
        );
      },
    );

    test(
      'moves to loaded with an empty list when Overpass finds nothing',
      () async {
        final dio = Dio()
          ..httpClientAdapter = _FakeAdapter.json({'elements': []});

        final notifier = RealHospitalsNotifier(dio: dio);
        await notifier.fetchNearby(center);

        expect(notifier.state.status, RealHospitalsStatus.loaded);
        expect(notifier.state.hospitals, isEmpty);
      },
    );

    test('moves to error, with a message, when the request throws', () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter.throwing(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.connectionError,
          ),
        );

      final notifier = RealHospitalsNotifier(dio: dio);
      await notifier.fetchNearby(center);

      expect(notifier.state.status, RealHospitalsStatus.error);
      expect(notifier.state.errorMessage, isNotNull);
    });

    test('sets status to loading immediately, before the request resolves', () {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter.json({'elements': []});
      final notifier = RealHospitalsNotifier(dio: dio);

      expect(notifier.state.status, RealHospitalsStatus.idle);
      final future = notifier.fetchNearby(center);
      expect(notifier.state.status, RealHospitalsStatus.loading);

      return future;
    });
  });
}
