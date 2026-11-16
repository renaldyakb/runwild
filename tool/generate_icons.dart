import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('Generate RUNWILD app icons', () async {
    final sizes = <String, int>{
      'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
      'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
      'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
      'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
      'assets/icons/app_icon.png': 512,
    };

    Directory('assets/icons').createSync(recursive: true);

    for (final entry in sizes.entries) {
      final path = entry.key;
      final size = entry.value.toDouble();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

      final center = Offset(size / 2, size / 2);
      final radius = size / 2;

      // 1. Background dark ink950
      final bgPaint = Paint()
        ..color = const Color(0xFF12130F)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, bgPaint);

      // 2. Subtle athletic outer ring Prime Lime
      final ringPaint = Paint()
        ..color = const Color(0xFFC7F000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.04;
      canvas.drawCircle(center, radius - (size * 0.02), ringPaint);

      // 3. Dynamic Athletic Running Silhouette / Wild Runner Bolt
      final primePaint = Paint()
        ..color = const Color(0xFFC7F000)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final s = size / 100.0;

      // Head
      canvas.drawCircle(Offset(58 * s, 26 * s), 7.5 * s, primePaint);

      // Athletic Runner Body Path (Forward leaning sprinter)
      final bodyPath = Path();
      // Torso & Legs
      bodyPath.moveTo(54 * s, 34 * s);
      bodyPath.lineTo(46 * s, 50 * s);
      bodyPath.lineTo(34 * s, 54 * s);
      bodyPath.lineTo(24 * s, 68 * s);
      bodyPath.lineTo(27 * s, 72 * s);
      bodyPath.lineTo(38 * s, 58 * s);
      bodyPath.lineTo(48 * s, 54 * s);
      bodyPath.lineTo(58 * s, 72 * s);
      bodyPath.lineTo(74 * s, 80 * s);
      bodyPath.lineTo(72 * s, 75 * s);
      bodyPath.lineTo(59 * s, 68 * s);
      bodyPath.lineTo(52 * s, 48 * s);
      bodyPath.lineTo(58 * s, 42 * s);
      bodyPath.lineTo(72 * s, 46 * s);
      bodyPath.lineTo(75 * s, 41 * s);
      bodyPath.lineTo(58 * s, 35 * s);
      bodyPath.close();

      canvas.drawPath(bodyPath, primePaint);

      // Runner trail spark / Speed chevron
      final sparkPath = Path();
      sparkPath.moveTo(25 * s, 38 * s);
      sparkPath.lineTo(38 * s, 42 * s);
      sparkPath.lineTo(28 * s, 46 * s);
      sparkPath.close();

      final sparkPaint = Paint()
        ..color = const Color(0xFFEAF854)
        ..style = PaintingStyle.fill;
      canvas.drawPath(sparkPath, sparkPaint);

      final picture = recorder.endRecording();
      final image = await picture.toImage(entry.value, entry.value);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        File(path).writeAsBytesSync(byteData.buffer.asUint8List());
      }
    }
  });
}
