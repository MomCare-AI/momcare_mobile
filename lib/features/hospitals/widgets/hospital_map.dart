import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../theme/app_colors.dart';
import '../models/real_hospital.dart';
import '../providers/location_provider.dart';
import 'distance_pill.dart';

/// The map + markers layer, isolated in its own widget so it's the only
/// part of the screen that rebuilds on every live-location tick (the
/// position stream fires on ~10m of movement). Permission overlays, the
/// hospital list, and the selected-hospital card don't depend on live GPS
/// coordinates and shouldn't re-render just because this widget's parent
/// would otherwise watch the whole LocationState.
///
/// Only built once the parent has already confirmed permission is granted
/// and a location is known — currentLocation is assumed non-null here.
class HospitalMap extends ConsumerWidget {
  const HospitalMap({
    super.key,
    required this.mapController,
    required this.hospitalsData,
    required this.selectedHospitalId,
    required this.onHospitalTapped,
    required this.onMapTap,
    this.tileProvider,
  });

  final MapController mapController;
  final List<Map<String, dynamic>> hospitalsData;
  final String? selectedHospitalId;
  final void Function(RealHospital hospital) onHospitalTapped;
  final VoidCallback onMapTap;

  /// Defaults to flutter_map's own real NetworkTileProvider when null — the
  /// same production behavior as before this parameter existed. Exists so
  /// tests can inject an offline provider instead of making real tile
  /// requests (there's no network in the test sandbox, so every real
  /// request fails, which is expected but has nothing to do with what a
  /// widget test of this screen is actually checking).
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocation = ref.watch(
      locationProvider.select((state) => state.currentLocation),
    )!;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: currentLocation,
        initialZoom: 14.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onTap: (_, _) => onMapTap(),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.momcare.patient',
          tileProvider: tileProvider,
          // A single tile failing to load (flaky connectivity, or no
          // network at all in a test environment) shouldn't become an
          // unhandled exception — the correct behavior for a tiled map is
          // to just leave that one tile blank, same as every mapping app.
          errorTileCallback: (tile, error, stackTrace) {},
        ),
        MarkerLayer(
          markers: [
            // Real hospitals from OpenStreetMap — Airbnb-style distance
            // pills rather than plain pins, so the map itself communicates
            // something (how far) without a tap.
            ...hospitalsData.map((data) {
              final hospital = data['hospital'] as RealHospital;
              final distanceKm = data['distanceKm'] as double;
              final isSelected = selectedHospitalId == hospital.id;
              return Marker(
                point: LatLng(hospital.latitude, hospital.longitude),
                width: 90,
                height: 44,
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () => onHospitalTapped(hospital),
                  child: DistancePill(
                    distanceKm: distanceKm,
                    isSelected: isSelected,
                  ),
                ),
              );
            }),
            // User location marker
            Marker(
              point: currentLocation,
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
    );
  }
}
