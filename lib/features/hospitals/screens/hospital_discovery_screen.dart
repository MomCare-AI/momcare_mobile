import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_colors.dart';
import '../models/real_hospital.dart';
import '../providers/location_provider.dart';
import '../providers/real_hospitals_provider.dart';
import '../widgets/hospital_list_sheet.dart';
import '../widgets/hospital_map.dart';
import '../widgets/selected_hospital_card.dart';
import '../widgets/status_overlays.dart';

class HospitalDiscoveryScreen extends ConsumerStatefulWidget {
  const HospitalDiscoveryScreen({super.key, this.tileProvider});

  static const path = '/guest/hospitals';

  /// Passed straight through to HospitalMap — null means the real network
  /// tile provider (production default). Exists purely so tests can inject
  /// an offline provider; see HospitalMap's own doc comment.
  final TileProvider? tileProvider;

  @override
  ConsumerState<HospitalDiscoveryScreen> createState() =>
      _HospitalDiscoveryScreenState();
}

class _HospitalDiscoveryScreenState
    extends ConsumerState<HospitalDiscoveryScreen> {
  final MapController _mapController = MapController();
  RealHospital? _selectedHospital;

  // Real hospitals are fetched once per location fix, not on every GPS
  // tick — the position stream updates every ~10m of movement, and
  // Overpass is a shared community service, not something to hammer.
  bool _hasFetchedForLocation = false;
  bool _hasFitInitialBounds = false;

  // Captured once, up front, rather than via ref.read() inside dispose():
  // if the whole widget tree (including the ProviderScope above this
  // screen) is torn down in the same pass — not how a normal in-app
  // Navigator.pop unmounts this screen, but real in tests that replace the
  // entire tree at once — Riverpod's ref is no longer usable by the time
  // dispose() runs. A plain object reference has no such restriction.
  late final LocationNotifier _locationNotifier;

  @override
  void initState() {
    super.initState();
    _locationNotifier = ref.read(locationProvider.notifier);
    // Don't request immediately, we show the explanation first if undetermined.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(locationProvider);
      if (state.permissionState == LocationPermissionState.granted) {
        // If already granted in a previous session, just start tracking
        _locationNotifier.requestPermissionAndStartTracking();
      }
    });
  }

  @override
  void dispose() {
    // locationProvider isn't scoped to this screen (it's a plain, not
    // autoDispose, provider — HospitalMap also reads it), so nothing else
    // stops the GPS stream when this screen is left. Without this, a
    // single Hospital Discovery visit would leave high-accuracy tracking
    // running for the rest of the app session. This only cancels the
    // active stream; permissionState/currentLocation are left alone so
    // initState()'s "already granted" fast path still works on return.
    _locationNotifier.stopTracking();
    super.dispose();
  }

  void _fitBoundsToEverything(
    LatLng userLocation,
    List<Map<String, dynamic>> hospitalsData,
  ) {
    final points = <LatLng>[
      userLocation,
      for (final data in hospitalsData)
        LatLng(
          (data['hospital'] as RealHospital).latitude,
          (data['hospital'] as RealHospital).longitude,
        ),
    ];
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.fromLTRB(40, 100, 40, 260),
      ),
    );
  }

  void _recenterMap() {
    final loc = ref.read(locationProvider).currentLocation;
    if (loc != null) {
      _mapController.move(loc, 14.0);
    }
  }

  // Shared by the top RetryPill and the bottom sheet's own retry button —
  // one retry mechanism, not two independent ones.
  void _retryFetch() {
    final currentLocation = ref.read(locationProvider).currentLocation;
    if (currentLocation != null) {
      ref.read(realHospitalsProvider.notifier).fetchNearby(currentLocation);
    }
  }

  void _onHospitalTapped(RealHospital hospital) {
    setState(() {
      _selectedHospital = hospital;
    });
    _mapController.move(LatLng(hospital.latitude, hospital.longitude), 15.0);
  }

  Future<void> _openDirections(RealHospital hospital) async {
    final uri = Uri.parse(
      'geo:${hospital.latitude},${hospital.longitude}?q=${hospital.latitude},${hospital.longitude}(${Uri.encodeComponent(hospital.name)})',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No maps app found to open directions.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Narrow watches — this build() only re-runs when the permission state
    // changes (rare) or when "do we have a location at all" flips from
    // false to true (once, ever, for the life of this screen). Live GPS
    // coordinate updates (~every 10m) no longer rebuild the permission
    // overlays, the hospital list, or the selected-hospital card — only
    // HospitalMap (below) watches the live currentLocation value itself.
    final permissionState = ref.watch(
      locationProvider.select((state) => state.permissionState),
    );
    final hasLocation = ref.watch(
      locationProvider.select((state) => state.currentLocation != null),
    );
    final hospitalsState = ref.watch(realHospitalsProvider);
    final hospitalsData = hospitalsState.hospitals;

    if (!_hasFetchedForLocation && hasLocation) {
      _hasFetchedForLocation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentLocation = ref.read(locationProvider).currentLocation;
        if (currentLocation != null) {
          ref.read(realHospitalsProvider.notifier).fetchNearby(currentLocation);
        }
      });
    }

    if (!_hasFitInitialBounds && hasLocation && hospitalsData.isNotEmpty) {
      _hasFitInitialBounds = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentLocation = ref.read(locationProvider).currentLocation;
        if (currentLocation != null) {
          _fitBoundsToEverything(currentLocation, hospitalsData);
        }
      });
    }

    // Resolved once per build, not inside a widget-builder method — same
    // lookup (and same throw-if-not-found behavior) the original had.
    final Map<String, dynamic>? selectedData = _selectedHospital == null
        ? null
        : hospitalsData.firstWhere(
            (d) => (d['hospital'] as RealHospital).id == _selectedHospital!.id,
          );

    // extendBodyBehindAppBar puts the map right up to the status bar, which
    // on real-world map tiles (light beige/tan roads and land) leaves the
    // default light status-bar icons/clock hard to read — confirmed on the
    // physical test device. Force dark icons regardless of what's under
    // them, same pattern already used by AuthScreen/OnboardingScreen.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Nearby Hospitals'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.ink,
        ),
        body: Stack(
          children: [
            // Background Map Layer
            if (permissionState == LocationPermissionState.granted &&
                hasLocation)
              HospitalMap(
                mapController: _mapController,
                hospitalsData: hospitalsData,
                selectedHospitalId: _selectedHospital?.id,
                onHospitalTapped: _onHospitalTapped,
                onMapTap: () => setState(() => _selectedHospital = null),
                tileProvider: widget.tileProvider,
              )
            else
              // Empty Map Background
              Container(color: AppColors.background),

            // States Overlay
            if (permissionState == LocationPermissionState.undetermined)
              PermissionExplanation(
                onAllow: () => ref
                    .read(locationProvider.notifier)
                    .requestPermissionAndStartTracking(),
              )
            else if (permissionState == LocationPermissionState.loading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            else if (permissionState == LocationPermissionState.denied)
              LocationErrorState(
                title: 'Location access is off',
                message: 'Enable location access to find hospitals near you.',
                buttonText: 'Enable Location',
                onPressed: () => ref
                    .read(locationProvider.notifier)
                    .requestPermissionAndStartTracking(),
              )
            else if (permissionState ==
                LocationPermissionState.permanentlyDenied)
              LocationErrorState(
                title: 'Location permission denied',
                message:
                    'MomCare needs location access to show hospitals near you.',
                buttonText: 'Open Settings',
                onPressed: () =>
                    ref.read(locationProvider.notifier).openSettings(),
              )
            else if (permissionState == LocationPermissionState.serviceDisabled)
              LocationErrorState(
                title: 'Location services are turned off',
                message:
                    'Turn on location services to find hospitals near you.',
                buttonText: 'Location Settings',
                onPressed: () {
                  ref.read(locationProvider.notifier).openLocationSettings();
                  // We'll also retry fetching state
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      ref
                          .read(locationProvider.notifier)
                          .requestPermissionAndStartTracking();
                    }
                  });
                },
              ),

            // Hospitals loading/error overlay — only once location is granted.
            if (permissionState == LocationPermissionState.granted)
              if (hospitalsState.status == RealHospitalsStatus.loading)
                const Positioned(
                  top: 120,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: StatusPill(
                      icon: LucideIcons.loader,
                      label: 'Finding real hospitals nearby…',
                    ),
                  ),
                )
              else if (hospitalsState.status == RealHospitalsStatus.error)
                Positioned(
                  top: 120,
                  left: 16,
                  right: 16,
                  child: RetryPill(
                    message:
                        hospitalsState.errorMessage ??
                        'Could not load hospitals.',
                    onRetry: _retryFetch,
                  ),
                ),

            // Recenter FAB
            if (permissionState == LocationPermissionState.granted)
              Positioned(
                right: 16,
                bottom: _selectedHospital != null
                    ? 300
                    : 200, // Above the bottom sheet
                child: FloatingActionButton(
                  // Not mini — Material's mini FAB is 40dp, under the 44-48pt
                  // minimum accessible touch target. The regular FAB (56dp)
                  // comfortably clears it.
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  tooltip: 'Center map on my location',
                  onPressed: _recenterMap,
                  child: const Icon(LucideIcons.locate),
                ),
              ),

            // Selected hospital: a fixed floating card (Airbnb-style), not the
            // draggable list — a specific hospital you tapped isn't a list.
            if (permissionState == LocationPermissionState.granted &&
                selectedData != null)
              SelectedHospitalCard(
                hospital: selectedData['hospital'] as RealHospital,
                distanceKm: selectedData['distanceKm'] as double,
                onClose: () => setState(() => _selectedHospital = null),
                onGetDirections: () =>
                    _openDirections(selectedData['hospital'] as RealHospital),
              )
            // Otherwise: the draggable list of everything nearby.
            else if (permissionState == LocationPermissionState.granted)
              HospitalListSheet(
                hospitalsData: hospitalsData,
                status: hospitalsState.status,
                errorMessage: hospitalsState.errorMessage,
                onHospitalTapped: _onHospitalTapped,
                onGetDirections: _openDirections,
                onRetry: _retryFetch,
              ),
          ],
        ),
      ),
    );
  }
}
