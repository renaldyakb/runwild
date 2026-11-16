import 'package:material_ui/material_ui.dart';

import '../tokens/rw_tokens.dart';
import 'rw_card.dart';

class RwStatTile extends StatelessWidget {
  const RwStatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.semanticLabel,
    required this.icon,
    super.key,
  });
  final String label;
  final String value;
  final String unit;
  final String semanticLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: RwCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(RwSpace.xxs),
                  decoration: BoxDecoration(
                    color: dark ? RwColors.ink700 : RwColors.lime100,
                    borderRadius: BorderRadius.circular(RwRadius.sm),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.primary,
                    size: RwSize.icon,
                  ),
                ),
                const SizedBox(width: RwSpace.xs),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: RwSpace.md),
            Wrap(
              spacing: RwSpace.xs,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                Text(
                  value,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: RwSpace.xxs),
                  child: Text(
                    unit,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
