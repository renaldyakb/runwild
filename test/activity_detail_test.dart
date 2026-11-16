import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/design/theme/rw_theme.dart';
import 'package:runwild/domain/interval/interval_config.dart';
import 'package:runwild/domain/interval/interval_engine.dart';
import 'package:runwild/domain/tracking/activity_detail.dart';
import 'package:runwild/domain/tracking/run_summary.dart';
import 'package:runwild/domain/tracking/tracking_engine.dart';
import 'package:runwild/features/activities/presentation/activity_detail_screen.dart';
import 'package:runwild/features/run/application/activity_sync.dart';
import 'package:runwild/features/run/application/run_journal.dart';
import 'package:runwild/l10n/generated/app_localizations.dart';

import 'support.dart';

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

class _FakeSyncRepository implements ActivitySyncRepository {
  String? lastUpdatedActivityId;
  String? lastDeletedActivityId;

  @override
  Future<int> syncPending(String owner) async => 0;

  @override
  Future<void> deleteActivity(String owner, String activityId) async {
    lastDeletedActivityId = activityId;
  }

  @override
  Future<void> updateActivity(
    String owner,
    String activityId, {
    String? title,
    String? note,
    String? feeling,
  }) async {
    lastUpdatedActivityId = activityId;
  }

  @override
  Future<int> pullCloudHistory(
    String owner, {
    int limit = 20,
    DateTime? before,
  }) async => 0;
}

void main() {
  setUpAll(loadArchivo);

  group('Activity detail domain tests', () {
    test('calculateSplitsFromPoints handles multi-km route with splits', () {
      final points = <ActivityPoint>[
        (
          seq: 1,
          capturedAt: Duration.zero,
          latitude: 0.0,
          longitude: 0.0,
          accuracy: 5.0,
          segmentStart: true,
        ),
        (
          seq: 2,
          capturedAt: const Duration(minutes: 5),
          latitude: 0.009, // ~1000m
          longitude: 0.0,
          accuracy: 5.0,
          segmentStart: false,
        ),
        (
          seq: 3,
          capturedAt: const Duration(minutes: 11),
          latitude: 0.018, // ~2000m
          longitude: 0.0,
          accuracy: 5.0,
          segmentStart: false,
        ),
        (
          seq: 4,
          capturedAt: const Duration(minutes: 13),
          latitude: 0.021, // ~2330m (+330m partial)
          longitude: 0.0,
          accuracy: 5.0,
          segmentStart: false,
        ),
      ];

      final splits = calculateSplitsFromPoints(points);
      expect(splits.length, greaterThanOrEqualTo(2));
      expect(splits.first.kilometer, 1);
      expect(splits.first.duration.inSeconds, greaterThan(0));
      expect(splits.first.paceSecondsPerKm, greaterThan(0));
    });

    test('calculateSplitsFromPoints fallback for short sessions', () {
      final emptySplits = calculateSplitsFromPoints(const []);
      expect(emptySplits, isEmpty);

      final shortSplits = calculateSplitsFromPoints(
        const [],
        totalMeters: 500.0,
        totalMoving: const Duration(minutes: 3),
      );
      expect(shortSplits.length, 1);
      expect(shortSplits.first.kilometer, 1);
      expect(shortSplits.first.distanceMeters, 500.0);
    });

    test('parseIntervalSummary parses interval JSON correctly', () {
      final config = (
        warmup: const Duration(minutes: 5),
        run: const Duration(seconds: 120),
        walk: const Duration(seconds: 60),
        rounds: 10,
        startWithWalk: false,
        cooldown: const Duration(minutes: 3),
      );
      final json = encodeInterval(config);
      final summary = parseIntervalSummary(json, const Duration(seconds: 540));
      expect(summary, isNotNull);
      expect(summary!.completedRounds, 3);
      expect(summary.totalRounds, 10);
      expect(summary.runTime, const Duration(seconds: 360));
      expect(summary.walkTime, const Duration(seconds: 180));
    });

    test('ActivityDetail converts to RunSummary accurately', () {
      final detail = ActivityDetail(
        id: 42,
        owner: 'user1',
        startedAt: DateTime(2026, 11, 16, 7),
        meters: 5000.0,
        moving: const Duration(minutes: 25),
        elapsed: const Duration(minutes: 27),
        pointsCount: 150,
        synced: true,
        points: const [],
        splits: const [
          (
            kilometer: 1,
            distanceMeters: 1000.0,
            duration: Duration(minutes: 5),
            paceSecondsPerKm: 300.0,
          ),
        ],
        title: 'Tempo Run',
        note: 'Terasa sangat segar',
        feeling: 'normal',
      );

      final summary = detail.toRunSummary();
      expect(summary.sessionId, 42);
      expect(summary.distanceMeters, 5000.0);
      expect(summary.averagePace, closeTo(300.0, 1.0));
      expect(summary.feeling, RunFeeling.normal);
      expect(summary.note, 'Terasa sangat segar');
      expect(detail.estimatedCalories, greaterThan(300));
    });
  });

  group('RunJournal detail and update tests', () {
    test(
      'session() loads, updateSession() edits, discardSession() removes',
      () async {
        final db = RunJournal(NativeDatabase.memory());
        addTearDown(db.close);

        final when = DateTime(2026, 11, 16, 6, 30);
        final id = await db.begin('runner', when);
        final cp = (
          id: id,
          startedAt: when,
          meters: 3200.0,
          moving: const Duration(minutes: 18),
          elapsed: const Duration(minutes: 20),
          points: 2,
        );
        const fix1 = GpsSample(
          latitude: -6.2,
          longitude: 106.8,
          accuracyMeters: 5.0,
          capturedAt: Duration.zero,
        );
        const fix2 = GpsSample(
          latitude: -6.21,
          longitude: 106.8,
          accuracyMeters: 4.0,
          capturedAt: Duration(minutes: 5),
        );
        await db.checkpoint('runner', cp, const [
          (fix1, SampleResult.segmentStart),
          (fix2, SampleResult.recorded),
        ], finish: true);

        // Verify session read
        final record = await db.session('runner', id);
        expect(record, isNotNull);
        expect(record!.id, id);
        expect(record.meters, 3200.0);
        expect(record.title, isNull);

        // Verify update session
        await db.updateSession(
          'runner',
          id,
          title: 'Lari Pagi Tebet',
          note: 'Cuaca cerah',
          feeling: 'easy',
        );
        final updated = await db.session('runner', id);
        expect(updated!.title, 'Lari Pagi Tebet');
        expect(updated.note, 'Cuaca cerah');
        expect(updated.feeling, 'easy');
        expect(updated.synced, isFalse);

        // Verify discard session
        await db.discardSession('runner', id);
        final deleted = await db.session('runner', id);
        expect(deleted, isNull);
        final remainingPoints = await db.sessionPoints(id);
        expect(remainingPoints, isEmpty);
      },
    );
  });

  group('ActivityDetailScreen widget tests', () {
    testWidgets('Shows not found state when session does not exist', (
      tester,
    ) async {
      final db = RunJournal(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            runJournalProvider.overrideWithValue(db),
            runOwnerProvider.overrideWithValue(() => 'runner'),
          ],
          child: _testHost(const ActivityDetailScreen(sessionId: 999)),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Aktivitas tidak ditemukan'), findsOneWidget);
    });

    testWidgets('Renders full activity detail, updates title and deletes', (
      tester,
    ) async {
      final db = RunJournal(NativeDatabase.memory());
      addTearDown(db.close);
      final fakeSync = _FakeSyncRepository();

      final when = DateTime(2026, 11, 16, 7, 0);
      final id = await db.begin(
        'runner',
        when,
        interval: defaultIntervalConfig,
      );
      final cp = (
        id: id,
        startedAt: when,
        meters: 4500.0,
        moving: const Duration(minutes: 24),
        elapsed: const Duration(minutes: 26),
        points: 2,
      );
      const fix1 = GpsSample(
        latitude: -6.200,
        longitude: 106.800,
        accuracyMeters: 5.0,
        capturedAt: Duration.zero,
      );
      const fix2 = GpsSample(
        latitude: -6.210,
        longitude: 106.800,
        accuracyMeters: 4.0,
        capturedAt: Duration(minutes: 10),
      );
      await db.checkpoint('runner', cp, const [
        (fix1, SampleResult.segmentStart),
        (fix2, SampleResult.recorded),
      ], finish: true);
      await db.updateSummary(
        'runner',
        id,
        feeling: 'normal',
        note: 'Latihan rutin',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            runJournalProvider.overrideWithValue(db),
            runOwnerProvider.overrideWithValue(() => 'runner'),
            activitySyncRepositoryProvider.overrideWithValue(fakeSync),
          ],
          child: _testHost(ActivityDetailScreen(sessionId: id)),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title, distance and metrics
      expect(find.text('Detail Aktivitas'), findsOneWidget);
      expect(find.text('4,50'), findsOneWidget);
      expect(find.text('KILOMETER'), findsOneWidget);
      expect(find.text('PUTARAN'), findsOneWidget);
      expect(find.text('Latihan rutin'), findsOneWidget);
      expect(find.text('Split per Kilometer'), findsOneWidget);
      expect(find.text('Bagikan Sesi'), findsWidgets);

      // Open Edit Dialog
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Ubah Judul Sesi'), findsOneWidget);

      // Enter new title
      await tester.enterText(
        find.byType(TextField).first,
        'Sesi Interval Pagi',
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Verify new title is reflected
      expect(find.text('Sesi Interval Pagi'), findsOneWidget);
      final recordAfterEdit = await db.session('runner', id);
      expect(recordAfterEdit!.title, 'Sesi Interval Pagi');

      // Test delete dialog
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Hapus aktivitas ini? Riwayat sesi dan rute akan dihapus permanen.',
        ),
        findsOneWidget,
      );

      // Confirm delete in dialog
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();

      final recordAfterDelete = await db.session('runner', id);
      expect(recordAfterDelete, isNull);
    });
  });
}
