/// Ambang kalibrasi GPS. Nilai dipakai domain murni dan UI agar tidak ada
/// angka ajaib di layar maupun di tes.
abstract final class CalibrationLimits {
  /// Minimal sampel dan rentang waktu sebelum hasil dianggap sah.
  static const int minimumSamples = 8;
  static const int targetSamples = 13;
  static const Duration minimumDuration = Duration(seconds: 12);

  /// Batas pengukuran; setelah ini kalibrasi berhenti sendiri.
  static const Duration maximumDuration = Duration(seconds: 20);
  static const Duration sampleInterval = Duration(seconds: 1);

  /// Nilai "baik": akurasi median dan pergeseran posisi diam.
  static const double goodMedianAccuracyMeters = 8;
  static const double goodDriftMeters = 12;

  /// Nilai "cukup" sebelum dinyatakan buruk.
  static const double fairMedianAccuracyMeters = 15;
  static const double fairDriftMeters = 20;

  /// Kalibrasi tidak perlu setiap sesi.
  static const Duration recalibrationInterval = Duration(days: 30);
  static const Duration poorRecalibrationInterval = Duration(days: 1);
}
