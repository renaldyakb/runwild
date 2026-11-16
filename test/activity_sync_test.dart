import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runwild/domain/interval/interval_engine.dart';
import 'package:runwild/domain/tracking/activity_record.dart';
import 'package:runwild/features/run/application/activity_sync.dart';
import 'package:runwild/features/run/application/run_journal.dart';

void main() {
  group('Polyline encoding and simplification', () {
    test('encodePolyline encodes coordinates accurately and handles empty', () {
      expect(encodePolyline([]), '');

      final points = [
        (latitude: 38.5, longitude: -120.2),
        (latitude: 40.7, longitude: -120.95),
        (latitude: 43.252, longitude: -126.453),
      ];

      final encoded = encodePolyline(points);
      expect(encoded.isNotEmpty, isTrue);
      // Validasi string karakter polyline standar
      expect(encoded, equals('_p~iF~ps|U_ulLnnqC_mqNvxq`@'));
    });

    test('simplifyPoints preserves endpoints and bounds count', () {
      final points = [
        for (var i = 0; i < 1000; i++)
          (latitude: -6.2 + (i * 0.0001), longitude: 106.8 + (i * 0.0001)),
      ];
      final simplified = simplifyPoints(points, maxPoints: 100);
      expect(simplified.length, lessThanOrEqualTo(101));
      expect(simplified.first, equals(points.first));
      expect(simplified.last, equals(points.last));
    });
  });

  group('ActivityRecord domain model', () {
    test('toFirestoreMap generates valid idempotent schema fields', () {
      final now = DateTime.utc(2026, 11, 16, 8, 30);
      final record = ActivityRecord(
        id: 'act_10_1731745800000',
        ownerId: 'runner_123',
        type: ActivityType.runWalk,
        mode: ActivityMode.interval,
        title: 'Lari Pagi',
        startedAt: now,
        endedAt: now.add(const Duration(minutes: 25)),
        movingTime: const Duration(minutes: 24),
        elapsedTime: const Duration(minutes: 25),
        distanceMeters: 4500.0,
        averageSpeedMps: 3.125,
        averagePaceSecPerKm: 320,
        estimatedCalories: 315,
        trackPointCount: 120,
        polyline: '_p~iF~ps|U',
        feeling: 'pas',
        note: 'Sesi latihan interval mantap',
        intervalSummary: {
          'warmupSec': 300,
          'runSec': 120,
          'walkSec': 60,
          'rounds': 8,
        },
      );

      final map = record.toFirestoreMap(
        timestampConverter: (dt) => dt.toIso8601String(),
      );

      expect(map['id'], 'act_10_1731745800000');
      expect(map['type'], 'runWalk');
      expect(map['mode'], 'interval');
      expect(map['title'], 'Lari Pagi');
      expect(map['distanceM'], 4500.0);
      expect(map['movingTimeSec'], 1440);
      expect(map['elapsedTimeSec'], 1500);
      expect(map['feeling'], 'pas');
      expect(map['visibility'], 'private');
      expect(map['source'], 'gps');
      expect(map['deviceInfo'], isA<Map<String, dynamic>>());
      expect(map['interval']['rounds'], 8);
    });

    test('defaultTitle formats correctly for morning, afternoon, evening', () {
      expect(ActivityRecord.defaultTitle(DateTime(2026, 1, 1, 6)), 'Lari Pagi');
      expect(
        ActivityRecord.defaultTitle(DateTime(2026, 1, 1, 13)),
        'Lari Siang',
      );
      expect(
        ActivityRecord.defaultTitle(DateTime(2026, 1, 1, 17)),
        'Lari Sore',
      );
      expect(
        ActivityRecord.defaultTitle(DateTime(2026, 1, 1, 20)),
        'Lari Malam',
      );
    });
  });

  group('RunJournal v4 offline queue and sync tracking', () {
    test('Unsynced sessions query and markSynced operation', () async {
      final dir = await Directory.systemTemp.createTemp('runwild-sync-');
      addTearDown(() => dir.delete(recursive: true));
      final dbFile = File('${dir.path}${Platform.pathSeparator}sync.sqlite');

      final journal = RunJournal(NativeDatabase(dbFile));
      addTearDown(journal.close);

      final startedAt = DateTime.utc(2026, 11, 16, 7, 0);
      final sessionId = await journal.begin(
        'user_abc',
        startedAt,
        interval: defaultIntervalConfig,
      );

      // Sesi belum selesai -> tidak muncul di unsynced
      expect(await journal.unsyncedSessions('user_abc'), isEmpty);

      // Simpan checkpoint dan tandai selesai
      await journal.checkpoint(
        'user_abc',
        (
          id: sessionId,
          startedAt: startedAt,
          meters: 3200.0,
          moving: const Duration(minutes: 18),
          elapsed: const Duration(minutes: 19),
          points: 10,
        ),
        const [],
        finish: true,
      );
      await journal.updateSummary(
        'user_abc',
        sessionId,
        feeling: 'mudah',
        note: 'Ringan dan santai',
      );

      // Sekarang harus muncul di antrean belum tersinkron
      final unsynced = await journal.unsyncedSessions('user_abc');
      expect(unsynced.length, 1);
      expect(unsynced.first.id, sessionId);
      expect(unsynced.first.feeling, 'mudah');
      expect(unsynced.first.note, 'Ringan dan santai');

      // Akun lain tidak boleh melihat sesi user_abc
      expect(await journal.unsyncedSessions('user_other'), isEmpty);

      // Tandai sudah tersinkronkan
      await journal.markSynced('user_abc', sessionId, 'act_cloud_id_999');

      // Setelah ditandai synced, antrean harus kosong
      expect(await journal.unsyncedSessions('user_abc'), isEmpty);
    });

    test(
      'FirestoreActivitySyncRepository handles offline / no-firebase safely',
      () async {
        final dir = await Directory.systemTemp.createTemp('runwild-sync-repo-');
        addTearDown(() => dir.delete(recursive: true));
        final dbFile = File('${dir.path}${Platform.pathSeparator}repo.sqlite');

        final journal = RunJournal(NativeDatabase(dbFile));
        addTearDown(journal.close);

        final repo = FirestoreActivitySyncRepository(journal);

        // Tanpa Firebase terinisialisasi (lingkungan headless/test), harus return 0 tanpa melempar exception fatal
        final synced = await repo.syncPending('user_abc');
        expect(synced, 0);

        final pulled = await repo.pullCloudHistory('user_abc');
        expect(pulled, 0);

        // deleteActivity and updateActivity also execute safely without error
        await repo.deleteActivity('user_abc', 'act_123');
        await repo.updateActivity(
          'user_abc',
          'act_123',
          title: 'New Title',
          note: 'New Note',
        );
      },
    );

    test(
      'importSession imports, deduplicates and resolves offline conflicts',
      () async {
        final db = RunJournal(NativeDatabase.memory());
        addTearDown(db.close);

        final when = DateTime.utc(2026, 11, 16, 5, 30);
        final id1 = await db.importSession(
          owner: 'user_x',
          activityId: 'act_cloud_001',
          startedAt: when,
          meters: 5000.0,
          moving: const Duration(minutes: 25),
          elapsed: const Duration(minutes: 26),
          title: 'Morning 5K',
          feeling: 'easy',
          note: 'First import',
          routePoints: const [
            (latitude: -6.2, longitude: 106.8),
            (latitude: -6.21, longitude: 106.81),
          ],
        );

        expect(id1, greaterThan(0));
        final record = await db.session('user_x', id1);
        expect(record, isNotNull);
        expect(record!.activityId, 'act_cloud_001');
        expect(record.title, 'Morning 5K');
        expect(record.meters, 5000.0);
        expect(record.synced, isTrue);

        final points = await db.sessionPoints(id1);
        expect(points.length, 2);
        expect(points.first.latitude, -6.2);
        expect(points.last.latitude, -6.21);

        // Deduplication test: re-importing same activityId does NOT create duplicate
        final id2 = await db.importSession(
          owner: 'user_x',
          activityId: 'act_cloud_001',
          startedAt: when,
          meters: 5000.0,
          moving: const Duration(minutes: 25),
          elapsed: const Duration(minutes: 26),
          title: 'Updated 5K Title',
          feeling: 'normal',
          note: 'Updated Note',
        );
        expect(id2, equals(id1));

        // Because synced == 1, title and note are updated
        final updated = await db.session('user_x', id1);
        expect(updated!.title, 'Updated 5K Title');
        expect(updated.feeling, 'normal');

        // Offline conflict test: if local was edited offline (synced == 0),
        // cloud pull must NOT overwrite local pending changes!
        await db.updateSession(
          'user_x',
          id1,
          title: 'Offline Edited Title',
          note: 'Local changes pending sync',
        );
        final localBeforePull = await db.session('user_x', id1);
        expect(localBeforePull!.synced, isFalse);

        final id3 = await db.importSession(
          owner: 'user_x',
          activityId: 'act_cloud_001',
          startedAt: when,
          meters: 5000.0,
          moving: const Duration(minutes: 25),
          elapsed: const Duration(minutes: 26),
          title: 'Cloud Stale Title',
        );
        expect(id3, equals(id1));

        // Local pending changes are preserved!
        final localAfterPull = await db.session('user_x', id1);
        expect(localAfterPull!.title, 'Offline Edited Title');
        expect(localAfterPull.note, 'Local changes pending sync');
      },
    );
  });
}
