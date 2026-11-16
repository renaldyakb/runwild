import 'dart:collection';
import 'dart:math' as math;

import '../../core/constants/tracking_limits.dart';
import 'run_summary.dart';

final class GpsSample {
  const GpsSample({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;

  /// Time on the same monotonic clock as the engine.
  final Duration capturedAt;
}

enum TrackingState { active, manuallyPaused, autoPaused, finished }

enum SampleResult { segmentStart, recorded, ignored }

/// Great-circle distance in meters between two valid GPS coordinates.
double haversineMeters(GpsSample from, GpsSample to) {
  const radians = math.pi / 180;
  final latA = from.latitude * radians;
  final latB = to.latitude * radians;
  final sinLat = math.sin((latB - latA) / 2);
  final sinLon = math.sin((to.longitude - from.longitude) * radians / 2);
  final a = sinLat * sinLat + math.cos(latA) * math.cos(latB) * sinLon * sinLon;
  return 2 *
      TrackingLimits.earthRadiusMeters *
      math.asin(math.sqrt(a.clamp(0.0, 1.0)));
}

/// One session, using monotonically increasing time from [clock].
final class TrackingEngine {
  TrackingEngine({required Duration Function() clock, bool autoPause = true})
    : this._(clock, autoPause);

  TrackingEngine._(this._clock, this._autoPause) {
    _startedAt = _clock();
    _activeSince = _startedAt;
  }

  /// Restores saved totals and waits for a new route anchor.
  factory TrackingEngine.restore({
    required Duration Function() clock,
    required double meters,
    required Duration moving,
    bool autoPause = true,
  }) {
    final engine = TrackingEngine(clock: clock, autoPause: autoPause)
      .._distance = meters
      .._moving = moving
      .._lastSplitMovingTime = moving;
    final completedCount = meters ~/ TrackingLimits.metersPerKilometer;
    if (completedCount > 0 && moving > Duration.zero) {
      final perKmDuration = Duration(
        microseconds: moving.inMicroseconds ~/ completedCount,
      );
      final pace =
          perKmDuration.inMicroseconds / Duration.microsecondsPerSecond;
      for (var i = 1; i <= completedCount; i++) {
        engine._completedSplits.add((
          kilometer: i,
          distanceMeters: TrackingLimits.metersPerKilometer.toDouble(),
          duration: perKmDuration,
          paceSecondsPerKm: pace,
        ));
      }
    }
    return engine;
  }

  final Duration Function() _clock;
  final bool _autoPause;
  final _pace = Queue<(Duration, double)>();
  late final Duration _startedAt;
  Duration? _activeSince;
  Duration? _finishedAt;
  Duration? _slowSince;
  Duration? _fastSince;
  Duration? _lastSeenAt;
  GpsSample? _motionAnchor;
  GpsSample? _routeAnchor;
  var _moving = Duration.zero;
  var _distance = 0.0;
  var _state = TrackingState.active;
  final _completedSplits = <KmSplit>[];
  var _lastSplitMovingTime = Duration.zero;

  TrackingState get state => _state;
  double get distanceMeters => _distance;
  Duration get elapsedTime => (_finishedAt ?? _clock()) - _startedAt;
  Duration get movingTime {
    final since = _activeSince;
    return since == null ? _moving : _moving + (_clock() - since);
  }

  /// List of kilometer splits (including any current partial split).
  List<KmSplit> get splits {
    final result = List<KmSplit>.of(_completedSplits);
    final completedDistance =
        _completedSplits.length * TrackingLimits.metersPerKilometer;
    final remainingDistance = _distance - completedDistance;
    if (remainingDistance >= 10.0) {
      final currentMoving = movingTime;
      final remainingDuration = currentMoving - _lastSplitMovingTime;
      if (remainingDuration > Duration.zero) {
        final pace =
            remainingDuration.inMicroseconds /
            Duration.microsecondsPerSecond *
            TrackingLimits.metersPerKilometer /
            remainingDistance;
        result.add((
          kilometer: _completedSplits.length + 1,
          distanceMeters: remainingDistance,
          duration: remainingDuration,
          paceSecondsPerKm: pace,
        ));
      }
    }
    return result;
  }

  /// Session average, in seconds per kilometer, once distance is measurable.
  double? get averagePace => _distance == 0
      ? null
      : movingTime.inMicroseconds /
            Duration.microsecondsPerSecond *
            TrackingLimits.metersPerKilometer /
            _distance;

  /// Rolling pace in seconds per kilometer, or null until enough data exists.
  double? get currentPace {
    if (_pace.isEmpty || _state != TrackingState.active) return null;
    final now = _clock();
    final end = _pace.last.$1;
    final cutoff = end - TrackingLimits.paceWindow;
    if (now - end >= TrackingLimits.paceWindow) return null;
    _trimPace(cutoff);
    final first = _pace.first;
    if (first.$1 > cutoff) return null;
    var metersAtCutoff = first.$2;
    if (first.$1 < cutoff && _pace.length > 1) {
      final next = _pace.elementAt(1);
      final fraction =
          (cutoff - first.$1).inMicroseconds /
          (next.$1 - first.$1).inMicroseconds;
      metersAtCutoff += (next.$2 - first.$2) * fraction;
    }
    final meters = _pace.last.$2 - metersAtCutoff;
    if (meters < TrackingLimits.minPaceWindowMeters) return null;
    return TrackingLimits.paceWindow.inSeconds *
        TrackingLimits.metersPerKilometer /
        meters;
  }

  /// Records a valid fix, identifying the first point after each pause.
  SampleResult addSample(GpsSample sample) {
    final last = _lastSeenAt;
    if (_state == TrackingState.finished ||
        _state == TrackingState.manuallyPaused ||
        sample.capturedAt < (_activeSince ?? _startedAt) ||
        sample.capturedAt > _clock() ||
        (last != null && sample.capturedAt <= last)) {
      return SampleResult.ignored;
    }
    _lastSeenAt = sample.capturedAt;
    if (!_valid(sample)) {
      _resetMotion();
      return SampleResult.ignored;
    }
    final motion = _motionAnchor;
    final anchor = _routeAnchor;
    final distance = anchor == null ? 0.0 : haversineMeters(anchor, sample);
    if ((anchor != null &&
            _speed(distance, anchor, sample) >
                TrackingLimits.maxSpeedMetersPerSecond) ||
        (motion != null &&
            _speed(haversineMeters(motion, sample), motion, sample) >
                TrackingLimits.maxSpeedMetersPerSecond)) {
      _resetMotion();
      return SampleResult.ignored;
    }
    _motionAnchor = sample;
    final speed = motion == null
        ? null
        : _speed(haversineMeters(motion, sample), motion, sample);
    if (_autoPause) {
      if (motion == null ||
          sample.capturedAt - motion.capturedAt >
              TrackingLimits.maxMotionSampleGap) {
        _slowSince = null;
        _fastSince = null;
      } else if (_state == TrackingState.autoPaused) {
        if (speed != null &&
            speed > TrackingLimits.resumeSpeedMetersPerSecond) {
          _fastSince ??= motion.capturedAt;
          if (sample.capturedAt - (_fastSince ?? sample.capturedAt) >=
              TrackingLimits.autoResumeDelay) {
            _resumeAt(sample.capturedAt);
            _motionAnchor = sample;
          }
        } else {
          _fastSince = null;
        }
      } else if (speed != null &&
          speed < TrackingLimits.slowSpeedMetersPerSecond) {
        _slowSince ??= motion.capturedAt;
        if (sample.capturedAt - (_slowSince ?? sample.capturedAt) >=
            TrackingLimits.autoPauseDelay) {
          _pauseAt(sample.capturedAt, TrackingState.autoPaused);
          _motionAnchor = sample;
        }
      } else {
        _slowSince = null;
      }
    }
    if (_state != TrackingState.active) return SampleResult.ignored;
    if (_routeAnchor == null) {
      _routeAnchor = sample;
      _addPace(sample);
      return SampleResult.segmentStart;
    }

    // Keep the route anchor across slow jitter so small steps can accumulate.
    if (distance < TrackingLimits.jitterMeters &&
        (speed ?? 0) < TrackingLimits.resumeSpeedMetersPerSecond) {
      _addPace(sample);
      return SampleResult.ignored;
    }
    _distance += distance;
    _checkSplitMilestone();
    _routeAnchor = sample;
    _addPace(sample);
    return SampleResult.recorded;
  }

  void _checkSplitMilestone() {
    while (_distance >=
        (_completedSplits.length + 1) * TrackingLimits.metersPerKilometer) {
      final targetKm = _completedSplits.length + 1;
      final currentMoving = movingTime;
      final splitDuration = currentMoving - _lastSplitMovingTime;
      final pace =
          splitDuration.inMicroseconds /
          Duration.microsecondsPerSecond *
          TrackingLimits.metersPerKilometer /
          TrackingLimits.metersPerKilometer;
      _completedSplits.add((
        kilometer: targetKm,
        distanceMeters: TrackingLimits.metersPerKilometer.toDouble(),
        duration: splitDuration,
        paceSecondsPerKm: pace,
      ));
      _lastSplitMovingTime = currentMoving;
    }
  }

  /// Pauses until explicitly resumed, including when auto-paused.
  void pause() {
    if (_state == TrackingState.active || _state == TrackingState.autoPaused) {
      _pauseAt(_clock(), TrackingState.manuallyPaused);
    }
  }

  /// Resumes from either pause state and starts a fresh GPS segment.
  void resume() {
    if (_state == TrackingState.manuallyPaused ||
        _state == TrackingState.autoPaused) {
      _resumeAt(_clock());
    }
  }

  /// Freezes metrics and stops accepting samples.
  void finish() {
    if (_state == TrackingState.finished) return;
    final now = _clock();
    _pauseAt(now, TrackingState.finished);
    _finishedAt = now;
  }

  bool _valid(GpsSample sample) =>
      sample.latitude >= -90 &&
      sample.latitude <= 90 &&
      sample.longitude >= -180 &&
      sample.longitude <= 180 &&
      sample.accuracyMeters >= 0 &&
      sample.accuracyMeters <= TrackingLimits.maxAccuracyMeters;

  double _speed(double distance, GpsSample from, GpsSample to) =>
      distance *
      Duration.microsecondsPerSecond /
      (to.capturedAt - from.capturedAt).inMicroseconds;

  void _resetMotion() {
    _motionAnchor = null;
    _slowSince = null;
    _fastSince = null;
  }

  void _pauseAt(Duration time, TrackingState state) {
    final since = _activeSince;
    if (since != null) _moving += time - since;
    _activeSince = null;
    _state = state;
    _routeAnchor = null;
    _pace.clear();
    _resetMotion();
  }

  void _resumeAt(Duration time) {
    _activeSince = time;
    _state = TrackingState.active;
    _resetMotion();
  }

  void _addPace(GpsSample sample) {
    _pace.add((sample.capturedAt, _distance));
    _trimPace(sample.capturedAt - TrackingLimits.paceWindow);
  }

  void _trimPace(Duration cutoff) {
    while (_pace.length > 1 && _pace.elementAt(1).$1 <= cutoff) {
      _pace.removeFirst();
    }
  }
}
