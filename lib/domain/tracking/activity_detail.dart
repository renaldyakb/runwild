// Pure Dart activity detail domain models and calculations.

import '../../core/constants/tracking_limits.dart';
import '../interval/interval_config.dart';
import 'run_summary.dart';
import 'tracking_engine.dart';

typedef ActivityPoint = ({
  int seq,
  Duration capturedAt,
  double latitude,
  double longitude,
  double accuracy,
  bool segmentStart,
});

/// Pure function to calculate kilometer splits from GPS points.
List<KmSplit> calculateSplitsFromPoints(
  List<ActivityPoint> points, {
  double totalMeters = 0.0,
  Duration totalMoving = Duration.zero,
}) {
  if (points.length < 2) {
    if (totalMeters >= 100.0) {
      final pace = totalMoving.inSeconds / (totalMeters / 1000.0);
      return [
        (
          kilometer: 1,
          distanceMeters: totalMeters,
          duration: totalMoving,
          paceSecondsPerKm: pace,
        ),
      ];
    }
    return const [];
  }

  final splits = <KmSplit>[];
  var accumulatedDist = 0.0;
  var accumulatedMoving = Duration.zero;
  var lastSplitDist = 0.0;
  var lastSplitMoving = Duration.zero;
  var targetDist = TrackingLimits.metersPerKilometer.toDouble();

  for (var i = 1; i < points.length; i++) {
    final prev = points[i - 1];
    final curr = points[i];
    if (curr.segmentStart) continue;

    final dist = haversineMeters(
      GpsSample(
        latitude: prev.latitude,
        longitude: prev.longitude,
        accuracyMeters: prev.accuracy,
        capturedAt: prev.capturedAt,
      ),
      GpsSample(
        latitude: curr.latitude,
        longitude: curr.longitude,
        accuracyMeters: curr.accuracy,
        capturedAt: curr.capturedAt,
      ),
    );
    final dt = curr.capturedAt - prev.capturedAt;
    accumulatedDist += dist;
    if (dt > Duration.zero) {
      accumulatedMoving += dt;
    }

    while (accumulatedDist >= targetDist) {
      final splitDist = targetDist - lastSplitDist;
      final splitDuration = accumulatedMoving - lastSplitMoving;
      final effectiveDuration = splitDuration > Duration.zero
          ? splitDuration
          : const Duration(seconds: 1);
      final pace =
          effectiveDuration.inMicroseconds /
          Duration.microsecondsPerSecond /
          (splitDist / 1000.0);

      splits.add((
        kilometer: splits.length + 1,
        distanceMeters: splitDist,
        duration: effectiveDuration,
        paceSecondsPerKm: pace,
      ));

      lastSplitDist = targetDist;
      lastSplitMoving = accumulatedMoving;
      targetDist += TrackingLimits.metersPerKilometer;
    }
  }

  final remainingDist = accumulatedDist - lastSplitDist;
  if (remainingDist >= 100.0) {
    final remainingMoving = accumulatedMoving - lastSplitMoving;
    final pace =
        remainingMoving.inMicroseconds /
        Duration.microsecondsPerSecond /
        (remainingDist / 1000.0);

    splits.add((
      kilometer: splits.length + 1,
      distanceMeters: remainingDist,
      duration: remainingMoving,
      paceSecondsPerKm: pace,
    ));
  } else if (splits.isEmpty && totalMeters >= 100.0) {
    splits.add((
      kilometer: 1,
      distanceMeters: totalMeters,
      duration: totalMoving,
      paceSecondsPerKm: totalMoving.inSeconds / (totalMeters / 1000.0),
    ));
  }

  return splits;
}

/// Helper untuk mengurai konfigurasi interval menjadi ringkasan yang mudah ditampilkan.
IntervalSummary? parseIntervalSummary(String? intervalJson, Duration elapsed) {
  if (intervalJson == null || intervalJson.isEmpty) return null;
  try {
    final config = decodeInterval(intervalJson);
    final runSec = config.run.inSeconds;
    final walkSec = config.walk.inSeconds;
    final cycleSec = runSec + walkSec;

    if (cycleSec <= 0) return null;

    final completedRounds = elapsed.inSeconds ~/ cycleSec;
    final totalRunSec = completedRounds * runSec;
    final totalWalkSec = completedRounds * walkSec;

    return (
      completedRounds: completedRounds,
      totalRounds: config.rounds,
      runTime: Duration(seconds: totalRunSec),
      walkTime: Duration(seconds: totalWalkSec),
    );
  } catch (_) {
    return null;
  }
}

/// Domain model detail lengkap sebuah sesi aktivitas.
class ActivityDetail {
  const ActivityDetail({
    required this.id,
    required this.owner,
    required this.startedAt,
    required this.meters,
    required this.moving,
    required this.elapsed,
    required this.pointsCount,
    required this.synced,
    required this.points,
    required this.splits,
    this.title,
    this.note,
    this.feeling,
    this.intervalJson,
    this.activityId,
    this.intervalSummary,
  });

  final int id;
  final String owner;
  final DateTime startedAt;
  final double meters;
  final Duration moving;
  final Duration elapsed;
  final int pointsCount;
  final bool synced;
  final List<ActivityPoint> points;
  final List<KmSplit> splits;
  final String? title;
  final String? note;
  final String? feeling;
  final String? intervalJson;
  final String? activityId;
  final IntervalSummary? intervalSummary;

  double? get averagePace => meters > 0 && moving > Duration.zero
      ? moving.inSeconds / (meters / 1000.0)
      : null;

  int get estimatedCalories {
    final km = meters / 1000.0;
    if (km <= 0) return 0;
    return (km * 65.0 * 1.036).round();
  }

  RunSummary toRunSummary() => RunSummary(
    sessionId: id,
    startedAt: startedAt,
    distanceMeters: meters,
    movingTime: moving,
    elapsedTime: elapsed,
    averagePace: averagePace,
    splits: splits,
    interval: intervalSummary,
    feeling: feeling != null ? RunFeeling.values.asNameMap()[feeling] : null,
    note: note,
  );
}
