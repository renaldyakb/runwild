import 'package:material_ui/material_ui.dart';

import '../tokens/rw_tokens.dart';

/// Komponen loading 1 layar penuh; mendukung teks status opsional untuk proses
/// penting seperti menyimpan sesi lari.
class RwFullPageLoading extends StatelessWidget {
  const RwFullPageLoading({
    super.key,
    this.backgroundColor,
    this.indicatorColor,
    this.label,
    this.subtitle,
  });

  final Color? backgroundColor;
  final Color? indicatorColor;
  final String? label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.scaffoldBackgroundColor;
    final fg = indicatorColor ?? RwColors.ink950;
    final hasText = label != null || subtitle != null;

    return Container(
      color: bg,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: RwSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              color: fg,
              backgroundColor: RwColors.paper200,
            ),
          ),
          if (hasText) const SizedBox(height: RwSpace.lg),
          if (label case final text?)
            Semantics(
              liveRegion: true,
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: RwType.family,
                  fontSize: RwType.body,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ),
          if (subtitle case final sub?) ...[
            const SizedBox(height: RwSpace.xs),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: RwType.family,
                fontSize: RwType.bodySmall,
                color: RwColors.mutedTextOnLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
