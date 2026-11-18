import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:runwild/domain/tracking/gps_calibration.dart';

GpsCalibrationSample _sample({
  required int second,
  required double accuracy,
  double latitude = -6.2,
  double longitude = 106.8,
}) => (
  latitude: latitude,
  longitude: longitude,
  accuracyMeters: accuracy,
  capturedAt: Duration(seconds: second),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('evaluateGpsCalibration', () {
    test('grades a steady 12 second measurement as good', () {
      final samples = [
        for (var i = 0; i < 13; i++) _sample(second: i, accuracy: 5 + (i % 2)),
      ];
      final report = evaluateGpsCalibration(samples);
      expect(report.hasEnoughData, isTrue);
      expect(report.grade, GpsCalibrationGrade.good);
      expect(report.sampleCount, 13);
      expect(report.span, const Duration(seconds: 12));
      expect(report.medianAccuracyMeters, closeTo(5.0, 0.01));
    });

    test('grades a loose but usable measurement as fair', () {
      final samples = [
        for (var i = 0; i < 13; i++) _sample(second: i, accuracy: 13),
      ];
      final report = evaluateGpsCalibration(samples);
      expect(report.grade, GpsCalibrationGrade.fair);
    });

    test('grades poor accuracy or movement as poor', () {
      final inaccurate = [
        for (var i = 0; i < 13; i++) _sample(second: i, accuracy: 30),
      ];
      expect(
        evaluateGpsCalibration(inaccurate).grade,
        GpsCalibrationGrade.poor,
      );

      final moving = [
        for (var i = 0; i < 13; i++)
          _sample(second: i, accuracy: 6, latitude: -6.2 + i * 0.0004),
      ];
      final report = evaluateGpsCalibration(moving);
      expect(report.maxDriftMeters, greaterThan(20));
      expect(report.grade, GpsCalibrationGrade.poor);
    });

    test('does not grade before enough samples and time', () {
      final samples = [
        for (var i = 0; i < 5; i++) _sample(second: i, accuracy: 5),
      ];
      final report = evaluateGpsCalibration(samples);
      expect(report.hasEnoughData, isFalse);
      expect(report.grade, isNull);
    });

    test('handles an empty list without inventing values', () {
      final report = evaluateGpsCalibration(const []);
      expect(report.hasEnoughData, isFalse);
      expect(report.sampleCount, 0);
      expect(report.grade, isNull);
    });
  });

  group('isGpsCalibrationDue', () {
    final now = DateTime(2026, 11, 18, 8);

    test('is due when never calibrated', () {
      expect(
        isGpsCalibrationDue(calibratedAt: null, grade: null, now: now),
        isTrue,
      );
    });

    test('waits 30 days after a good calibration', () {
      expect(
        isGpsCalibrationDue(
          calibratedAt: now.subtract(const Duration(days: 10)),
          grade: GpsCalibrationGrade.good,
          now: now,
        ),
        isFalse,
      );
      expect(
        isGpsCalibrationDue(
          calibratedAt: now.subtract(const Duration(days: 31)),
          grade: GpsCalibrationGrade.good,
          now: now,
        ),
        isTrue,
      );
    });

    test('asks again the next day after a poor calibration', () {
      expect(
        isGpsCalibrationDue(
          calibratedAt: now.subtract(const Duration(hours: 2)),
          grade: GpsCalibrationGrade.poor,
          now: now,
        ),
        isFalse,
      );
      expect(
        isGpsCalibrationDue(
          calibratedAt: now.subtract(const Duration(hours: 25)),
          grade: GpsCalibrationGrade.poor,
          now: now,
        ),
        isTrue,
      );
    });

    test('does not nag when the clock moved backwards', () {
      expect(
        isGpsCalibrationDue(
          calibratedAt: now.add(const Duration(days: 1)),
          grade: GpsCalibrationGrade.good,
          now: now,
        ),
        isFalse,
      );
    });
  });

  testWidgets('bundled calibration animation is a valid Lottie file', (
    tester,
  ) async {
    final data = await rootBundle.load('assets/lottie/gps_calibration.json');
    final composition = await LottieComposition.fromBytes(
      data.buffer.asUint8List(),
    );
    expect(composition, isNotNull);
    expect(composition.duration, greaterThan(Duration.zero));
  });
}
