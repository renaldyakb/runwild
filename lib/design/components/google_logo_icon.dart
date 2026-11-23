import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Ikon vektor logo Google 4 warna resmi untuk tombol autentikasi.
class GoogleLogoIcon extends StatelessWidget {
  const GoogleLogoIcon({this.size = 20, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _GoogleLogoPainter()),
  );
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = s * 0.21;
    final radius = (s - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    // Merah (atas kiri ke atas kanan)
    paint.color = _red;
    canvas.drawArc(rect, -math.pi * 0.80, math.pi * 0.56, false, paint);

    // Kuning (kiri)
    paint.color = _yellow;
    canvas.drawArc(rect, math.pi * 0.78, math.pi * 0.44, false, paint);

    // Hijau (bawah)
    paint.color = _green;
    canvas.drawArc(rect, math.pi * 0.20, math.pi * 0.60, false, paint);

    // Biru (kanan bawah sampai horizontal tengah)
    paint.color = _blue;
    canvas.drawArc(rect, -math.pi * 0.04, math.pi * 0.26, false, paint);

    // Batang horizontal huruf G
    final barPaint = Paint()
      ..color = _blue
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final barHeight = stroke * 0.96;
    final barRect = Rect.fromLTWH(
      center.dx - s * 0.02,
      center.dy - barHeight / 2,
      radius + stroke / 2 + s * 0.02,
      barHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, Radius.circular(stroke * 0.12)),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
