import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vital_reading.dart';
import '../repositories/vitals_repository.dart';

enum VitalsTimeRange { today, week, month }

enum VitalsStatus { loading, loaded, empty, error }

class VitalsState {
  const VitalsState({
    required this.status,
    this.readings = const [],
    this.timeRange = VitalsTimeRange.today,
    this.errorMessage,
    this.isRefreshing = false,
  });

  final VitalsStatus status;
  final List<VitalReading> readings;
  final VitalsTimeRange timeRange;
  final String? errorMessage;

  /// True while a fetch is in flight *and* there's already-loaded content on
  /// screen — lets the UI keep showing the last good data with a light
  /// indicator instead of blanking to a full spinner on every filter tap.
  final bool isRefreshing;

  VitalsState copyWith({
    VitalsStatus? status,
    List<VitalReading>? readings,
    VitalsTimeRange? timeRange,
    String? errorMessage,
    bool? isRefreshing,
  }) {
    return VitalsState(
      status: status ?? this.status,
      readings: readings ?? this.readings,
      timeRange: timeRange ?? this.timeRange,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  /// The most recent non-null value for one vital across every loaded
  /// reading — not just whatever the single latest reading happens to
  /// carry. Matches the real backend's own model docstring: hemoglobin and
  /// blood glucose in particular persist across many rows until the next
  /// test, so reading only the latest row would show them as blank far more
  /// often than they actually are.
  T? latestValueOf<T>(T? Function(VitalReading) selector) {
    for (final reading in readings) {
      final value = selector(reading);
      if (value != null) return value;
    }
    return null;
  }

  /// The most recent reading that actually carries a blood-pressure pair.
  /// Not the same as combining the latest systolic and latest diastolic
  /// independently — the backend only ever accepts them together (see
  /// `VitalReadingCreateSerializer.validate`), so a display that mixed two
  /// different reading events' halves could show a pairing that was never
  /// actually measured together.
  VitalReading? get latestBloodPressureReading {
    for (final reading in readings) {
      if (reading.hasBloodPressure) return reading;
    }
    return null;
  }
}

class VitalsNotifier extends StateNotifier<VitalsState> {
  // Fetches from its own constructor rather than waiting for the screen to
  // trigger it, unlike the `hospitals` feature's manual-trigger pattern —
  // deliberate here, not an oversight: unlike hospitals, this feature has no
  // permission gate to wait on first, so there's nothing to gain by
  // delaying the first load.
  VitalsNotifier(this._repository)
    : super(const VitalsState(status: VitalsStatus.loading)) {
    fetch();
  }

  final VitalsRepository _repository;

  // Guards against a slow, stale fetch overwriting a faster, newer one —
  // e.g. tapping Week then quickly Today before Week's response lands.
  // Whichever fetch was started *last* is the only one allowed to write to
  // state; every earlier in-flight call's result is discarded on arrival.
  int _requestGeneration = 0;

  DateTime _sinceFor(VitalsTimeRange range) {
    final now = DateTime.now();
    switch (range) {
      case VitalsTimeRange.today:
        return DateTime(now.year, now.month, now.day);
      case VitalsTimeRange.week:
        return now.subtract(const Duration(days: 7));
      case VitalsTimeRange.month:
        return now.subtract(const Duration(days: 30));
    }
  }

  Future<void> fetch() async {
    final thisRequest = ++_requestGeneration;
    final hasExistingContent = state.readings.isNotEmpty;

    state = state.copyWith(
      status: hasExistingContent ? state.status : VitalsStatus.loading,
      isRefreshing: hasExistingContent,
    );

    try {
      final readings = await _repository.fetchReadings(
        since: _sinceFor(state.timeRange),
      );
      if (thisRequest != _requestGeneration) return; // superseded — discard

      state = state.copyWith(
        status: readings.isEmpty ? VitalsStatus.empty : VitalsStatus.loaded,
        readings: readings,
        isRefreshing: false,
      );
    } catch (_) {
      if (thisRequest != _requestGeneration) return; // superseded — discard

      state = state.copyWith(
        status: VitalsStatus.error,
        errorMessage:
            'Could not load your vitals. Check your connection and try again.',
        isRefreshing: false,
      );
    }
  }

  void setTimeRange(VitalsTimeRange range) {
    if (range == state.timeRange) return;
    state = state.copyWith(timeRange: range);
    fetch();
  }
}

final vitalsRepositoryProvider = Provider<VitalsRepository>((ref) {
  return VitalsRepository();
});

final vitalsProvider = StateNotifierProvider<VitalsNotifier, VitalsState>((
  ref,
) {
  return VitalsNotifier(ref.watch(vitalsRepositoryProvider));
});
