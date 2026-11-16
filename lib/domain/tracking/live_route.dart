import '../../core/constants/tracking_limits.dart';
import 'tracking_engine.dart';

typedef RoutePoint = ({double latitude, double longitude});
typedef LiveRouteSnapshot = ({
  List<List<RoutePoint>> segments,
  GpsSample? position,
  Duration? age,
});

final class LiveRoute {
  final _segments = <List<RoutePoint>>[];
  GpsSample? _position;
  List<List<RoutePoint>> _snapshot = const [];

  void restore(Iterable<({RoutePoint point, bool segmentStart})> points) {
    for (final value in points) {
      if (_segments.isEmpty || value.segmentStart) _segments.add([]);
      _segments.last.add(value.point);
    }
    _freeze();
  }

  void add(GpsSample sample, SampleResult result, Duration now) {
    if (sample.latitude.isFinite &&
        sample.longitude.isFinite &&
        sample.latitude.abs() <= 90 &&
        sample.longitude.abs() <= 180 &&
        sample.accuracyMeters.isFinite &&
        sample.accuracyMeters >= 0 &&
        sample.accuracyMeters <= TrackingLimits.maxAccuracyMeters &&
        sample.capturedAt <= now &&
        now - sample.capturedAt <= TrackingLimits.maxLocationAge) {
      final previous = _position;
      final delta = previous == null
          ? Duration.zero
          : sample.capturedAt - previous.capturedAt;
      if (previous == null ||
          delta > Duration.zero &&
              haversineMeters(previous, sample) <=
                  TrackingLimits.maxSpeedMetersPerSecond *
                      delta.inMicroseconds /
                      Duration.microsecondsPerSecond) {
        _position = sample;
      }
    }
    if (result == SampleResult.ignored) return;
    if (_segments.isEmpty || result == SampleResult.segmentStart) {
      _segments.add([]);
    }
    _segments.last.add((
      latitude: sample.latitude,
      longitude: sample.longitude,
    ));
    _freeze();
  }

  void _freeze() => _snapshot = List.unmodifiable([
    for (final segment in _segments) List<RoutePoint>.unmodifiable(segment),
  ]);

  LiveRouteSnapshot snapshot(Duration now) => (
    segments: _snapshot,
    position: _position,
    age: _position == null ? null : now - (_position?.capturedAt ?? now),
  );
}
