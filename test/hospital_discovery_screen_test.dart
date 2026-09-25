import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:momcare_mobile/features/hospitals/models/real_hospital.dart';
import 'package:momcare_mobile/features/hospitals/providers/location_provider.dart';
import 'package:momcare_mobile/features/hospitals/providers/real_hospitals_provider.dart';
import 'package:momcare_mobile/features/hospitals/screens/hospital_discovery_screen.dart';
import 'package:momcare_mobile/features/hospitals/widgets/distance_pill.dart';
import 'package:momcare_mobile/features/hospitals/widgets/hospital_list_sheet.dart';
import 'package:momcare_mobile/features/hospitals/widgets/selected_hospital_card.dart';

/// Seeds a fixed LocationState without ever touching the real Geolocator
/// platform channel — these tests are about the screen's own wiring
/// (map/list/card sync, permission-state overlays), not the permission flow
/// itself.
class _FakeLocationNotifier extends LocationNotifier {
  _FakeLocationNotifier(LocationState initial) {
    state = initial;
  }

  bool stopTrackingCalled = false;

  @override
  Future<void> requestPermissionAndStartTracking() async {
    // No-op. HospitalDiscoveryScreen's initState() calls this itself
    // whenever it sees permissionState == granted (to resume tracking
    // after e.g. an app restart) — without this override, that immediately
    // overwrites a seeded "granted" state with "loading" (the real
    // method's first line), via a real, unmocked Geolocator call. The
    // permission-request flow itself isn't what these tests check.
  }

  @override
  void stopTracking() {
    stopTrackingCalled = true;
    super.stopTracking();
  }
}

class _FakeRealHospitalsNotifier extends RealHospitalsNotifier {
  _FakeRealHospitalsNotifier(RealHospitalsState initial) {
    state = initial;
  }

  @override
  Future<void> fetchNearby(
    LatLng center, {
    double radiusMeters = 5000,
    bool forceRefresh = false,
  }) async {
    // No-op. HospitalDiscoveryScreen's own preserved side effect calls
    // fetchNearby the moment a location is known — without this override,
    // that would immediately overwrite the state these tests seed with a
    // real, unmocked network call. The real fetch flow (including fallback
    // endpoints and caching) is covered separately in
    // real_hospitals_provider_test.dart.
  }
}

/// Returns flutter_map's own built-in 1x1 transparent PNG for every tile,
/// entirely offline — no network access exists in the test sandbox, so a
/// real NetworkTileProvider would fail every request (expected, but noisy
/// and irrelevant to what these tests actually check: the screen's own
/// wiring, not whether map tiles render). HospitalMap/HospitalDiscoveryScreen
/// both default to the real network provider in production — this is
/// test-only, injected explicitly below.
class _FakeTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(TileProvider.transparentImage);
  }
}

void main() {
  const userLocation = LatLng(33.7294, 73.0931);

  final hospitalA = RealHospital(
    id: 'a',
    name: 'Alpha Hospital',
    address: 'Street 1',
    latitude: 33.7300,
    longitude: 73.0935,
  );
  final hospitalB = RealHospital(
    id: 'b',
    name: 'Beta Hospital',
    address: 'Street 2',
    latitude: 33.7350,
    longitude: 73.1000,
  );

  final loadedHospitalsState = RealHospitalsState(
    status: RealHospitalsStatus.loaded,
    hospitals: [
      {'hospital': hospitalA, 'distanceKm': 1.2},
      {'hospital': hospitalB, 'distanceKm': 3.4},
    ],
  );

  Widget wrap({
    required LocationState locationState,
    required RealHospitalsState hospitalsState,
  }) {
    return ProviderScope(
      overrides: [
        locationProvider.overrideWith(
          (ref) => _FakeLocationNotifier(locationState),
        ),
        realHospitalsProvider.overrideWith(
          (ref) => _FakeRealHospitalsNotifier(hospitalsState),
        ),
      ],
      child: MaterialApp(
        home: HospitalDiscoveryScreen(tileProvider: _FakeTileProvider()),
      ),
    );
  }

  group('permission-state overlays', () {
    testWidgets('undetermined shows the permission explanation', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          locationState: LocationState(
            permissionState: LocationPermissionState.undetermined,
          ),
          hospitalsState: const RealHospitalsState(
            status: RealHospitalsStatus.idle,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Find maternal care near you'), findsOneWidget);
    });

    testWidgets('denied shows the "enable location" error state', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          locationState: LocationState(
            permissionState: LocationPermissionState.denied,
          ),
          hospitalsState: const RealHospitalsState(
            status: RealHospitalsStatus.idle,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Location access is off'), findsOneWidget);
    });

    testWidgets('permanentlyDenied shows the "open settings" error state', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          locationState: LocationState(
            permissionState: LocationPermissionState.permanentlyDenied,
          ),
          hospitalsState: const RealHospitalsState(
            status: RealHospitalsStatus.idle,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Location permission denied'), findsOneWidget);
    });
  });

  group('map/list/card sync (granted + loaded)', () {
    testWidgets('shows the list sheet by default, not the selected card', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          locationState: LocationState(
            permissionState: LocationPermissionState.granted,
            currentLocation: userLocation,
          ),
          hospitalsState: loadedHospitalsState,
        ),
      );
      await tester.pump();

      expect(find.byType(HospitalListSheet), findsOneWidget);
      expect(find.byType(SelectedHospitalCard), findsNothing);
      expect(find.text('Alpha Hospital'), findsOneWidget);
      // The sheet's ListView is lazy and only builds what fits its
      // initialChildSize (0.4 of an 800x600 test surface) — Beta isn't
      // built yet at this point, not just scrolled off-screen. Scroll the
      // list itself (not ensureVisible, which needs the target to already
      // exist in the tree) to force it to build.
      await tester.scrollUntilVisible(
        find.text('Beta Hospital'),
        100,
        scrollable: find.descendant(
          of: find.byType(HospitalListSheet),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('Beta Hospital'), findsOneWidget);
    });

    testWidgets(
      'tapping a map marker selects that hospital and hides the list',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            locationState: LocationState(
              permissionState: LocationPermissionState.granted,
              currentLocation: userLocation,
            ),
            hospitalsState: loadedHospitalsState,
          ),
        );
        await tester.pump();

        // Two DistancePill markers exist on the map — tap the first (Alpha,
        // closer, sorted first).
        final pills = find.byType(DistancePill);
        expect(pills, findsNWidgets(2));
        await tester.tap(pills.first);
        await tester.pump();

        expect(find.byType(SelectedHospitalCard), findsOneWidget);
        expect(find.byType(HospitalListSheet), findsNothing);
        expect(find.text('Alpha Hospital'), findsOneWidget);
      },
    );

    testWidgets('tapping a hospital in the list selects it the same way', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          locationState: LocationState(
            permissionState: LocationPermissionState.granted,
            currentLocation: userLocation,
          ),
          hospitalsState: loadedHospitalsState,
        ),
      );
      await tester.pump();

      // Beta isn't built by the lazy ListView until scrolled into range —
      // see the same note in the previous test.
      await tester.scrollUntilVisible(
        find.text('Beta Hospital'),
        100,
        scrollable: find.descendant(
          of: find.byType(HospitalListSheet),
          matching: find.byType(Scrollable),
        ),
      );
      // A tap immediately after a scroll on a nested Scrollable leaves the
      // scroll gesture's "hold" state unreleased (a known Flutter test
      // framework edge case: ScrollableState's '_hold == null' assertion).
      // No infinite ticker on this screen (unlike onboarding's
      // AutoScrollingRow), so pumpAndSettle() is safe here and fully
      // flushes the gesture arena, unlike a fixed-duration pump.
      await tester.pumpAndSettle();
      await tester.tap(find.text('Beta Hospital'));
      await tester.pump();

      expect(find.byType(SelectedHospitalCard), findsOneWidget);
      // The card shows Beta's own distance, not Alpha's — scoped to inside
      // the card specifically, since the map's own DistancePill marker for
      // Beta also legitimately contains "3.4 km" as a substring.
      expect(
        find.descendant(
          of: find.byType(SelectedHospitalCard),
          matching: find.textContaining('3.4 km'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('closing the selected card returns to the list', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          locationState: LocationState(
            permissionState: LocationPermissionState.granted,
            currentLocation: userLocation,
          ),
          hospitalsState: loadedHospitalsState,
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(DistancePill).first);
      await tester.pump();
      expect(find.byType(SelectedHospitalCard), findsOneWidget);

      // SelectedHospitalCard's close button uses LucideIcons.x, not
      // Material's Icons.close.
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump();

      expect(find.byType(SelectedHospitalCard), findsNothing);
      expect(find.byType(HospitalListSheet), findsOneWidget);
    });
  });

  group('hospital-loading overlays (granted, no location gate)', () {
    testWidgets('shows a status pill while hospitals are loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          locationState: LocationState(
            permissionState: LocationPermissionState.granted,
            currentLocation: userLocation,
          ),
          hospitalsState: const RealHospitalsState(
            status: RealHospitalsStatus.loading,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Finding real hospitals nearby…'), findsOneWidget);
    });

    testWidgets('shows a retry pill on error, with the real error message', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          locationState: LocationState(
            permissionState: LocationPermissionState.granted,
            currentLocation: userLocation,
          ),
          hospitalsState: const RealHospitalsState(
            status: RealHospitalsStatus.error,
            errorMessage:
                'Could not load nearby hospitals. Check your connection and try again.',
          ),
        ),
      );
      await tester.pump();

      // Now shown in two places by design: the top RetryPill overlay and
      // HospitalListSheet's own error state (previously the sheet showed
      // nothing at all on error — just blank space under the title).
      expect(
        find.text(
          'Could not load nearby hospitals. Check your connection and try again.',
        ),
        findsNWidgets(2),
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('lifecycle', () {
    testWidgets('leaving the screen stops the location stream', (tester) async {
      // Built inline rather than via wrap() so the test can hold a
      // reference to the fake notifier and check it after disposal.
      final fakeNotifier = _FakeLocationNotifier(
        LocationState(
          permissionState: LocationPermissionState.granted,
          currentLocation: userLocation,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationProvider.overrideWith((ref) => fakeNotifier),
            realHospitalsProvider.overrideWith(
              (ref) => _FakeRealHospitalsNotifier(loadedHospitalsState),
            ),
          ],
          child: MaterialApp(
            home: HospitalDiscoveryScreen(tileProvider: _FakeTileProvider()),
          ),
        ),
      );
      await tester.pump();

      expect(fakeNotifier.stopTrackingCalled, isFalse);

      // Replace the whole tree so HospitalDiscoveryScreen's State is
      // actually disposed, not just covered by a new route.
      await tester.pumpWidget(const SizedBox.shrink());

      expect(fakeNotifier.stopTrackingCalled, isTrue);
    });
  });
}
