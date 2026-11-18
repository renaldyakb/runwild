import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/calibration_limits.dart';
import '../../../domain/tracking/gps_calibration.dart';

typedef GpsCalibrationRecord = ({
  DateTime calibratedAt,
  GpsCalibrationGrade grade,
  double medianAccuracyMeters,
});

typedef GpsCalibrationStatus = ({
  bool isDue,
  DateTime? calibratedAt,
  GpsCalibrationGrade? grade,
});

abstract interface class GpsCalibrationStore {
  Future<GpsCalibrationRecord?> read();
  Future<void> save(GpsCalibrationRecord record);
}

final gpsCalibrationStoreProvider = Provider<GpsCalibrationStore>(
  (ref) => LocalGpsCalibrationStore(SharedPreferencesAsync()),
);

class LocalGpsCalibrationStore implements GpsCalibrationStore {
  LocalGpsCalibrationStore(this._preferences);

  static const _timeKey = 'runwild.gps_calibration_at';
  static const _gradeKey = 'runwild.gps_calibration_grade';
  static const _accuracyKey = 'runwild.gps_calibration_accuracy';

  final SharedPreferencesAsync _preferences;

  @override
  Future<GpsCalibrationRecord?> read() async {
    final time = await _preferences.getInt(_timeKey);
    final gradeName = await _preferences.getString(_gradeKey);
    final accuracy = await _preferences.getDouble(_accuracyKey);
    if (time == null || gradeName == null || accuracy == null) return null;
    final grade = GpsCalibrationGrade.values.asNameMap()[gradeName];
    if (grade == null) return null;
    return (
      calibratedAt: DateTime.fromMillisecondsSinceEpoch(time),
      grade: grade,
      medianAccuracyMeters: accuracy,
    );
  }

  @override
  Future<void> save(GpsCalibrationRecord record) async {
    await _preferences.setInt(
      _timeKey,
      record.calibratedAt.millisecondsSinceEpoch,
    );
    await _preferences.setString(_gradeKey, record.grade.name);
    await _preferences.setDouble(_accuracyKey, record.medianAccuracyMeters);
  }
}

final gpsCalibrationStatusProvider =
    FutureProvider.autoDispose<GpsCalibrationStatus>((ref) async {
      final store = ref.watch(gpsCalibrationStoreProvider);
      final record = await store.read();
      return (
        isDue: isGpsCalibrationDue(
          calibratedAt: record?.calibratedAt,
          grade: record?.grade,
          now: DateTime.now(),
        ),
        calibratedAt: record?.calibratedAt,
        grade: record?.grade,
      );
    });

abstract interface class GpsCalibrationSource {
  Stream<GpsCalibrationSample> samples();
}

final gpsCalibrationSourceProvider = Provider<GpsCalibrationSource>(
  (ref) => const DeviceGpsCalibrationSource(),
);

class DeviceGpsCalibrationSource implements GpsCalibrationSource {
  const DeviceGpsCalibrationSource();

  @override
  Stream<GpsCalibrationSample> samples() async* {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceDisabledException();
    }
    final watch = Stopwatch()..start();
    final settings = switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: CalibrationLimits.sampleInterval,
      ),
      TargetPlatform.iOS => AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.otherNavigation,
        pauseLocationUpdatesAutomatically: false,
      ),
      _ => const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    };
    await for (final position in Geolocator.getPositionStream(
      locationSettings: settings,
    )) {
      yield (
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        capturedAt: watch.elapsed,
      );
    }
  }
}

enum GpsCalibrationPhase { idle, sampling, done, failed }

typedef GpsCalibrationView = ({
  GpsCalibrationPhase phase,
  List<GpsCalibrationSample> samples,
  GpsCalibrationReport? report,
  bool serviceDisabled,
  bool saveFailed,
});

final gpsCalibrationControllerProvider =
    NotifierProvider.autoDispose<GpsCalibrationController, GpsCalibrationView>(
      GpsCalibrationController.new,
    );

class GpsCalibrationController extends Notifier<GpsCalibrationView> {
  StreamSubscription<GpsCalibrationSample>? _subscription;

  @override
  GpsCalibrationView build() {
    ref.onDispose(() => unawaited(_subscription?.cancel()));
    return (
      phase: GpsCalibrationPhase.idle,
      samples: const [],
      report: null,
      serviceDisabled: false,
      saveFailed: false,
    );
  }

  void start() => unawaited(_start());

  Future<void> _start() async {
    await _subscription?.cancel();
    _subscription = null;
    state = (
      phase: GpsCalibrationPhase.sampling,
      samples: const [],
      report: null,
      serviceDisabled: false,
      saveFailed: false,
    );

    final samples = <GpsCalibrationSample>[];
    _subscription = ref
        .read(gpsCalibrationSourceProvider)
        .samples()
        .listen(
          (sample) {
            samples.add(sample);
            final span = sample.capturedAt - samples.first.capturedAt;
            if (samples.length >= CalibrationLimits.targetSamples ||
                span >= CalibrationLimits.maximumDuration) {
              unawaited(_complete(samples));
              return;
            }
            state = (
              phase: GpsCalibrationPhase.sampling,
              samples: List.unmodifiable(samples),
              report: evaluateGpsCalibration(samples),
              serviceDisabled: false,
              saveFailed: false,
            );
          },
          onError: (Object error, StackTrace stackTrace) {
            unawaited(_subscription?.cancel());
            _subscription = null;
            final disabled = error is LocationServiceDisabledException;
            debugPrint('GPS calibration stopped: ${error.runtimeType}');
            state = (
              phase: GpsCalibrationPhase.failed,
              samples: List.unmodifiable(samples),
              report: null,
              serviceDisabled: disabled,
              saveFailed: false,
            );
          },
          cancelOnError: true,
        );
  }

  void cancel() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    state = (
      phase: GpsCalibrationPhase.idle,
      samples: const [],
      report: null,
      serviceDisabled: false,
      saveFailed: false,
    );
  }

  Future<void> _complete(List<GpsCalibrationSample> samples) async {
    // Jangan menunggu cancel dari dalam handler stream: future cancel baru
    // selesai setelah handler ini kembali (deadlock).
    final subscription = _subscription;
    _subscription = null;
    unawaited(subscription?.cancel());
    final report = evaluateGpsCalibration(samples);
    var saveFailed = false;
    final grade = report.grade;
    if (grade != null) {
      try {
        await ref.read(gpsCalibrationStoreProvider).save((
          calibratedAt: DateTime.now(),
          grade: grade,
          medianAccuracyMeters: report.medianAccuracyMeters,
        ));
        ref.invalidate(gpsCalibrationStatusProvider);
      } on Exception catch (error) {
        debugPrint('GPS calibration save failed: ${error.runtimeType}');
        saveFailed = true;
      }
    }
    state = (
      phase: GpsCalibrationPhase.done,
      samples: List.unmodifiable(samples),
      report: report,
      serviceDisabled: false,
      saveFailed: saveFailed,
    );
  }
}
