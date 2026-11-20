import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/design/theme/rw_theme.dart';
import 'package:runwild/domain/stats/stats_engine.dart';
import 'package:runwild/domain/tracking/run_summary.dart';
import 'package:runwild/features/foundation/application/home_stats_provider.dart';
import 'package:runwild/features/run/presentation/run_summary_screen.dart';
import 'package:runwild/features/run/presentation/share_card_widget.dart';
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

void main() {
  group('Upgrade #3: Personal Best (PB) Detection & Alert', () {
    final now = DateTime(2026, 11, 16, 8, 30);

    test(
      'StatsEngine.detectPersonalBestsForSession detects matching records',
      () {
        final records = (
          longestDistance: (
            title: 'Jarak Terjauh',
            value: '10.50',
            unit: 'km',
            achievedAt: now,
          ),
          longestDuration: (
            title: 'Durasi Terlama',
            value: '60:00',
            unit: 'waktu',
            achievedAt: now,
          ),
          bestPace1k: (
            title: 'Pace 1 KM Terbaik',
            value: '4\'30"',
            unit: '/km',
            achievedAt: DateTime(2026, 10, 1),
          ),
          bestPace5k: null,
        );

        final pbs = StatsEngine.detectPersonalBestsForSession(
          startedAt: now,
          records: records,
        );

        expect(pbs, contains('Jarak Terjauh'));
        expect(pbs, contains('Durasi Terlama'));
        expect(pbs, isNot(contains('Pace 1K Rata-rata')));
        expect(pbs, isNot(contains('Pace 5K Rata-rata')));
      },
    );

    test('detects a record when the session time carries microseconds', () {
      final precise = DateTime(2026, 11, 18, 7, 0, 0, 123, 456);
      final stored = DateTime.fromMillisecondsSinceEpoch(
        precise.millisecondsSinceEpoch,
      );
      final records = (
        longestDistance: (
          title: 'Jarak Terjauh',
          value: '5.20',
          unit: 'km',
          achievedAt: stored,
        ),
        longestDuration: null,
        bestPace1k: null,
        bestPace5k: null,
      );

      final pbs = StatsEngine.detectPersonalBestsForSession(
        startedAt: precise,
        records: records,
      );

      expect(pbs, contains('Jarak Terjauh'));
    });

    testWidgets(
      'RunSummaryScreen renders PB alert banner when session holds record',
      (tester) async {
        final summary = RunSummary(
          startedAt: now,
          distanceMeters: 10500,
          movingTime: const Duration(minutes: 60),
          elapsedTime: const Duration(minutes: 60),
          averagePace: 342,
          splits: const [],
        );

        final fakeRecords = (
          longestDistance: (
            title: 'Jarak Terjauh',
            value: '10.50',
            unit: 'km',
            achievedAt: now,
          ),
          longestDuration: (
            title: 'Durasi Terlama',
            value: '60:00',
            unit: 'waktu',
            achievedAt: now,
          ),
          bestPace1k: null,
          bestPace5k: null,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              personalRecordsProvider.overrideWith(
                (ref) => Future.value(fakeRecords),
              ),
            ],
            child: _testHost(RunSummaryScreen(summary: summary)),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Rekor pribadi baru'), findsOneWidget);
        expect(
          find.textContaining(
            'Kamu memecahkan Jarak Terjauh & Durasi Terlama.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('ShareCardWidget renders REKOR PRIBADI pill badge', (
      tester,
    ) async {
      final summary = RunSummary(
        startedAt: now,
        distanceMeters: 5000,
        movingTime: const Duration(minutes: 30),
        elapsedTime: const Duration(minutes: 30),
        averagePace: 360,
        splits: const [],
      );

      await tester.pumpWidget(
        _testHost(
          ShareCardWidget(
            summary: summary,
            theme: ShareCardTheme.primeLime,
            format: ShareCardFormat.square,
            hideRoute: false,
            personalBests: const ['Jarak Terjauh'],
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('REKOR PRIBADI · JARAK TERJAUH'), findsOneWidget);
    });
  });
}
