import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/design/theme/rw_theme.dart';
import 'package:runwild/domain/interval/interval_config.dart';
import 'package:runwild/domain/stats/stats_engine.dart';
import 'package:runwild/features/activities/presentation/progress_screen.dart';
import 'package:runwild/features/foundation/presentation/home_dashboard.dart';
import 'package:runwild/features/run/application/run_journal.dart';
import 'package:runwild/l10n/generated/app_localizations.dart';

Widget _testHost(Widget child) => MaterialApp(
  theme: RwTheme.light,
  locale: const Locale('id'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

SessionItem _dummyItem({
  required DateTime startedAt,
  required double meters,
  required Duration moving,
}) {
  return (startedAt: startedAt, meters: meters, moving: moving);
}

void main() {
  group('StatsEngine unit tests', () {
    test('calculateWeekSummary computes totals and 7 bars accurately', () {
      final now = DateTime(2026, 11, 16, 12, 0); // Senin
      final sessions = [
        _dummyItem(
          startedAt: DateTime(2026, 11, 16, 7, 0),
          meters: 5000,
          moving: const Duration(minutes: 30),
        ),
      ];

      final summary = StatsEngine.calculateWeekSummary(
        sessions: sessions,
        now: now,
      );

      expect(summary.totalDistanceMeters, 5000);
      expect(summary.totalMovingTime, const Duration(minutes: 30));
      expect(summary.sessionCount, 1);
      expect(summary.dailyBars.length, 7);
      expect(summary.dailyBars[0].distanceKm, 5.0);
      expect(summary.dailyBars[0].isToday, isTrue);
      expect(summary.dailyBars[1].distanceKm, 0.0);
    });

    test('calculateWeeklyStreak calculates continuous streak', () {
      final now = DateTime(2026, 11, 16, 12, 0);
      final sessions = [
        // Minggu ini
        _dummyItem(
          startedAt: DateTime(2026, 11, 16, 7, 0),
          meters: 5000,
          moving: const Duration(minutes: 30),
        ),
        // 1 minggu lalu
        _dummyItem(
          startedAt: DateTime(2026, 11, 9, 7, 0),
          meters: 4000,
          moving: const Duration(minutes: 25),
        ),
        // 2 minggu lalu
        _dummyItem(
          startedAt: DateTime(2026, 11, 2, 7, 0),
          meters: 3000,
          moving: const Duration(minutes: 20),
        ),
      ];

      final streak = StatsEngine.calculateWeeklyStreak(
        sessions: sessions,
        now: now,
        targetSessions: 1,
      );

      expect(streak, 3);
    });

    test('calculatePeriodStats groups by month or allTime', () {
      final now = DateTime(2026, 11, 16, 12, 0);
      final sessions = [
        _dummyItem(
          startedAt: DateTime(2026, 11, 16, 7, 0),
          meters: 6000,
          moving: const Duration(minutes: 36),
        ),
        _dummyItem(
          startedAt: DateTime(2026, 10, 10, 7, 0),
          meters: 4000,
          moving: const Duration(minutes: 24),
        ),
      ];

      final monthStats = StatsEngine.calculatePeriodStats(
        sessions: sessions,
        period: ProgressPeriod.month,
        now: now,
      );
      expect(monthStats.totalDistanceMeters, 6000);
      expect(monthStats.sessionCount, 1);

      final allStats = StatsEngine.calculatePeriodStats(
        sessions: sessions,
        period: ProgressPeriod.allTime,
        now: now,
      );
      expect(allStats.totalDistanceMeters, 10000);
      expect(allStats.sessionCount, 2);
    });

    test('calculatePersonalRecords calculates personal bests', () {
      final sessions = [
        _dummyItem(
          startedAt: DateTime(2026, 11, 10),
          meters: 10000,
          moving: const Duration(minutes: 60), // 6:00 /km
        ),
        _dummyItem(
          startedAt: DateTime(2026, 11, 12),
          meters: 3000,
          moving: const Duration(minutes: 15), // 5:00 /km
        ),
      ];

      final pb = StatsEngine.calculatePersonalRecords(sessions);

      expect(pb.longestDistance?.value, '10.00');
      expect(pb.longestDuration?.value, '60:00');
      expect(pb.bestPace1k?.value, '5\'00"');
      expect(pb.bestPace5k?.value, '6\'00"');
    });

    test('getRecommendedSession suggests based on runner history', () {
      final emptyRec = StatsEngine.getRecommendedSession(
        totalCompletedSessions: 0,
      );
      expect(emptyRec.preset, IntervalPreset.beginner);

      final intervalRec = StatsEngine.getRecommendedSession(
        totalCompletedSessions: 1,
      );
      expect(intervalRec.preset, IntervalPreset.classic);

      final freeRec = StatsEngine.getRecommendedSession(
        totalCompletedSessions: 2,
      );
      expect(freeRec.isFree, isTrue);
    });
  });

  group('HomeDashboard & ProgressScreen UI tests', () {
    late RunJournal journal;

    setUp(() {
      journal = RunJournal(NativeDatabase.memory());
    });

    tearDown(() async {
      await journal.close();
    });

    testWidgets(
      'HomeDashboard renders weekly goal, stats, and recommendation',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              runJournalProvider.overrideWithValue(journal),
              runOwnerProvider.overrideWithValue(() => 'tester-1'),
            ],
            child: _testHost(HomeDashboard(onStart: () {})),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Mulai berlari'), findsOneWidget);
        expect(find.text('MINGGU INI'), findsOneWidget);
        expect(find.text('TARGET MINGGUAN'), findsOneWidget);
        expect(find.text('Progress & Rekor'), findsOneWidget);
      },
    );

    testWidgets(
      'ProgressScreen renders empty state when no sessions recorded',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              runJournalProvider.overrideWithValue(journal),
              runOwnerProvider.overrideWithValue(() => 'tester-1'),
            ],
            child: _testHost(const ProgressScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Progress & Rekor'), findsOneWidget);
        expect(find.text('Minggu Ini'), findsWidgets);
        expect(find.text('Bulan Ini'), findsOneWidget);
        expect(find.text('Semua'), findsOneWidget);
        // Empty state
        expect(
          find.text(
            'Belum ada rekor pribadi. Mulai sesi lari pertamamu untuk mencatat rekor!',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('ProgressScreen renders personal bests when sessions exist', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Sisipkan 1 sesi selesai
      await journal.customInsert(
        'INSERT INTO run_sessions (owner, started_ms, meters, moving_us, elapsed_us, points, finished, synced) '
        'VALUES (?, ?, ?, ?, ?, ?, 1, 1)',
        variables: [
          Variable('tester-1'),
          Variable(DateTime.now().millisecondsSinceEpoch),
          Variable(5200.0),
          Variable(const Duration(minutes: 26).inMicroseconds),
          Variable(const Duration(minutes: 26).inMicroseconds),
          Variable(15),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            runJournalProvider.overrideWithValue(journal),
            runOwnerProvider.overrideWithValue(() => 'tester-1'),
          ],
          child: _testHost(const ProgressScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Progress & Rekor'), findsOneWidget);
      expect(find.text('REKOR PRIBADI (PERSONAL BEST)'), findsOneWidget);
      expect(find.text('Jarak Terjauh'), findsOneWidget);
      expect(find.text('Durasi Terlama'), findsOneWidget);
      expect(find.text('Pace 1 KM Terbaik'), findsOneWidget);
      expect(find.text('Pace 5 KM Terbaik'), findsOneWidget);
    });
  });
}
