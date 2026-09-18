import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:momcare_mobile/features/vitals/models/vital_reading.dart';
import 'package:momcare_mobile/features/vitals/providers/vitals_provider.dart';
import 'package:momcare_mobile/features/vitals/repositories/vitals_repository.dart';
import 'package:momcare_mobile/features/vitals/screens/vitals_screen.dart';

/// A repository whose calls only resolve when the test explicitly tells
/// them to, in whatever order the test chooses — the only way to actually
/// exercise "an older fetch resolves after a newer one" deterministically.
class _ManualRepository extends VitalsRepository {
  final List<Completer<List<VitalReading>>> _completers = [];
  final List<DateTime> callsWithSince = [];

  @override
  Future<List<VitalReading>> fetchReadings({required DateTime since}) {
    callsWithSince.add(since);
    final completer = Completer<List<VitalReading>>();
    _completers.add(completer);
    return completer.future;
  }

  void completeCall(int index, List<VitalReading> result) {
    _completers[index].complete(result);
  }

  void failCall(int index, Object error) {
    _completers[index].completeError(error);
  }
}

void main() {
  Widget wrap(VitalsRepository repository) {
    return ProviderScope(
      overrides: [vitalsRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: VitalsScreen()),
    );
  }

  testWidgets('shows a spinner while the first load is in flight', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(_ManualRepository()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('the sample-data notice is visible without scrolling', (
    tester,
  ) async {
    final fake = _ManualRepository();
    await tester.pumpWidget(wrap(fake));
    await tester.pump();
    fake.completeCall(0, []);
    await tester.pumpAndSettle();

    expect(find.text('Sample data — not yet connected'), findsOneWidget);
  });

  testWidgets('shows measurement cards and a grouped timeline once loaded', (
    tester,
  ) async {
    final fake = _ManualRepository();
    await tester.pumpWidget(wrap(fake));
    await tester.pump();

    fake.completeCall(0, [
      VitalReading(
        id: 'r1',
        recordedAt: DateTime.now(),
        source: VitalSource.device,
        heartRate: 80,
        systolicBp: 120,
        diastolicBp: 78,
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Blood Pressure'), findsOneWidget);
    expect(find.text('Heart Rate'), findsOneWidget);
    // One grouped timeline entry, not two separate ones for BP and HR.
    expect(find.textContaining('BP 120/78'), findsOneWidget);
    expect(find.textContaining('HR 80 BPM'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are genuinely no readings', (
    tester,
  ) async {
    final fake = _ManualRepository();
    await tester.pumpWidget(wrap(fake));
    await tester.pump();

    fake.completeCall(0, []);
    await tester.pumpAndSettle();

    expect(find.text('No readings yet'), findsOneWidget);
  });

  testWidgets('shows an error message when the repository fails', (
    tester,
  ) async {
    final fake = _ManualRepository();
    await tester.pumpWidget(wrap(fake));
    await tester.pump();

    fake.failCall(0, Exception('network down'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets(
    'a stale response from an earlier filter tap never overrides a newer one',
    (tester) async {
      final fake = _ManualRepository();
      await tester.pumpWidget(wrap(fake));
      await tester.pump();

      // Call 0: the initial "Today" fetch from construction.
      fake.completeCall(0, []);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Week')); // call 1
      await tester.pump();
      await tester.tap(find.text('Today')); // call 2 — supersedes call 1
      await tester.pump();

      // Resolve the newer request first, then the stale one — exactly the
      // out-of-order arrival the request-generation guard exists for.
      fake.completeCall(2, [
        VitalReading(
          id: 'today',
          recordedAt: DateTime.now(),
          source: VitalSource.device,
          heartRate: 99,
        ),
      ]);
      await tester.pump();
      fake.completeCall(1, [
        VitalReading(
          id: 'week',
          recordedAt: DateTime.now(),
          source: VitalSource.device,
          heartRate: 55,
        ),
      ]);
      await tester.pumpAndSettle();

      expect(find.textContaining('HR 99 BPM'), findsOneWidget);
      expect(find.textContaining('HR 55 BPM'), findsNothing);
    },
  );
}
