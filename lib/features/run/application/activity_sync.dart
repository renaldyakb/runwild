import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_version.dart';
import '../../../design/components/rw_route_view.dart';
import '../../../domain/interval/interval_config.dart';
import '../../../domain/tracking/activity_record.dart';
import 'run_journal.dart';

/// Kontrak antarmuka sinkronisasi sesi lari ke cloud
abstract interface class ActivitySyncRepository {
  /// Menyinkronkan semua sesi lari lokal yang berstatus selesai namun belum tersinkron
  /// ke cloud Firestore secara idempoten.
  /// Mengembalikan jumlah sesi yang berhasil disinkronkan pada panggilan ini.
  Future<int> syncPending(String owner);

  /// Menghapus aktivitas dari cloud Firestore bila sudah pernah tersinkron.
  Future<void> deleteActivity(String owner, String activityId);

  /// Memperbarui informasi judul/catatan/feeling aktivitas di cloud Firestore.
  Future<void> updateActivity(
    String owner,
    String activityId, {
    String? title,
    String? note,
    String? feeling,
  });

  /// Mengunduh aktivitas dari Firestore ke database lokal SQLite jika belum ada di lokal.
  /// Mendukung paginasi via [limit] dan [before] timestamp cursor.
  /// Mengembalikan jumlah sesi baru yang berhasil diimpor ke SQLite lokal.
  Future<int> pullCloudHistory(
    String owner, {
    int limit = 20,
    DateTime? before,
  });
}

final activitySyncRepositoryProvider = Provider<ActivitySyncRepository>((ref) {
  final journal = ref.watch(runJournalProvider);
  return FirestoreActivitySyncRepository(journal);
});

class FirestoreActivitySyncRepository implements ActivitySyncRepository {
  FirestoreActivitySyncRepository(this._journal, [this._firestore]);

  final RunJournal _journal;
  final FirebaseFirestore? _firestore;

  FirebaseFirestore? get _client {
    if (_firestore != null) return _firestore;
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instance;
  }

  @override
  Future<int> syncPending(String owner) async {
    final client = _client;
    if (client == null) {
      // Firebase belum diinisialisasi atau lingkungan headless
      return 0;
    }

    final pendingSessions = await _journal.unsyncedSessions(owner);
    if (pendingSessions.isEmpty) return 0;

    var syncedCount = 0;

    for (final session in pendingSessions) {
      try {
        // ID idempoten: berbasis session id lokal dan timestamp mulai
        final activityId =
            session.activityId ??
            'act_${session.id}_${session.startedAt.millisecondsSinceEpoch}';

        // Ambil titik rute untuk polyline
        final points = await _journal.sessionPoints(session.id);
        final simplified = simplifyPoints([
          for (final p in points)
            (latitude: p.latitude, longitude: p.longitude),
        ]);
        final polyline = encodePolyline(simplified);

        // Parse konfigurasi interval jika ada
        Map<String, dynamic>? intervalMap;
        var mode = ActivityMode.free;
        if (session.intervalJson != null && session.intervalJson!.isNotEmpty) {
          mode = ActivityMode.interval;
          try {
            final config = decodeInterval(session.intervalJson!);
            final progress = await _journal.intervalProgress(owner, session.id);
            intervalMap = {
              'warmupSec': config.warmup.inSeconds,
              'runSec': config.run.inSeconds,
              'walkSec': config.walk.inSeconds,
              'rounds': config.rounds,
              'startWithWalk': config.startWithWalk,
              'cooldownSec': config.cooldown.inSeconds,
              if (progress != null) ...{
                'actualRounds': progress.rounds,
                'actualRunSec': progress.run.inSeconds,
                'actualWalkSec': progress.walk.inSeconds,
              },
            };
          } catch (_) {}
        }

        final movingSec = session.moving.inSeconds;
        final avgSpeed = movingSec > 0 ? (session.meters / movingSec) : 0.0;
        final avgPace = session.meters >= 10.0 && movingSec > 0
            ? (movingSec / (session.meters / 1000.0)).round()
            : null;

        // Estimasi kalori MET standar (65kg x 1.036 faktor)
        final distanceKm = session.meters / 1000.0;
        final calEst = distanceKm > 0 ? (distanceKm * 65.0 * 1.036).round() : 0;

        final title =
            session.title ?? ActivityRecord.defaultTitle(session.startedAt);

        final record = ActivityRecord(
          appVersion: AppVersion.current,
          id: activityId,
          ownerId: owner,
          type: mode == ActivityMode.interval
              ? ActivityType.runWalk
              : ActivityType.run,
          mode: mode,
          title: title,
          startedAt: session.startedAt,
          endedAt: session.startedAt.add(session.elapsed),
          movingTime: session.moving,
          elapsedTime: session.elapsed,
          distanceMeters: session.meters,
          averageSpeedMps: avgSpeed,
          averagePaceSecPerKm: avgPace,
          estimatedCalories: calEst,
          trackPointCount: session.points,
          polyline: polyline,
          feeling: session.feeling,
          note: session.note,
          intervalSummary: intervalMap,
          platform: Platform.isAndroid
              ? 'android'
              : (Platform.isIOS ? 'ios' : 'desktop'),
        );

        final firestoreMap = record.toFirestoreMap(
          timestampConverter: (dt) => Timestamp.fromDate(dt),
        );

        // Penulisan idempoten via doc(activityId).set(..., SetOptions(merge: true))
        await client
            .collection('users')
            .doc(owner)
            .collection('activities')
            .doc(activityId)
            .set(firestoreMap, SetOptions(merge: true));

        // Tandai sukses sinkron di database lokal
        await _journal.markSynced(owner, session.id, activityId);
        syncedCount++;
      } catch (_) {
        // Error offline atau timeout jaringan: hentikan loop sementara,
        // biarkan sesi tersimpan di SQLite untuk dicoba lagi pada pemanggilan berikutnya.
        break;
      }
    }

    return syncedCount;
  }

  @override
  Future<void> deleteActivity(String owner, String activityId) async {
    final client = _client;
    if (client == null) return;
    try {
      await client
          .collection('users')
          .doc(owner)
          .collection('activities')
          .doc(activityId)
          .delete();
    } catch (_) {}
  }

  @override
  Future<void> updateActivity(
    String owner,
    String activityId, {
    String? title,
    String? note,
    String? feeling,
  }) async {
    final client = _client;
    if (client == null) return;
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (title != null) updates['title'] = title;
      if (note != null) updates['note'] = note;
      if (feeling != null) updates['feeling'] = feeling;
      await client
          .collection('users')
          .doc(owner)
          .collection('activities')
          .doc(activityId)
          .update(updates);
    } catch (_) {}
  }

  @override
  Future<int> pullCloudHistory(
    String owner, {
    int limit = 20,
    DateTime? before,
  }) async {
    final client = _client;
    if (client == null) return 0;

    try {
      var query = client
          .collection('users')
          .doc(owner)
          .collection('activities')
          .orderBy('startedAt', descending: true)
          .limit(limit);

      if (before != null) {
        query = query.startAfter([Timestamp.fromDate(before)]);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) return 0;

      var importedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Lewati aktivitas yang sudah di-soft delete
        if (data['deletedAt'] != null) continue;

        final activityId = doc.id;
        final startedTimestamp = data['startedAt'] as Timestamp?;
        final startedAt = startedTimestamp?.toDate() ?? DateTime.now();

        final distanceM = (data['distanceM'] as num?)?.toDouble() ?? 0.0;
        final movingTimeSec = (data['movingTimeSec'] as num?)?.toInt() ?? 0;
        final elapsedTimeSec =
            (data['elapsedTimeSec'] as num?)?.toInt() ?? movingTimeSec;

        final title = data['title'] as String?;
        final feeling = data['feeling'] as String?;
        final note = data['note'] as String?;

        // Rekonstruksi interval jika ada
        String? intervalJson;
        int? actualRounds;
        int? actualRunSec;
        int? actualWalkSec;
        final intervalMap = data['interval'];
        if (intervalMap is Map) {
          try {
            final config = (
              warmup: Duration(
                seconds: (intervalMap['warmupSec'] as num?)?.toInt() ?? 0,
              ),
              run: Duration(
                seconds: (intervalMap['runSec'] as num?)?.toInt() ?? 60,
              ),
              walk: Duration(
                seconds: (intervalMap['walkSec'] as num?)?.toInt() ?? 60,
              ),
              rounds: (intervalMap['rounds'] as num?)?.toInt(),
              startWithWalk: intervalMap['startWithWalk'] == true,
              cooldown: Duration(
                seconds: (intervalMap['cooldownSec'] as num?)?.toInt() ?? 0,
              ),
            );
            intervalJson = encodeInterval(config);
            actualRounds = (intervalMap['actualRounds'] as num?)?.toInt();
            actualRunSec = (intervalMap['actualRunSec'] as num?)?.toInt();
            actualWalkSec = (intervalMap['actualWalkSec'] as num?)?.toInt();
          } catch (_) {}
        }

        // Decode polyline menjadi titik koordinat rute
        final polyline = data['polyline'] as String? ?? '';
        final points = decodePolylinePoints(polyline);

        await _journal.importSession(
          owner: owner,
          activityId: activityId,
          startedAt: startedAt,
          meters: distanceM,
          moving: Duration(seconds: movingTimeSec),
          elapsed: Duration(seconds: elapsedTimeSec),
          title: title,
          feeling: feeling,
          note: note,
          intervalJson: intervalJson,
          intervalRounds: actualRounds,
          intervalRun: actualRunSec == null
              ? null
              : Duration(seconds: actualRunSec),
          intervalWalk: actualWalkSec == null
              ? null
              : Duration(seconds: actualWalkSec),
          routePoints: points,
        );

        importedCount++;
      }

      return importedCount;
    } catch (_) {
      // Graceful error/offline fallback
      return 0;
    }
  }
}
