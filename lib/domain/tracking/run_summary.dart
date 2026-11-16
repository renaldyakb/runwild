enum RunFeeling { easy, normal, hard }

typedef KmSplit = ({
  int kilometer,
  double distanceMeters,
  Duration duration,
  double paceSecondsPerKm,
});

typedef IntervalSummary = ({
  int completedRounds,
  int? totalRounds,
  Duration runTime,
  Duration walkTime,
});

class RunSummary {
  const RunSummary({
    required this.startedAt,
    required this.distanceMeters,
    required this.movingTime,
    required this.elapsedTime,
    required this.averagePace,
    required this.splits,
    this.sessionId,
    this.interval,
    this.feeling,
    this.note,
  });

  final int? sessionId;
  final DateTime startedAt;
  final double distanceMeters;
  final Duration movingTime;
  final Duration elapsedTime;
  final double? averagePace;
  final List<KmSplit> splits;
  final IntervalSummary? interval;
  final RunFeeling? feeling;
  final String? note;

  /// Estimasi kalori menggunakan formula MET standar running:
  /// Kalori ≈ jarak (km) × berat rata-rata 65 kg × faktor 1.036
  int get estimatedCalories {
    final distanceKm = distanceMeters / 1000.0;
    if (distanceKm <= 0) return 0;
    return (distanceKm * 65.0 * 1.036).round();
  }

  RunSummary copyWith({RunFeeling? feeling, String? note}) => RunSummary(
    sessionId: sessionId,
    startedAt: startedAt,
    distanceMeters: distanceMeters,
    movingTime: movingTime,
    elapsedTime: elapsedTime,
    averagePace: averagePace,
    splits: splits,
    interval: interval,
    feeling: feeling ?? this.feeling,
    note: note ?? this.note,
  );
}
