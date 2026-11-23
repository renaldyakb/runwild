import 'package:material_ui/material_ui.dart';

import '../tokens/rw_tokens.dart';
import 'rw_motion.dart';

class RwCard extends StatelessWidget {
  const RwCard({
    required this.child,
    this.padding = const EdgeInsets.all(RwSpace.screen),
    this.color,
    this.borderColor,
    this.radius = RwRadius.lg,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(radius);
    final content = Padding(padding: padding, child: child);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? colors.surfaceContainer,
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor ?? colors.outlineVariant,
          width: RwSize.hairline,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: onTap != null
            ? InkWell(borderRadius: borderRadius, onTap: onTap, child: content)
            : content,
      ),
    );
    return onTap != null ? RwPressScale(child: card) : card;
  }
}
