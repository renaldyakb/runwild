import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runwild/domain/tracking/run_summary.dart';
import 'package:runwild/features/run/presentation/run_summary_screen.dart';

import 'support.dart';

void main() {
  test('RunSummary calories and splits calculation', () {
    final summary = RunSummary(
      startedAt: DateTime(2026, 11, 16, 10, 0),
      distanceMeters: 5000,
      movingTime: const Duration(minutes: 25),
      elapsedTime: const Duration(minutes: 26),
      averagePace: 300, // 5:00 /km
      splits: const [
        (
          kilometer: 1,
          distanceMeters: 1000,
          duration: Duration(minutes: 5),
          paceSecondsPerKm: 300,
        ),
      ],
    );

    // 5 km * 65 kg * 1.036 = 336.7 -> 337 kcal
    expect(summary.estimatedCalories, 337);
    expect(summary.copyWith(feeling: RunFeeling.easy).feeling, RunFeeling.easy);
  });

  testWidgets(
    'RunSummaryScreen renders stats, splits and allows feeling selection',
    (tester) async {
      final summary = RunSummary(
        sessionId: 42,
        startedAt: DateTime(2026, 11, 16, 10, 0),
        distanceMeters: 2500,
        movingTime: const Duration(minutes: 13, seconds: 45),
        elapsedTime: const Duration(minutes: 14),
        averagePace: 330,
        splits: const [
          (
            kilometer: 1,
            distanceMeters: 1000,
            duration: Duration(minutes: 5, seconds: 15),
            paceSecondsPerKm: 315,
          ),
          (
            kilometer: 2,
            distanceMeters: 1000,
            duration: Duration(minutes: 5, seconds: 30),
            paceSecondsPerKm: 330,
          ),
          (
            kilometer: 3,
            distanceMeters: 500,
            duration: Duration(minutes: 3),
            paceSecondsPerKm: 360,
          ),
        ],
        interval: (
          completedRounds: 4,
          totalRounds: 6,
          runTime: const Duration(minutes: 4),
          walkTime: const Duration(minutes: 8),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: componentHost(RunSummaryScreen(summary: summary), dark: false),
        ),
      );
      await tester.pumpAndSettle();

      // Verify distance and celebration
      expect(find.text('KERJA BAGUS!'), findsOneWidget);
      expect(find.text('2.50'), findsOneWidget);
      expect(find.text('KILOMETER'), findsOneWidget);

      // Verify splits
      expect(find.text('Split per Kilometer'), findsOneWidget);
      expect(find.text('Km 1'), findsOneWidget);
      expect(find.text('Km 2'), findsOneWidget);

      // Verify interval stats
      expect(find.text('Statistik Interval'), findsOneWidget);
      expect(find.text('4 dari 6 putaran'), findsOneWidget);

      // Verify feeling chips
      final mudah = find.text('🟢 Mudah');
      await tester.ensureVisible(mudah);
      expect(mudah, findsOneWidget);
      expect(find.text('🟡 Pas'), findsOneWidget);
      expect(find.text('🔴 Berat'), findsOneWidget);

      // Tap a feeling chip
      await tester.tap(mudah);
      await tester.pumpAndSettle();

      // Buttons
      final save = find.text('Simpan Sesi');
      await tester.ensureVisible(save);
      expect(save, findsOneWidget);
      expect(find.text('Bagikan'), findsOneWidget);
      expect(find.text('Buang Sesi'), findsOneWidget);
    },
  );
}
