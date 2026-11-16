import 'package:flutter_test/flutter_test.dart';
import 'package:runwild/domain/tracking/tracking_engine.dart';

class _Session {
  _Session({bool autoPause = true}) {
    engine = TrackingEngine(clock: () => now, autoPause: autoPause);
  }

  late final TrackingEngine engine;
  Duration now = Duration.zero;

  SampleResult fix(int seconds, double meters, {double accuracy = 5}) {
    now = Duration(seconds: seconds);
    return engine.addSample(_point(meters, now, accuracy: accuracy));
  }
}

GpsSample _point(double meters, Duration time, {double accuracy = 5}) =>
    GpsSample(
      latitude: 0,
      longitude: meters / 111195.08,
      accuracyMeters: accuracy,
      capturedAt: time,
    );

void main() {
  test('Haversine follows the shortest arc across the date line', () {
    const a = GpsSample(
      latitude: 0,
      longitude: 179.999,
      accuracyMeters: 5,
      capturedAt: Duration.zero,
    );
    const b = GpsSample(
      latitude: 0,
      longitude: -179.999,
      accuracyMeters: 5,
      capturedAt: Duration.zero,
    );
    expect(haversineMeters(a, b), closeTo(222.39, 0.02));
    expect(haversineMeters(a, a), 0);
  });

  test(
    'Rejects inaccurate, invalid, future, duplicate and implausible fixes',
    () {
      final s = _Session(autoPause: false);
      expect(s.fix(0, 0, accuracy: 31), SampleResult.ignored);
      expect(s.fix(1, 0, accuracy: 30), SampleResult.segmentStart);
      expect(s.fix(1, 4), SampleResult.ignored);
      expect(
        s.engine.addSample(_point(4, const Duration(seconds: 100))),
        SampleResult.ignored,
      );
      expect(s.fix(2, double.nan), SampleResult.ignored);
      expect(s.fix(3, 100), SampleResult.ignored);
      expect(s.fix(4, 9), SampleResult.recorded);
      expect(s.engine.distanceMeters, closeTo(9, 0.001));
    },
  );

  test('Slow movement accumulates without recording stationary jitter', () {
    final s = _Session(autoPause: false);
    s.fix(0, 0);
    expect(s.fix(4, 1), SampleResult.ignored);
    expect(s.fix(8, 2), SampleResult.ignored);
    expect(s.fix(12, 3.1), SampleResult.recorded);
    expect(s.engine.distanceMeters, closeTo(3.1, 0.001));
  });

  test(
    'Pace waits for 15 seconds and 20 m, then interpolates its boundary',
    () {
      final s = _Session(autoPause: false);
      expect(s.engine.averagePace, isNull);
      s.fix(0, 0);
      s.fix(14, 28);
      expect(s.engine.currentPace, isNull);
      s.fix(17, 34);
      expect(s.engine.currentPace, closeTo(500, 0.01));
      expect(s.engine.averagePace, closeTo(500, 0.01));
      s.now = const Duration(seconds: 33);
      expect(s.engine.currentPace, isNull);
      final slow = _Session(autoPause: false)
        ..fix(0, 0)
        ..fix(15, 15);
      expect(slow.engine.currentPace, isNull);
    },
  );

  test(
    'Manual pause excludes elapsed time and movement; finish freezes metrics',
    () {
      final s = _Session()
        ..fix(0, 0)
        ..fix(4, 12);
      s.engine.pause();
      expect(s.fix(10, 60), SampleResult.ignored);
      expect(s.engine.movingTime.inSeconds, 4);
      expect(s.engine.elapsedTime.inSeconds, 10);
      s.engine.resume();
      expect(
        s.engine.addSample(_point(60, const Duration(seconds: 9))),
        SampleResult.ignored,
      );
      expect(s.fix(11, 60), SampleResult.segmentStart);
      expect(s.fix(14, 69), SampleResult.recorded);
      s.engine.finish();
      s.engine.finish();
      s.engine.resume();
      expect(s.fix(40, 200), SampleResult.ignored);
      expect(s.engine.elapsedTime.inSeconds, 14);
      expect(s.engine.movingTime.inSeconds, 8);
      expect(s.engine.distanceMeters, closeTo(21, 0.001));
    },
  );

  test(
    'Auto-pause needs continuous slow fixes and resumes on sustained motion',
    () {
      final s = _Session()..fix(0, 0);
      s.fix(7, 0); // A GPS gap cannot prove inactivity.
      expect(s.engine.state, TrackingState.active);
      s.fix(11, 0);
      s.fix(15, 0);
      expect(s.engine.state, TrackingState.autoPaused);
      s.fix(16, 2);
      expect(s.engine.state, TrackingState.autoPaused);
      expect(s.fix(17, 4), SampleResult.segmentStart);
      expect(s.engine.state, TrackingState.active);
      expect(s.engine.distanceMeters, 0);
      s.fix(18, 6);
      expect(s.engine.movingTime.inSeconds, 16);
      expect(s.engine.distanceMeters, closeTo(2, 0.001));
    },
  );

  test('Manual pause takes priority over auto-resume', () {
    final s = _Session()
      ..fix(0, 0)
      ..fix(4, 0)
      ..fix(8, 0);
    expect(s.engine.state, TrackingState.autoPaused);
    s.engine.pause();
    s.fix(9, 4);
    s.fix(11, 10);
    expect(s.engine.state, TrackingState.manuallyPaused);
    s.engine.resume();
    expect(s.fix(12, 12), SampleResult.segmentStart);
  });
}
