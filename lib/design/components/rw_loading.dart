import 'package:material_ui/material_ui.dart';

import '../tokens/rw_tokens.dart';

/// Komponen loading 1 layar penuh tanpa teks untuk data fetching
class RwFullPageLoading extends StatelessWidget {
  const RwFullPageLoading({
    super.key,
    this.backgroundColor,
    this.indicatorColor,
  });

  final Color? backgroundColor;
  final Color? indicatorColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.scaffoldBackgroundColor;
    final fg = indicatorColor ?? RwColors.ink950;

    return Container(
      color: bg,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(
          strokeWidth: 3.5,
          color: fg,
          backgroundColor: RwColors.paper200,
        ),
      ),
    );
  }
}
