import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_colors.dart';
import '../models/real_hospital.dart';
import '../providers/location_provider.dart';
import '../providers/real_hospitals_provider.dart';
import '../widgets/hospital_card.dart';

class HospitalDiscoveryScreen extends ConsumerStatefulWidget {
  const HospitalDiscoveryScreen({super.key});

  static const path = '/guest/hospitals';

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

  @override
  void initState() {
    super.initState();
    // Don't request immediately, we show the explanation first if undetermined.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(locationProvider);
      if (state.permissionState == LocationPermissionState.granted) {
        // If already granted in a previous session, just start tracking
        ref.read(locationProvider.notifier).requestPermissionAndStartTracking();
      }
    });
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
    final locationState = ref.watch(locationProvider);
    final hospitalsState = ref.watch(realHospitalsProvider);
    final hospitalsData = hospitalsState.hospitals;

    if (!_hasFetchedForLocation && locationState.currentLocation != null) {
      _hasFetchedForLocation = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(realHospitalsProvider.notifier)
            .fetchNearby(locationState.currentLocation!);
      });
    }

    if (!_hasFitInitialBounds &&
        locationState.currentLocation != null &&
        hospitalsData.isNotEmpty) {
      _hasFitInitialBounds = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBoundsToEverything(locationState.currentLocation!, hospitalsData);
      });
    }

    return Scaffold(
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
          if (locationState.permissionState ==
                  LocationPermissionState.granted &&
              locationState.currentLocation != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: locationState.currentLocation!,
                initialZoom: 14.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: (_, _) {
                  setState(() {
                    _selectedHospital = null;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.momcare.patient',
                ),
                MarkerLayer(
                  markers: [
                    // Real hospitals from OpenStreetMap — Airbnb-style
                    // distance pills rather than plain pins, so the map
                    // itself communicates something (how far) without a tap.
                    ...hospitalsData.map((data) {
                      final hospital = data['hospital'] as RealHospital;
                      final distanceKm = data['distanceKm'] as double;
                      final isSelected = _selectedHospital?.id == hospital.id;
                      return Marker(
                        point: LatLng(hospital.latitude, hospital.longitude),
                        width: 90,
                        height: 44,
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: () => _onHospitalTapped(hospital),
                          child: _DistancePill(
                            distanceKm: distanceKm,
                            isSelected: isSelected,
                          ),
                        ),
                      );
                    }),
                    // User location marker
                    Marker(
                      point: locationState.currentLocation!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            // Empty Map Background
            Container(color: AppColors.background),

          // States Overlay
          if (locationState.permissionState ==
              LocationPermissionState.undetermined)
            _buildPermissionExplanation()
          else if (locationState.permissionState ==
              LocationPermissionState.loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else if (locationState.permissionState ==
              LocationPermissionState.denied)
            _buildErrorState(
              'Location access is off',
              'Enable location access to find hospitals near you.',
              'Enable Location',
              () => ref
                  .read(locationProvider.notifier)
                  .requestPermissionAndStartTracking(),
            )
          else if (locationState.permissionState ==
              LocationPermissionState.permanentlyDenied)
            _buildErrorState(
              'Location permission denied',
              'MomCare needs location access to show hospitals near you.',
              'Open Settings',
              () => ref.read(locationProvider.notifier).openSettings(),
            )
          else if (locationState.permissionState ==
              LocationPermissionState.serviceDisabled)
            _buildErrorState(
              'Location services are turned off',
              'Turn on location services to find hospitals near you.',
              'Location Settings',
              () {
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
          if (locationState.permissionState == LocationPermissionState.granted)
            if (hospitalsState.status == RealHospitalsStatus.loading)
              const Positioned(
                top: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: _StatusPill(
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
                child: _RetryPill(
                  message:
                      hospitalsState.errorMessage ??
                      'Could not load hospitals.',
                  onRetry: () => ref
                      .read(realHospitalsProvider.notifier)
                      .fetchNearby(locationState.currentLocation!),
                ),
              ),

          // Recenter FAB
          if (locationState.permissionState == LocationPermissionState.granted)
            Positioned(
              right: 16,
              bottom: _selectedHospital != null
                  ? 300
                  : 200, // Above the bottom sheet
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                onPressed: _recenterMap,
                child: const Icon(LucideIcons.locate),
              ),
            ),

          // Selected hospital: a fixed floating card (Airbnb-style), not the
          // draggable list — a specific hospital you tapped isn't a list.
          if (locationState.permissionState ==
                  LocationPermissionState.granted &&
              _selectedHospital != null)
            _buildSelectedHospitalCard(hospitalsData)
          // Otherwise: the draggable list of everything nearby.
          else if (locationState.permissionState ==
              LocationPermissionState.granted)
            _buildHospitalListSheet(hospitalsData, hospitalsState.status),
        ],
      ),
    );
  }

  Widget _buildPermissionExplanation() {
    return Container(
      color: Colors.white.withValues(alpha: 0.9),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.mapPin, size: 48, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text(
              'Find maternal care near you',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Allow MomCare to use your location to show nearby hospitals and care facilities.',
              style: TextStyle(fontSize: 16, color: AppColors.faint),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => ref
                  .read(locationProvider.notifier)
                  .requestPermissionAndStartTracking(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Allow Location Access',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    String title,
    String message,
    String buttonText,
    VoidCallback onPressed,
  ) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.mapPinOff, size: 48, color: AppColors.faint),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: AppColors.faint),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalListSheet(
    List<Map<String, dynamic>> hospitalsData,
    RealHospitalsStatus status,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.1,
      maxChildSize: 0.8,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 0),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Nearby Hospitals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              Expanded(
                child:
                    status == RealHospitalsStatus.loaded &&
                        hospitalsData.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No hospitals found nearby.\nTry expanding your search area.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.faint),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        itemCount: hospitalsData.length,
                        itemBuilder: (context, index) {
                          final data = hospitalsData[index];
                          final hospital = data['hospital'] as RealHospital;
                          final distanceKm = data['distanceKm'] as double;

                          return HospitalCard(
                            name: hospital.name,
                            address: hospital.address,
                            distanceKm: distanceKm,
                            onTap: () => _onHospitalTapped(hospital),
                            actionLabel: 'Get Directions',
                            onActionPressed: () => _openDirections(hospital),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// The Airbnb-reference popup: a fixed card for exactly the one hospital
  /// you tapped on the map — not a draggable list, since there's nothing to
  /// scroll through once you've picked one.
  Widget _buildSelectedHospitalCard(List<Map<String, dynamic>> hospitalsData) {
    final data = hospitalsData.firstWhere(
      (d) => (d['hospital'] as RealHospital).id == _selectedHospital!.id,
    );
    final hospital = data['hospital'] as RealHospital;
    final distanceKm = data['distanceKm'] as double;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Material(
        borderRadius: BorderRadius.circular(24),
        elevation: 8,
        shadowColor: Colors.black26,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      LucideIcons.building2,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospital.name,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${distanceKm.toStringAsFixed(1)} km away · ${hospital.address}',
                          style: const TextStyle(
                            color: AppColors.faint,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    // 44x44pt minimum tap target (Apple HIG) — the icon
                    // itself stays 20px, only the hit area grows.
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: const Icon(
                      LucideIcons.x,
                      size: 20,
                      color: AppColors.faint,
                    ),
                    onPressed: () => setState(() => _selectedHospital = null),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _openDirections(hospital),
                  icon: const Icon(LucideIcons.navigation, size: 18),
                  label: const Text(
                    'Get Directions',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Airbnb-style distance pill: what the map shows before you tap anything.
class _DistancePill extends StatelessWidget {
  const _DistancePill({required this.distanceKm, required this.isSelected});

  final double distanceKm;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final label = '${distanceKm.toStringAsFixed(1)} km';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.black87,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: AppColors.ink, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _RetryPill extends StatelessWidget {
  const _RetryPill({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.ink, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
