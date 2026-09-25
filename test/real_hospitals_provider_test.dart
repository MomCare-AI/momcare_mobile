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

/// A queue of per-call outcomes (thrown error or a json body+statusCode),
/// consumed one per `fetch()` call — for exercising the endpoint-fallback
/// loop (first call throws, second succeeds) and counting how many network
/// calls actually happened (for the caching tests, where the right number
/// is zero).
class _SequenceAdapter implements HttpClientAdapter {
  _SequenceAdapter(this._steps);

  final List<Object> _steps; // each is either an Exception or a Map body
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final step = _steps[callCount];
    callCount++;
    if (step is Exception) throw step;
    return ResponseBody.fromString(
      jsonEncode(step),
      200,
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
  const farCenter = LatLng(
    24.8607,
    67.0011,
  ); // Karachi — well outside cache radius

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

    test(
      'falls back to the second endpoint when the first one fails',
      () async {
        final adapter = _SequenceAdapter([
          DioException(
            requestOptions: RequestOptions(path: '/'),
            response: Response(
              requestOptions: RequestOptions(path: '/'),
              statusCode: 429,
            ),
            type: DioExceptionType.badResponse,
          ),
          {
            'elements': [
              {
                'type': 'node',
                'id': 1,
                'lat': 33.7300,
                'lon': 73.0935,
                'tags': {'name': 'Fallback Hospital'},
              },
            ],
          },
        ]);
        final dio = Dio()..httpClientAdapter = adapter;

        final notifier = RealHospitalsNotifier(dio: dio);
        await notifier.fetchNearby(center);

        expect(adapter.callCount, 2, reason: 'first endpoint, then second');
        expect(notifier.state.status, RealHospitalsStatus.loaded);
        expect(
          notifier.state.hospitals.single['hospital'].name,
          'Fallback Hospital',
        );
      },
    );

    test(
      'uses a rate-limit-specific message when every endpoint 429s',
      () async {
        final rateLimited = DioException(
          requestOptions: RequestOptions(path: '/'),
          response: Response(
            requestOptions: RequestOptions(path: '/'),
            statusCode: 429,
          ),
          type: DioExceptionType.badResponse,
        );
        final dio = Dio()
          ..httpClientAdapter = _SequenceAdapter([rateLimited, rateLimited]);

        final notifier = RealHospitalsNotifier(dio: dio);
        await notifier.fetchNearby(center);

        expect(notifier.state.status, RealHospitalsStatus.error);
        expect(notifier.state.errorMessage, contains('busy'));
      },
    );

    test('a second fetch at essentially the same location reuses the cache '
        'instead of hitting the network again', () async {
      final adapter = _SequenceAdapter([
        {'elements': []},
      ]);
      final dio = Dio()..httpClientAdapter = adapter;
      final notifier = RealHospitalsNotifier(dio: dio);

      await notifier.fetchNearby(center);
      // A few meters off, same neighborhood — well inside the cache radius.
      await notifier.fetchNearby(const LatLng(33.7295, 73.0932));

      expect(
        adapter.callCount,
        1,
        reason: 'second call should be served from cache, no network hit',
      );
      expect(notifier.state.status, RealHospitalsStatus.loaded);
    });

    test(
      'forceRefresh bypasses the cache and hits the network again',
      () async {
        final adapter = _SequenceAdapter([
          {'elements': []},
          {'elements': []},
        ]);
        final dio = Dio()..httpClientAdapter = adapter;
        final notifier = RealHospitalsNotifier(dio: dio);

        await notifier.fetchNearby(center);
        await notifier.fetchNearby(center, forceRefresh: true);

        expect(adapter.callCount, 2);
      },
    );

    test(
      'a fetch for a genuinely different location bypasses the cache',
      () async {
        final adapter = _SequenceAdapter([
          {'elements': []},
          {'elements': []},
        ]);
        final dio = Dio()..httpClientAdapter = adapter;
        final notifier = RealHospitalsNotifier(dio: dio);

        await notifier.fetchNearby(center);
        await notifier.fetchNearby(farCenter);

        expect(adapter.callCount, 2);
      },
    );
  });
}
