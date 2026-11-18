// Pure Dart evaluation for GPS calibration before a session.

import '../../core/constants/calibration_limits.dart';
import 'tracking_engine.dart';

enum GpsCalibrationGrade { good, fair, poor }

typedef GpsCalibrationSample = ({
  double latitude,
  double longitude,
  double accuracyMeters,
  Duration capturedAt,
});

typedef GpsCalibrationReport = ({
  bool hasEnoughData,
  GpsCalibrationGrade? grade,
  double medianAccuracyMeters,
  double maxDriftMeters,
  int sampleCount,
  Duration span,
});

/// Menilai sampel GPS yang diambil saat pengguna berdiri diam.
///
/// Akurasi memakai median (tahan terhadap satu titik buruk); drift memakai
/// jarak terjauh dari sampel pertama sehingga gerakan kecil ikut terukur.
GpsCalibrationReport evaluateGpsCalibration(
  List<GpsCalibrationSample> samples,
) {
  if (samples.isEmpty) {
    return (
      hasEnoughData: false,
      grade: null,
      medianAccuracyMeters: 0,
      maxDriftMeters: 0,
      sampleCount: 0,
      span: Duration.zero,
    );
  }

  final accuracies = [for (final sample in samples) sample.accuracyMeters]
    ..sort();
  final middle = accuracies.length ~/ 2;
  final median = accuracies.length.isOdd
      ? accuracies[middle]
      : (accuracies[middle - 1] + accuracies[middle]) / 2;

  final anchor = samples.first;
  final anchorSample = GpsSample(
    latitude: anchor.latitude,
    longitude: anchor.longitude,
    accuracyMeters: anchor.accuracyMeters,
    capturedAt: anchor.capturedAt,
  );
  var drift = 0.0;
  for (final sample in samples.skip(1)) {
    final meters = haversineMeters(
      anchorSample,
      GpsSample(
        latitude: sample.latitude,
        longitude: sample.longitude,
        accuracyMeters: sample.accuracyMeters,
        capturedAt: sample.capturedAt,
      ),
    );
    if (meters > drift) drift = meters;
  }

  final span = samples.last.capturedAt - samples.first.capturedAt;
  final enough =
      samples.length >= CalibrationLimits.minimumSamples &&
      span >= CalibrationLimits.minimumDuration;

  GpsCalibrationGrade? grade;
  if (enough) {
    if (median <= CalibrationLimits.goodMedianAccuracyMeters &&
        drift <= CalibrationLimits.goodDriftMeters) {
      grade = GpsCalibrationGrade.good;
    } else if (median <= CalibrationLimits.fairMedianAccuracyMeters &&
        drift <= CalibrationLimits.fairDriftMeters) {
      grade = GpsCalibrationGrade.fair;
    } else {
      grade = GpsCalibrationGrade.poor;
    }
  }

  return (
    hasEnoughData: enough,
    grade: grade,
    medianAccuracyMeters: median,
    maxDriftMeters: drift,
    sampleCount: samples.length,
    span: span,
  );
}

/// Kalibrasi hanya diminta ulang bila belum pernah, hasil terakhir buruk,
/// atau sudah lewat masa berlaku.
bool isGpsCalibrationDue({
  required DateTime? calibratedAt,
  required GpsCalibrationGrade? grade,
  required DateTime now,
}) {
  if (calibratedAt == null || grade == null) return true;
  final age = now.difference(calibratedAt);
  if (age.isNegative) return false;
  final interval = grade == GpsCalibrationGrade.poor
      ? CalibrationLimits.poorRecalibrationInterval
      : CalibrationLimits.recalibrationInterval;
  return age >= interval;
}
