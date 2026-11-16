import 'package:material_ui/material_ui.dart';

import '../tokens/rw_tokens.dart';

class MountainSilhouette extends StatelessWidget {
  const MountainSilhouette({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: RwSize.landscape,
      width: double.infinity,
      child: CustomPaint(
        painter: _MountainPainter(
          mountain: Theme.of(context).colorScheme.onSurface,
          snow: Theme.of(context).colorScheme.surface,
        ),
      ),
    ),
  );
}

class _MountainPainter extends CustomPainter {
  const _MountainPainter({required this.mountain, required this.snow});
  final Color mountain;
  final Color snow;

  @override
  void paint(Canvas canvas, Size size) {
    // Normalized points preserve the same ridge at every phone width.
    canvas.save();
    canvas.scale(size.width, size.height);
    canvas.drawOval(
      const Rect.fromLTWH(.66, .04, .18, .55),
      Paint()..color = RwColors.lime500,
    );
    final ridge = Path()
      ..moveTo(0, .9)
      ..lineTo(.16, .44)
      ..lineTo(.24, .66)
      ..lineTo(.43, .08)
      ..lineTo(.62, .65)
      ..lineTo(.72, .4)
      ..lineTo(.9, .83)
      ..lineTo(1, .68)
      ..lineTo(1, 1)
      ..lineTo(0, 1)
      ..close();
    canvas.drawPath(ridge, Paint()..color = mountain);
    final cap = Path()
      ..moveTo(.43, .08)
      ..lineTo(.34, .36)
      ..lineTo(.41, .28)
      ..lineTo(.45, .4)
      ..lineTo(.49, .32)
      ..close();
    canvas.drawPath(cap, Paint()..color = snow);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MountainPainter oldDelegate) =>
      mountain != oldDelegate.mountain || snow != oldDelegate.snow;
}
