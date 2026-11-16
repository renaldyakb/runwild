import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';
import '../tokens/rw_tokens.dart';

class RwBottomNav extends StatelessWidget {
  const RwBottomNav({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final destinations = [
      (s.home, Icons.home_rounded),
      (s.run, Icons.directions_run_rounded),
      (s.activities, Icons.route_rounded),
      (s.profile, Icons.person_rounded),
    ];

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(RwSpace.sm, 0, RwSpace.sm, RwSpace.xs),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(RwRadius.lg),
          border: Border.all(color: const Color(0xFFE2E6DC), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RwSpace.xs,
            vertical: RwSpace.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: Semantics(
                    selected: selectedIndex == i,
                    child: TextButton(
                      onPressed: () => onSelected(i),
                      style: ButtonStyle(
                        minimumSize: const WidgetStatePropertyAll(
                          Size(RwSize.touch, RwSize.button),
                        ),
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(
                            horizontal: RwSpace.xxs,
                            vertical: RwSpace.xs,
                          ),
                        ),
                        foregroundColor: WidgetStatePropertyAll(
                          selectedIndex == i
                              ? RwColors.ink950
                              : RwColors.mutedTextOnLight,
                        ),
                        backgroundColor: WidgetStatePropertyAll(
                          selectedIndex == i
                              ? RwColors.lime500
                              : Colors.transparent,
                        ),
                        shape: const WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(RwRadius.md),
                            ),
                          ),
                        ),
                        overlayColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            destinations[i].$2,
                            size: 20,
                            color: selectedIndex == i
                                ? RwColors.ink950
                                : RwColors.mutedTextOnLight,
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              destinations[i].$1,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: RwType.family,
                                fontSize: 11,
                                fontWeight: selectedIndex == i
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                letterSpacing: 0,
                                color: selectedIndex == i
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
      ),
    );
  }
}
