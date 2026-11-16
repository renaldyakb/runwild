import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/tracking/activity_detail.dart';
import '../../auth/application/auth_session.dart';
import '../../run/application/activity_sync.dart';
import '../../run/application/run_journal.dart';
import 'activity_history.dart';

final activityDetailProvider = FutureProvider.autoDispose
    .family<ActivityDetail?, int>((ref, sessionId) async {
      ref.watch(authSessionProvider);
      final owner = ref.watch(runOwnerProvider)();
      if (owner == null) return null;

      final journal = ref.watch(runJournalProvider);
      final record = await journal.session(owner, sessionId);
      if (record == null) return null;

      final rawPoints = await journal.sessionPoints(sessionId, owner: owner);
      final points = [
        for (final p in rawPoints)
          (
            seq: p.seq,
            capturedAt: p.capturedAt,
            latitude: p.latitude,
            longitude: p.longitude,
            accuracy: p.accuracy,
            segmentStart: p.segmentStart,
          ),
      ];

      final splits = calculateSplitsFromPoints(
        points,
        totalMeters: record.meters,
        totalMoving: record.moving,
      );

      final intervalSummary = parseIntervalSummary(
        record.intervalJson,
        record.elapsed,
      );

      return ActivityDetail(
        id: record.id,
        owner: record.owner,
        startedAt: record.startedAt,
        meters: record.meters,
        moving: record.moving,
        elapsed: record.elapsed,
        pointsCount: record.points,
        synced: record.synced,
        points: points,
        splits: splits,
        title: record.title,
        note: record.note,
        feeling: record.feeling,
        intervalJson: record.intervalJson,
        activityId: record.activityId,
        intervalSummary: intervalSummary,
      );
    });

class ActivityDetailController {
  ActivityDetailController(this.ref);
  final Ref ref;

  Future<void> updateDetails(
    int sessionId, {
    String? title,
    String? note,
    String? feeling,
  }) async {
    final owner = ref.read(runOwnerProvider)();
    if (owner == null) return;

    final journal = ref.read(runJournalProvider);
    final detail = await ref.read(activityDetailProvider(sessionId).future);
    if (detail == null) return;

    final cleanTitle = title?.trim().isEmpty ?? true ? null : title!.trim();
    final cleanNote = note?.trim().isEmpty ?? true ? null : note!.trim();

    await journal.updateSession(
      owner,
      sessionId,
      title: cleanTitle,
      note: cleanNote,
      feeling: feeling ?? detail.feeling,
    );

    if (detail.activityId != null) {
      unawaited(
        ref
            .read(activitySyncRepositoryProvider)
            .updateActivity(
              owner,
              detail.activityId!,
              title: cleanTitle,
              note: cleanNote,
              feeling: feeling ?? detail.feeling,
            ),
      );
    } else {
      unawaited(ref.read(activitySyncRepositoryProvider).syncPending(owner));
    }

    ref.invalidate(activityDetailProvider(sessionId));
    unawaited(ref.read(activityHistoryProvider.notifier).refresh());
  }

  Future<void> deleteSession(int sessionId) async {
    final owner = ref.read(runOwnerProvider)();
    if (owner == null) return;

    final journal = ref.read(runJournalProvider);
    final detail = await ref.read(activityDetailProvider(sessionId).future);

    await journal.discardSession(owner, sessionId);

    if (detail?.activityId != null) {
      unawaited(
        ref
            .read(activitySyncRepositoryProvider)
            .deleteActivity(owner, detail!.activityId!),
      );
    }

    ref.invalidate(activityDetailProvider(sessionId));
    unawaited(ref.read(activityHistoryProvider.notifier).refresh());
  }
}

final activityDetailControllerProvider = Provider<ActivityDetailController>(
  (ref) => ActivityDetailController(ref),
);
