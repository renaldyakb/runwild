// Pure Dart statistics engine for Home dashboard and Progress (T4.4 & T4.5).

import '../interval/interval_config.dart';

typedef SessionItem = ({DateTime startedAt, double meters, Duration moving});

typedef DailyBar = ({
  int dayOfWeek, // 1 = Monday .. 7 = Sunday
  String dayLabel, // 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'
  double distanceKm,
  bool isToday,
});

typedef WeekSummary = ({
  DateTime weekStart,
  DateTime weekEnd,
  double totalDistanceMeters,
  Duration totalMovingTime,
  int totalCalories,
  int sessionCount,
  int targetSessions,
  int streakWeeks,
  List<DailyBar> dailyBars,
});

typedef PersonalRecord = ({
  String title,
  String value,
  String unit,
  DateTime achievedAt,
});

typedef PersonalRecords = ({
  PersonalRecord? longestDistance,
  PersonalRecord? longestDuration,
  PersonalRecord? bestPace1k,
  PersonalRecord? bestPace5k,
});

enum ProgressPeriod { week, month, allTime }

typedef ChartBarData = ({String label, double valueKm, bool isHighlight});

typedef PeriodStats = ({
  double totalDistanceMeters,
  Duration totalMovingTime,
  int sessionCount,
  int totalCalories,
  double? averagePaceSecondsPerKm,
  List<ChartBarData> chartBars,
});

typedef RecommendedSession = ({
  String title,
  String description,
  IntervalPreset? preset,
  bool isFree,
});

abstract final class StatsEngine {
  static const dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  /// Mengembalikan awal minggu (Senin 00:00:00) dari tanggal yang diberikan.
  static DateTime startOfWeek(DateTime date) {
    final local = date.toLocal();
    final monday = local.subtract(Duration(days: local.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  /// Mengembalikan akhir minggu (Minggu 23:59:59) dari tanggal yang diberikan.
  static DateTime endOfWeek(DateTime date) {
    final start = startOfWeek(date);
    return DateTime(start.year, start.month, start.day + 6, 23, 59, 59, 999);
  }

  /// Menghitung ringkasan performa 7 hari minggu berjalan dan streak mingguan.
  static WeekSummary calculateWeekSummary({
    required List<({DateTime startedAt, double meters, Duration moving})>
    sessions,
    required DateTime now,
    int targetSessions = 3,
  }) {
    final weekStart = startOfWeek(now);
    final weekEnd = endOfWeek(now);
    final todayWeekday = now.toLocal().weekday; // 1 = Sen .. 7 = Min

    final dailyDistances = List<double>.filled(7, 0.0);
    var weekMeters = 0.0;
    var weekMoving = Duration.zero;
    var weekCount = 0;

    for (final s in sessions) {
      final dt = s.startedAt.toLocal();
      if (!dt.isBefore(weekStart) && !dt.isAfter(weekEnd)) {
        final dayIdx = dt.weekday - 1;
        dailyDistances[dayIdx] += s.meters / 1000.0;
        weekMeters += s.meters;
        weekMoving += s.moving;
        weekCount++;
      }
    }

    final dailyBars = <DailyBar>[
      for (var i = 0; i < 7; i++)
        (
          dayOfWeek: i + 1,
          dayLabel: dayLabels[i],
          distanceKm: dailyDistances[i],
          isToday: (i + 1) == todayWeekday,
        ),
    ];

    final weekCalories = weekMeters > 0
        ? (weekMeters / 1000.0 * 65.0 * 1.036).round()
        : 0;

    // Hitung streak mingguan ke belakang
    final streak = calculateWeeklyStreak(
      sessions: sessions,
      now: now,
      targetSessions: targetSessions,
    );

    return (
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalDistanceMeters: weekMeters,
      totalMovingTime: weekMoving,
      totalCalories: weekCalories,
      sessionCount: weekCount,
      targetSessions: targetSessions,
      streakWeeks: streak,
      dailyBars: dailyBars,
    );
  }

  /// Menghitung streak mingguan (jumlah minggu berturut-turut mencapai target).
  static int calculateWeeklyStreak({
    required List<({DateTime startedAt, double meters, Duration moving})>
    sessions,
    required DateTime now,
    required int targetSessions,
  }) {
    if (sessions.isEmpty || targetSessions <= 0) return 0;

    final currentWeekStart = startOfWeek(now);
    var weekCount = 0;
    var streak = 0;

    // Sesi minggu berjalan
    for (final s in sessions) {
      final dt = s.startedAt.toLocal();
      if (!dt.isBefore(currentWeekStart) && !dt.isAfter(endOfWeek(now))) {
        weekCount++;
      }
    }

    // Jika minggu ini sudah capai target, streak bertambah 1
    var checkDate = currentWeekStart;
    if (weekCount >= targetSessions) {
      streak++;
      checkDate = currentWeekStart.subtract(const Duration(days: 7));
    } else {
      // Jika belum capai target di minggu ini, mulai hitung dari minggu lalu
      checkDate = currentWeekStart.subtract(const Duration(days: 7));
    }

    // Telusuri minggu-minggu sebelumnya
    while (true) {
      final wStart = startOfWeek(checkDate);
      final wEnd = endOfWeek(checkDate);

      var countInWeek = 0;
      for (final s in sessions) {
        final dt = s.startedAt.toLocal();
        if (!dt.isBefore(wStart) && !dt.isAfter(wEnd)) {
          countInWeek++;
        }
      }

      if (countInWeek >= targetSessions) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 7));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Menghitung statistik berdasarkan filter periode (Minggu Ini, Bulan Ini, Semua).
  static PeriodStats calculatePeriodStats({
    required List<({DateTime startedAt, double meters, Duration moving})>
    sessions,
    required ProgressPeriod period,
    required DateTime now,
  }) {
    final localNow = now.toLocal();
    final filtered = <({DateTime startedAt, double meters, Duration moving})>[];

    switch (period) {
      case ProgressPeriod.week:
        final wStart = startOfWeek(localNow);
        final wEnd = endOfWeek(localNow);
        for (final s in sessions) {
          final dt = s.startedAt.toLocal();
          if (!dt.isBefore(wStart) && !dt.isAfter(wEnd)) {
            filtered.add(s);
          }
        }
      case ProgressPeriod.month:
        final mStart = DateTime(localNow.year, localNow.month, 1);
        final mEnd = DateTime(localNow.year, localNow.month + 1, 0, 23, 59, 59);
        for (final s in sessions) {
          final dt = s.startedAt.toLocal();
          if (!dt.isBefore(mStart) && !dt.isAfter(mEnd)) {
            filtered.add(s);
          }
        }
      case ProgressPeriod.allTime:
        filtered.addAll(sessions);
    }

    var totalMeters = 0.0;
    var totalMoving = Duration.zero;
    for (final s in filtered) {
      totalMeters += s.meters;
      totalMoving += s.moving;
    }

    final totalCal = totalMeters > 0
        ? (totalMeters / 1000.0 * 65.0 * 1.036).round()
        : 0;
    final avgPace = totalMeters > 0 && totalMoving > Duration.zero
        ? totalMoving.inSeconds / (totalMeters / 1000.0)
        : null;

    // Grafik batang sesuai periode
    final chartBars = <ChartBarData>[];

    if (period == ProgressPeriod.week) {
      final dailyMap = List<double>.filled(7, 0.0);
      for (final s in filtered) {
        final dayIdx = s.startedAt.toLocal().weekday - 1;
        dailyMap[dayIdx] += s.meters / 1000.0;
      }
      for (var i = 0; i < 7; i++) {
        chartBars.add((
          label: dayLabels[i],
          valueKm: dailyMap[i],
          isHighlight: (i + 1) == localNow.weekday,
        ));
      }
    } else if (period == ProgressPeriod.month) {
      // Kelompokkan 4 minggu di bulan ini (W1..W4)
      final weekTotals = List<double>.filled(4, 0.0);
      for (final s in filtered) {
        final day = s.startedAt.toLocal().day;
        final weekIdx = ((day - 1) ~/ 7).clamp(0, 3);
        weekTotals[weekIdx] += s.meters / 1000.0;
      }
      for (var i = 0; i < 4; i++) {
        chartBars.add((
          label: 'M${i + 1}',
          valueKm: weekTotals[i],
          isHighlight: false,
        ));
      }
    } else {
      // 6 bulan terakhir untuk all-time
      final monthTotals = <int, double>{};
      for (var m = 5; m >= 0; m--) {
        final dt = DateTime(localNow.year, localNow.month - m, 1);
        final key = dt.year * 100 + dt.month;
        monthTotals[key] = 0.0;
      }
      for (final s in sessions) {
        final dt = s.startedAt.toLocal();
        final key = dt.year * 100 + dt.month;
        if (monthTotals.containsKey(key)) {
          monthTotals[key] = (monthTotals[key] ?? 0.0) + (s.meters / 1000.0);
        }
      }
      final monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      for (final entry in monthTotals.entries) {
        final monthNum = entry.key % 100;
        chartBars.add((
          label: monthNames[monthNum - 1],
          valueKm: entry.value,
          isHighlight: entry.key == (localNow.year * 100 + localNow.month),
        ));
      }
    }

    return (
      totalDistanceMeters: totalMeters,
      totalMovingTime: totalMoving,
      sessionCount: filtered.length,
      totalCalories: totalCal,
      averagePaceSecondsPerKm: avgPace,
      chartBars: chartBars,
    );
  }

  /// Menghitung Rekor Pribadi (Personal Best) dari seluruh riwayat sesi.
  static PersonalRecords calculatePersonalRecords(
    List<({DateTime startedAt, double meters, Duration moving})> sessions,
  ) {
    if (sessions.isEmpty) {
      return (
        longestDistance: null,
        longestDuration: null,
        bestPace1k: null,
        bestPace5k: null,
      );
    }

    ({DateTime startedAt, double meters, Duration moving})? maxDist;
    ({DateTime startedAt, double meters, Duration moving})? maxDur;
    ({DateTime startedAt, double meters, Duration moving})? best1k;
    double? minPace1k;
    ({DateTime startedAt, double meters, Duration moving})? best5k;
    double? minPace5k;

    for (final s in sessions) {
      // Jarak Terjauh
      if (maxDist == null || s.meters > maxDist.meters) {
        maxDist = s;
      }

      // Durasi Terlama
      if (maxDur == null || s.moving > maxDur.moving) {
        maxDur = s;
      }

      // Pace 1 KM Terbaik (minimal 1000 m)
      if (s.meters >= 1000.0 && s.moving > Duration.zero) {
        final pace = s.moving.inSeconds / (s.meters / 1000.0);
        if (minPace1k == null || pace < minPace1k) {
          minPace1k = pace;
          best1k = s;
        }
      }

      // Pace 5 KM Terbaik (minimal 5000 m)
      if (s.meters >= 5000.0 && s.moving > Duration.zero) {
        final pace = s.moving.inSeconds / (s.meters / 1000.0);
        if (minPace5k == null || pace < minPace5k) {
          minPace5k = pace;
          best5k = s;
        }
      }
    }

    PersonalRecord? longestDistanceRecord;
    if (maxDist != null && maxDist.meters > 0) {
      longestDistanceRecord = (
        title: 'Jarak Terjauh',
        value: (maxDist.meters / 1000.0).toStringAsFixed(2),
        unit: 'km',
        achievedAt: maxDist.startedAt,
      );
    }

    PersonalRecord? longestDurationRecord;
    if (maxDur != null && maxDur.moving > Duration.zero) {
      final m = maxDur.moving.inMinutes;
      final s = maxDur.moving.inSeconds % 60;
      longestDurationRecord = (
        title: 'Durasi Terlama',
        value: '$m:${s.toString().padLeft(2, '0')}',
        unit: 'waktu',
        achievedAt: maxDur.startedAt,
      );
    }

    PersonalRecord? best1kRecord;
    if (best1k != null && minPace1k != null) {
      final m = minPace1k.round() ~/ 60;
      final s = minPace1k.round() % 60;
      best1kRecord = (
        title: 'Pace Rata-rata Terbaik (≥1 km)',
        value: '$m\'${s.toString().padLeft(2, '0')}"',
        unit: '/km',
        achievedAt: best1k.startedAt,
      );
    }

    PersonalRecord? best5kRecord;
    if (best5k != null && minPace5k != null) {
      final m = minPace5k.round() ~/ 60;
      final s = minPace5k.round() % 60;
      best5kRecord = (
        title: 'Pace Rata-rata Terbaik (≥5 km)',
        value: '$m\'${s.toString().padLeft(2, '0')}"',
        unit: '/km',
        achievedAt: best5k.startedAt,
      );
    }

    return (
      longestDistance: longestDistanceRecord,
      longestDuration: longestDurationRecord,
      bestPace1k: best1kRecord,
      bestPace5k: best5kRecord,
    );
  }

  /// Membandingkan momen memakai resolusi penyimpanan (milidetik), karena
  /// SQLite menyimpan `started_ms` dan membuang mikrodetik dari `DateTime`.
  static bool _sameInstant(DateTime a, DateTime b) =>
      a.millisecondsSinceEpoch == b.millisecondsSinceEpoch;

  /// Memeriksa apakah sesi dengan [startedAt] memecahkan atau memegang
  /// salah satu rekor pribadi (Personal Best).
  static List<String> detectPersonalBestsForSession({
    required DateTime startedAt,
    required PersonalRecords records,
  }) {
    final pbs = <String>[];
    if (records.longestDistance != null &&
        _sameInstant(records.longestDistance!.achievedAt, startedAt)) {
      pbs.add('Jarak Terjauh');
    }
    if (records.longestDuration != null &&
        _sameInstant(records.longestDuration!.achievedAt, startedAt)) {
      pbs.add('Durasi Terlama');
    }
    if (records.bestPace1k != null &&
        _sameInstant(records.bestPace1k!.achievedAt, startedAt)) {
      pbs.add('Pace 1K Rata-rata');
    }
    if (records.bestPace5k != null &&
        _sameInstant(records.bestPace5k!.achievedAt, startedAt)) {
      pbs.add('Pace 5K Rata-rata');
    }
    return pbs;
  }

  /// Rekomendasi sesi berikutnya berdasarkan riwayat sesi.
  static RecommendedSession getRecommendedSession({
    required int totalCompletedSessions,
  }) {
    if (totalCompletedSessions == 0) {
      return (
        title: 'Coba Pemula Santai',
        description: '20 menit: Jalan 2 menit / Lari 1 menit x 8 ronde. Sangat ramah untuk pemula.',
        preset: IntervalPreset.beginner,
        isFree: false,
      );
    } else if (totalCompletedSessions % 2 == 1) {
      return (
        title: 'Lanjutkan Ritme: Interval 1:1',
        description: '20 menit: Jalan 1 menit / Lari 1 menit x 10 ronde untuk membangun stamina stabil.',
        preset: IntervalPreset.classic,
        isFree: false,
      );
    } else {
      return (
        title: 'Jalan / Lari Bebas',
        description: 'Berlari santai tanpa tekanan target waktu. Nikmati udara dan langkah kakimu.',
        preset: null,
        isFree: true,
      );
    }
  }
}
