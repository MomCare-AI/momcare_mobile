import 'package:flutter_test/flutter_test.dart';

import 'package:momcare_mobile/features/vitals/repositories/vitals_repository.dart';

void main() {
  group('VitalsRepository.fetchReadings', () {
    test('excludes readings recorded before "since"', () async {
      final repository = VitalsRepository();
      final farPast = DateTime.now().subtract(const Duration(days: 3650));

      // sampleVitalReadings' oldest entry is ~9 days ago — asking for
      // everything since 10 years ago must include all of them.
      final all = await repository.fetchReadings(since: farPast);
      final sinceNow = await repository.fetchReadings(since: DateTime.now());

      expect(all, isNotEmpty);
      expect(sinceNow, isEmpty);
    });

    test('returns readings newest-first, matching the real endpoint\'s ordering',
        () async {
      final repository = VitalsRepository();
      final farPast = DateTime.now().subtract(const Duration(days: 3650));

      final readings = await repository.fetchReadings(since: farPast);

      for (var i = 0; i < readings.length - 1; i++) {
        expect(
          readings[i].recordedAt.isAfter(readings[i + 1].recordedAt) ||
              readings[i].recordedAt.isAtSameMomentAs(readings[i + 1].recordedAt),
          isTrue,
          reason: 'Reading at index $i is not newer than or equal to the next one',
        );
      }
    });
  });
}
