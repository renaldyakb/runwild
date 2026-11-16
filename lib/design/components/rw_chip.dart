import 'package:material_ui/material_ui.dart';

import '../tokens/rw_tokens.dart';

/// Item pilihan untuk segmented control
class RwSegmentItem<T> {
  const RwSegmentItem({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Segmented control rapi dan simetris (pengganti chips berserakan)
class RwSegmentedControl<T> extends StatelessWidget {
  const RwSegmentedControl({
    required this.items,
    required this.selectedValue,
    this.onChanged,
    super.key,
  });

  final List<RwSegmentItem<T>> items;
  final T selectedValue;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onChanged == null ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF2EA),
          borderRadius: BorderRadius.circular(RwRadius.pill),
          border: Border.all(color: const Color(0xFFE2E6DC), width: 1),
        ),
        child: Row(
          children: [
            for (final item in items)
              Expanded(
                child: RwChip(
                  label: item.label,
                  selected: item.value == selectedValue,
                  onSelected: onChanged == null
                      ? null
                      : (_) => onChanged!(item.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: item.value == selectedValue
                          ? RwColors.lime500
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(RwRadius.pill),
                      boxShadow: item.value == selectedValue
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (item.icon != null) ...[
                          Icon(
                            item.icon,
                            size: 16,
                            color: item.value == selectedValue
                                ? RwColors.ink950
                                : RwColors.mutedTextOnLight,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: RwType.family,
                              fontSize: 13,
                              fontWeight: item.value == selectedValue
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              letterSpacing: 0,
                              color: item.value == selectedValue
                                  ? RwColors.ink950
                                  : RwColors.mutedTextOnLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Chip standar yang dirapikan tanpa border kasar
class RwChip extends StatelessWidget {
  const RwChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.child,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSelected == null ? null : () => onSelected!(!selected),
        child: child,
      );
    }

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: RwType.family,
          fontSize: 13,
          letterSpacing: 0,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          color: selected ? RwColors.ink950 : RwColors.ink700,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: RwColors.lime500,
      backgroundColor: const Color(0xFFEFF2EA),
      side: BorderSide(
        color: selected ? RwColors.lime600 : const Color(0xFFE2E6DC),
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RwRadius.pill),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
