import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:momcare_mobile/features/vitals/models/vital_reading.dart';
import 'package:momcare_mobile/features/vitals/providers/vitals_provider.dart';
import 'package:momcare_mobile/features/vitals/repositories/vitals_repository.dart';

/// Records every `since` it was called with and returns canned data
/// instantly — no real delay, no real sample-data coupling, so these tests
/// only ever exercise the provider's own status-transition logic.
class _FakeVitalsRepository extends VitalsRepository {
  final List<DateTime> callsWithSince = [];
  List<VitalReading> nextResult = [];
  bool shouldThrow = false;

  @override
  Future<List<VitalReading>> fetchReadings({required DateTime since}) async {
    callsWithSince.add(since);
    if (shouldThrow) throw Exception('network down');
    return nextResult;
  }
}

void main() {
  group('VitalsNotifier', () {
    test('starts loading, then moves to loaded when readings exist', () async {
      final fake = _FakeVitalsRepository()
        ..nextResult = [
          VitalReading(
            id: 'r1',
            recordedAt: DateTime.now(),
            source: VitalSource.device,
            heartRate: 80,
          ),
        ];
      final container = ProviderContainer(
        overrides: [vitalsRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      expect(container.read(vitalsProvider).status, VitalsStatus.loading);

      await container.read(vitalsProvider.notifier).fetch();

      expect(container.read(vitalsProvider).status, VitalsStatus.loaded);
      expect(container.read(vitalsProvider).readings, hasLength(1));
    });

    test(
      'moves to empty (not loaded) when there are genuinely no readings',
      () async {
        final fake = _FakeVitalsRepository()..nextResult = [];
        final container = ProviderContainer(
          overrides: [vitalsRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        await container.read(vitalsProvider.notifier).fetch();

        expect(container.read(vitalsProvider).status, VitalsStatus.empty);
      },
    );

    test(
      'moves to error, with a message, when the repository throws',
      () async {
        final fake = _FakeVitalsRepository()..shouldThrow = true;
        final container = ProviderContainer(
          overrides: [vitalsRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        await container.read(vitalsProvider.notifier).fetch();

        expect(container.read(vitalsProvider).status, VitalsStatus.error);
        expect(container.read(vitalsProvider).errorMessage, isNotNull);
      },
    );

    test(
      'changing the time range refetches with a wider "since" boundary',
      () async {
        final fake = _FakeVitalsRepository();
        final container = ProviderContainer(
          overrides: [vitalsRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        // Force construction (and its own initial "today" fetch) before
        // capturing the baseline — reading .notifier for the first time on
        // the same line as the actual action being tested would silently
        // fold construction's fetch into the count being measured.
        final notifier = container.read(vitalsProvider.notifier);
        final callsBeforeChange = fake.callsWithSince.length;

        notifier.setTimeRange(VitalsTimeRange.month);
        await Future<void>.delayed(Duration.zero);

        expect(fake.callsWithSince.length, callsBeforeChange + 1);
        final todaySince = fake.callsWithSince[callsBeforeChange - 1];
        final monthSince = fake.callsWithSince[callsBeforeChange];
        expect(
          monthSince.isBefore(todaySince),
          isTrue,
          reason: 'A month range should look further back than a day range',
        );
        expect(container.read(vitalsProvider).timeRange, VitalsTimeRange.month);
      },
    );

    test(
      'setting the same time range again does not trigger a refetch',
      () async {
        final fake = _FakeVitalsRepository();
        final container = ProviderContainer(
          overrides: [vitalsRepositoryProvider.overrideWithValue(fake)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(vitalsProvider.notifier);
        final callsBefore = fake.callsWithSince.length;
        notifier.setTimeRange(VitalsTimeRange.today);

        expect(fake.callsWithSince.length, callsBefore);
      },
    );
  });
}
