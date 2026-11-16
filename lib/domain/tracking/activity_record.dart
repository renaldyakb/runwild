// Domain model for run activity cloud record (Pure Dart, no Flutter/Firebase).

/// Standard Flexible/Google Encoded Polyline algorithm (precision 1e5 = ~1m).
String encodePolyline(Iterable<({double latitude, double longitude})> points) {
  if (points.isEmpty) return '';
  final buffer = StringBuffer();
  int lastLat = 0;
  int lastLng = 0;

  for (final point in points) {
    final lat = (point.latitude * 1e5).round();
    final lng = (point.longitude * 1e5).round();

    _encodeValue(lat - lastLat, buffer);
    _encodeValue(lng - lastLng, buffer);

    lastLat = lat;
    lastLng = lng;
  }
  return buffer.toString();
}

void _encodeValue(int value, StringBuffer buffer) {
  int v = value < 0 ? ~(value << 1) : (value << 1);
  while (v >= 0x20) {
    buffer.writeCharCode((0x20 | (v & 0x1f)) + 63);
    v >>= 5;
  }
  buffer.writeCharCode(v + 63);
}

/// Sederhanakan polyline bila jumlah titik terlalu banyak (> 500 titik)
/// menggunakan downsampling jarak seragam untuk menghemat ukuran Firestore (<= 1MB).
List<({double latitude, double longitude})> simplifyPoints(
  List<({double latitude, double longitude})> points, {
  int maxPoints = 500,
}) {
  if (points.length <= maxPoints) return points;
  final step = points.length / maxPoints;
  final result = <({double latitude, double longitude})>[];
  for (var i = 0.0; i < points.length; i += step) {
    result.add(points[i.toInt()]);
  }
  if (result.last != points.last) {
    result.add(points.last);
  }
  return result;
}

/// Tipe aktivitas lari
enum ActivityType { run, walk, runWalk }

/// Mode sesi lari
enum ActivityMode { free, interval, program }

/// Representasi domain aktivitas lari
class ActivityRecord {
  const ActivityRecord({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.mode,
    required this.title,
    required this.startedAt,
    required this.endedAt,
    required this.movingTime,
    required this.elapsedTime,
    required this.distanceMeters,
    required this.averageSpeedMps,
    required this.averagePaceSecPerKm,
    required this.estimatedCalories,
    required this.trackPointCount,
    required this.polyline,
    this.note,
    this.feeling,
    this.intervalSummary,
    this.splits = const [],
    this.platform = 'android',
    this.appVersion = '0.1.0',
  });

  final String id;
  final String ownerId;
  final ActivityType type;
  final ActivityMode mode;
  final String title;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration movingTime;
  final Duration elapsedTime;
  final double distanceMeters;
  final double averageSpeedMps;
  final int? averagePaceSecPerKm;
  final int estimatedCalories;
  final int trackPointCount;
  final String polyline;
  final String? note;
  final String? feeling;
  final Map<String, dynamic>? intervalSummary;
  final List<Map<String, dynamic>> splits;
  final String platform;
  final String appVersion;

  /// Konversi ke Map data Firestore
  Map<String, dynamic> toFirestoreMap({
    required Object Function(DateTime) timestampConverter,
  }) {
    return {
      'id': id,
      'type': type.name,
      'mode': mode.name,
      'title': title,
      if (note != null && note!.isNotEmpty) 'note': note,
      if (feeling != null) 'feeling': feeling,
      'startedAt': timestampConverter(startedAt),
      'endedAt': timestampConverter(endedAt),
      'movingTimeSec': movingTime.inSeconds,
      'elapsedTimeSec': elapsedTime.inSeconds,
      'distanceM': distanceMeters,
      'avgSpeedMps': averageSpeedMps,
      'avgPaceSecPerKm': averagePaceSecPerKm,
      'caloriesEst': estimatedCalories,
      'trackPointCount': trackPointCount,
      'polyline': polyline,
      if (intervalSummary != null) 'interval': intervalSummary,
      'splits': splits,
      'visibility': 'private',
      'source': 'gps',
      'deviceInfo': {'platform': platform, 'appVersion': appVersion},
      'createdAt': timestampConverter(DateTime.now().toUtc()),
      'updatedAt': timestampConverter(DateTime.now().toUtc()),
    };
  }

  /// Menghasilkan judul default berdasarkan jam mulai lokal
  static String defaultTitle(DateTime startedAt) {
    final hour = startedAt.toLocal().hour;
    if (hour >= 4 && hour < 11) return 'Lari Pagi';
    if (hour >= 11 && hour < 15) return 'Lari Siang';
    if (hour >= 15 && hour < 19) return 'Lari Sore';
    return 'Lari Malam';
  }
}
