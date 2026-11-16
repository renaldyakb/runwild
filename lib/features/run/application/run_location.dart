import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/tracking_limits.dart';
import '../../../domain/tracking/tracking_engine.dart';

abstract interface class RunLocation {
  Stream<GpsSample> samples({
    required Duration Function() clock,
    required String notificationTitle,
    required String notificationText,
  });
}

final runLocationProvider = Provider<RunLocation>(
  (ref) => const _DeviceLocation(),
);

class _DeviceLocation implements RunLocation {
  const _DeviceLocation();

  @override
  Stream<GpsSample> samples({
    required Duration Function() clock,
    required String notificationTitle,
    required String notificationText,
  }) async* {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceDisabledException();
    }
    final settings = switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        intervalDuration: TrackingLimits.locationInterval,
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: notificationTitle,
          notificationText: notificationText,
          enableWakeLock: true,
        ),
      ),
      TargetPlatform.iOS => AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      ),
      _ => throw UnsupportedError('GPS recording requires Android or iOS'),
    };
    await for (final position in Geolocator.getPositionStream(
      locationSettings: settings,
    )) {
      final age = DateTime.now().difference(position.timestamp);
      // Convert capture time to the engine clock and discard stale cached fixes.
      if (age.isNegative || age > TrackingLimits.maxLocationAge) continue;
      final capturedAt = clock() - age;
      if (capturedAt.isNegative) continue;
      yield GpsSample(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
        capturedAt: capturedAt,
      );
    }
  }
}
