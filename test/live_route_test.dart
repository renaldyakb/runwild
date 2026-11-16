import 'package:flutter_test/flutter_test.dart';
import 'package:runwild/domain/tracking/live_route.dart';
import 'package:runwild/domain/tracking/tracking_engine.dart';

GpsSample fix(int seconds, {double latitude = 0, double accuracy = 5}) =>
    GpsSample(
      latitude: latitude,
      longitude: 0,
      accuracyMeters: accuracy,
      capturedAt: Duration(seconds: seconds),
    );

void main() {
  test('Current marker rejects poor/stale fixes and teleports, updates while paused', () {
    final route = LiveRoute();
    route.add(fix(0), SampleResult.segmentStart, Duration.zero);
    route.add(
      fix(1, accuracy: 99),
      SampleResult.ignored,
      const Duration(seconds: 1),
    );
    route.add(
      fix(2, latitude: 1),
      SampleResult.ignored,
      const Duration(seconds: 2),
    );
    expect(
      route.snapshot(const Duration(seconds: 2)).position?.capturedAt,
      Duration.zero,
    );
    route.add(
      fix(3, latitude: 0.00001),
      SampleResult.ignored,
      const Duration(seconds: 3),
    );
    expect(
      route.snapshot(const Duration(seconds: 3)).position?.capturedAt,
      const Duration(seconds: 3),
    );
    expect(
      route.snapshot(const Duration(seconds: 3)).segments.single.length,
      1,
    );
    route.add(fix(4), SampleResult.ignored, const Duration(seconds: 20));
    expect(
      route.snapshot(const Duration(seconds: 20)).age,
      const Duration(seconds: 17),
    );
  });

  test(
    'Route retains segment gaps, immutable snapshots and recovered history',
    () {
      final route = LiveRoute();
      route.restore([
        (point: (latitude: 1.0, longitude: 1.0), segmentStart: true),
        (point: (latitude: 1.001, longitude: 1.001), segmentStart: false),
      ]);
      final before = route.snapshot(Duration.zero);
      expect(before.position, isNull);
      route.add(fix(1), SampleResult.segmentStart, const Duration(seconds: 1));
      route.add(
        fix(2, latitude: 0.00005),
        SampleResult.recorded,
        const Duration(seconds: 2),
      );
      expect(
        route
            .snapshot(const Duration(seconds: 2))
            .segments
            .map((s) => s.length),
        [2, 2],
      );
      expect(before.segments.length, 1);
      expect(() => before.segments.clear(), throwsUnsupportedError);
    },
  );
}
