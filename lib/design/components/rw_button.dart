import 'package:material_ui/material_ui.dart';

import '../tokens/rw_tokens.dart';

class RwButton extends StatelessWidget {
  const RwButton.primary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.loadingLabel,
    this.fullWidth = true,
    super.key,
  }) : secondary = false;

  const RwButton.secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.loadingLabel,
    this.fullWidth = true,
    super.key,
  }) : secondary = true;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final String? loadingLabel;
  final bool secondary;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduced = MediaQuery.disableAnimationsOf(context);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading || icon != null) ...[
          Icon(loading ? Icons.hourglass_top_rounded : icon, size: 20),
          const SizedBox(width: RwSpace.xs),
        ],
        Flexible(
          child: Text(
            loading ? loadingLabel ?? label : label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: RwType.family,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );

    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: RwSpace.lg, vertical: RwSpace.sm),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RwRadius.pill),
        ),
      ),
      animationDuration: reduced ? Duration.zero : RwMotion.micro,
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.onSurfaceVariant.withValues(alpha: 0.5);
        }
        return secondary ? RwColors.ink950 : RwColors.ink950;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return const Color(0xFFEFF2EA);
        }
        if (secondary) {
          if (states.contains(WidgetState.pressed)) {
            return const Color(0xFFF0F3EB);
          }
          return const Color(0xFFFFFFFF);
        }
        if (states.contains(WidgetState.pressed)) {
          return RwColors.lime600;
        }
        return RwColors.lime500;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (secondary) {
          return const BorderSide(color: Color(0xFFE2E6DC), width: 1.2);
        }
        return BorderSide.none;
      }),
      elevation: const WidgetStatePropertyAll(0),
      overlayColor: const WidgetStatePropertyAll(RwColors.transparent),
    );

    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      style: style,
      child: content,
    );

    return Semantics(
      liveRegion: loading,
      child: fullWidth
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }
}
