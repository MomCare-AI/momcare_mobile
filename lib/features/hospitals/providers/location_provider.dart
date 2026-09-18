import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationPermissionState {
  undetermined,
  loading,
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

class LocationState {
  final LocationPermissionState permissionState;
  final LatLng? currentLocation;

  LocationState({required this.permissionState, this.currentLocation});

  LocationState copyWith({
    LocationPermissionState? permissionState,
    LatLng? currentLocation,
  }) {
    return LocationState(
      permissionState: permissionState ?? this.permissionState,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier()
    : super(
        LocationState(permissionState: LocationPermissionState.undetermined),
      );

  StreamSubscription<Position>? _positionStream;

  Future<void> requestPermissionAndStartTracking() async {
    state = state.copyWith(permissionState: LocationPermissionState.loading);

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(
        permissionState: LocationPermissionState.serviceDisabled,
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        state = state.copyWith(permissionState: LocationPermissionState.denied);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        permissionState: LocationPermissionState.permanentlyDenied,
      );
      return;
    }

    state = state.copyWith(permissionState: LocationPermissionState.granted);

    // Get initial position
    try {
      final position = await Geolocator.getCurrentPosition();
      state = state.copyWith(
        currentLocation: LatLng(position.latitude, position.longitude),
      );
    } catch (e) {
      // Ignore if it fails initially, stream might catch it
    }

    // Start live tracking
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // only update if moved 10 meters
          ),
        ).listen((Position position) {
          state = state.copyWith(
            currentLocation: LatLng(position.latitude, position.longitude),
          );
        });
  }

  void openSettings() {
    Geolocator.openAppSettings();
  }

  void openLocationSettings() {
    Geolocator.openLocationSettings();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) {
    return LocationNotifier();
  },
);
