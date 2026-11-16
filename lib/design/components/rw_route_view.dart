import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../tokens/rw_tokens.dart';

/// Model titik koordinat GPS
typedef LatLngPoint = ({double latitude, double longitude});

/// Decode polyline standar (presisi 1e5)
List<LatLngPoint> decodePolylinePoints(String encoded) {
  if (encoded.isEmpty) return const [];
  final points = <LatLngPoint>[];
  var index = 0;
  var lat = 0;
  var lng = 0;

  while (index < encoded.length) {
    var b = 0;
    var shift = 0;
    var result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += dlng;

    points.add((latitude: lat / 1e5, longitude: lng / 1e5));
  }
  return points;
}

/// Komponen visual alur rute presisi dari start ke finish
class RunRouteView extends StatelessWidget {
  const RunRouteView({
    super.key,
    this.points = const [],
    this.segmentStarts = const {},
    this.encodedPolyline,
    this.routeColor,
    this.startMarkerColor,
    this.finishMarkerColor,
    this.backgroundColor,
    this.strokeWidth = 3.5,
    this.padding = 16.0,
  });

  final List<LatLngPoint> points;
  final Set<int> segmentStarts;
  final String? encodedPolyline;
  final Color? routeColor;
  final Color? startMarkerColor;
  final Color? finishMarkerColor;
  final Color? backgroundColor;
  final double strokeWidth;
  final double padding;

  @override
  Widget build(BuildContext context) {
    List<LatLngPoint> activePoints = points;
    if (activePoints.isEmpty &&
        encodedPolyline != null &&
        encodedPolyline!.isNotEmpty) {
      activePoints = decodePolylinePoints(encodedPolyline!);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(RwRadius.md),
      child: Container(
        color: backgroundColor ?? Colors.transparent,
        child: CustomPaint(
          painter: _RunRoutePainter(
            points: activePoints,
            segmentStarts: segmentStarts,
            routeColor: routeColor ?? RwColors.lime500,
            startColor: startMarkerColor ?? const Color(0xFF2ECC71),
            finishColor: finishMarkerColor ?? RwColors.ink950,
            strokeWidth: strokeWidth,
            padding: padding,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _RunRoutePainter extends CustomPainter {
  _RunRoutePainter({
    required this.points,
    required this.segmentStarts,
    required this.routeColor,
    required this.startColor,
    required this.finishColor,
    required this.strokeWidth,
    required this.padding,
  });

  final List<LatLngPoint> points;
  final Set<int> segmentStarts;
  final Color routeColor;
  final Color startColor;
  final Color finishColor;
  final double strokeWidth;
  final double padding;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    if (points.length < 2) {
      // Jika belum ada titik rute cukup, gambar representasi alur kurva sporty
      _paintEmptyPlaceholder(canvas, size);
      return;
    }

    // Hitung bounding box
    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final dLat = maxLat - minLat;
    final dLng = maxLng - minLng;

    // Hindari pembagian dengan nol jika rute di satu titik
    final spanLat = math.max(dLat, 0.0001);
    final spanLng = math.max(dLng, 0.0001);

    final availWidth = size.width - (padding * 2);
    final availHeight = size.height - (padding * 2);

    final scaleX = availWidth / spanLng;
    final scaleY = availHeight / spanLat;
    final scale = math.min(scaleX, scaleY);

    // Pusatkan rute di tengah canvas
    final routeWidth = spanLng * scale;
    final routeHeight = spanLat * scale;
    final offsetX = padding + (availWidth - routeWidth) / 2;
    final offsetY = padding + (availHeight - routeHeight) / 2;

    Offset toCanvas(LatLngPoint p) {
      final x = offsetX + (p.longitude - minLng) * scale;
      // Latitude terbalik pada sistem koordinat canvas (y bertambah ke bawah)
      final y = offsetY + (maxLat - p.latitude) * scale;
      return Offset(x, y);
    }

    final path = Path();
    final firstPoint = toCanvas(points.first);
    path.moveTo(firstPoint.dx, firstPoint.dy);

    for (var i = 1; i < points.length; i++) {
      final pt = toCanvas(points[i]);
      if (segmentStarts.contains(i)) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }

    // Bayangan / garis kontur bawah rute
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, shadowPaint);

    // Garis rute utama
    final routePaint = Paint()
      ..color = routeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, routePaint);

    // Titik START (lingkaran awal)
    final startPt = firstPoint;
    canvas.drawCircle(startPt, 5.0, Paint()..color = Colors.white);
    canvas.drawCircle(startPt, 4.0, Paint()..color = startColor);

    // Titik FINISH (lingkaran akhir)
    final finishPt = toCanvas(points.last);
    canvas.drawCircle(finishPt, 6.0, Paint()..color = Colors.white);
    canvas.drawCircle(finishPt, 4.5, Paint()..color = finishColor);
    canvas.drawCircle(finishPt, 2.0, Paint()..color = routeColor);
  }

  void _paintEmptyPlaceholder(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.15, h * 0.7)
      ..cubicTo(w * 0.35, h * 0.2, w * 0.65, h * 0.85, w * 0.85, h * 0.3);

    final paint = Paint()
      ..color = routeColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RunRoutePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.segmentStarts != segmentStarts ||
        oldDelegate.routeColor != routeColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
