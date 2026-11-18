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

/// Rencana interval yang tersimpan pada sesi (bukan hasil aktual).
typedef IntervalPlan = ({
  Duration run,
  Duration walk,
  int? rounds,
  bool startWithWalk,
});

IntervalPlan? parseIntervalPlan(String? intervalJson) {
  if (intervalJson == null || intervalJson.isEmpty) return null;
  try {
    final config = decodeInterval(intervalJson);
    return (
      run: config.run,
      walk: config.walk,
      rounds: config.rounds,
      startWithWalk: config.startWithWalk,
    );
  } catch (_) {
    return null;
  }
}

/// Ringkasan interval **aktual**; null bila sesi lama belum menyimpan detail
/// aktual, sehingga tampilan memakai kartu rencana, bukan angka karangan.
IntervalSummary? buildIntervalSummary({
  required String? intervalJson,
  required int? completedRounds,
  required Duration? runTime,
  required Duration? walkTime,
}) {
  final plan = parseIntervalPlan(intervalJson);
  if (plan == null ||
      completedRounds == null ||
      runTime == null ||
      walkTime == null) {
    return null;
  }
  return (
    completedRounds: completedRounds,
    totalRounds: plan.rounds,
    runTime: runTime,
    walkTime: walkTime,
  );
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
    this.intervalPlan,
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
  final IntervalPlan? intervalPlan;

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
