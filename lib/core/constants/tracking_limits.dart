abstract final class TrackingLimits {
  static const maxAccuracyMeters = 30.0;
  static const maxSpeedMetersPerSecond = 12.0;
  static const jitterMeters = 3.0;
  static const slowSpeedMetersPerSecond = 0.5;
  static const resumeSpeedMetersPerSecond = 1.0;
  static const autoPauseDelay = Duration(seconds: 8);
  static const autoResumeDelay = Duration(seconds: 2);
  static const maxMotionSampleGap = Duration(seconds: 5);
  static const locationInterval = Duration(seconds: 1);
  static const maxLocationAge = Duration(seconds: 5);
  static const paceWindow = Duration(seconds: 15);
  static const minPaceWindowMeters = 20.0;
  static const earthRadiusMeters = 6371008.8;
  static const metersPerKilometer = 1000.0;
}
