import 'package:material_ui/material_ui.dart';

import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_card.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../profile/presentation/profile_screen.dart';
import 'home_dashboard.dart';

enum FoundationDestination { home, activities, profile }

class FoundationScreen extends StatelessWidget {
  const FoundationScreen({required this.destination, this.onStart, super.key});
  final FoundationDestination destination;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final home = destination == FoundationDestination.home;
    if (home) return HomeDashboard(onStart: onStart);

    if (destination == FoundationDestination.activities) {
      return RwPage(
        children: [
          Semantics(
            header: true,
            child: Text(
              s.comingActivities,
              style: Theme.of(context).textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
          ),
          const SizedBox(height: RwSpace.md),
          Text(
            s.comingActivitiesBody,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: RwSpace.xl),
          RwCard(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? RwColors.ink800
                        : RwColors.lime100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_run_rounded,
                    size: 44,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: RwSpace.lg),
                Text(
                  s.homeRouteEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: RwSpace.xs),
                Text(
                  s.homeRouteHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: RwSpace.xl),
                RwButton.primary(
                  label: s.homeStart,
                  icon: Icons.play_arrow_rounded,
                  onPressed: onStart,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Profile Destination
    return const ProfileScreen();
  }
}
