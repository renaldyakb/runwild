import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';
import '../tokens/rw_tokens.dart';
import 'rw_button.dart';
import 'rw_card.dart';

enum RwViewState { content, loading, empty, error, offline }

class RwStateView extends StatelessWidget {
  const RwStateView({required this.state, required this.onAction, super.key});
  final RwViewState state;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    if (state == RwViewState.loading) {
      return Semantics(
        label: s.loadingActivities,
        liveRegion: true,
        child: ExcludeSemantics(
          child: RwCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.loadingActivities),
                const SizedBox(height: RwSpace.md),
                const _Skeleton(height: RwSize.skeletonHeading),
                const SizedBox(height: RwSpace.sm),
                const FractionallySizedBox(
                  widthFactor: RwSize.skeletonShortFraction,
                  alignment: Alignment.centerLeft,
                  child: _Skeleton(height: RwSize.skeleton),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final (title, body, icon) = switch (state) {
      RwViewState.empty => (s.emptyTitle, s.emptyBody, Icons.route_outlined),
      RwViewState.error => (s.errorTitle, s.errorBody, Icons.error_outline),
      RwViewState.offline => (
        s.offlineTitle,
        s.offlineBody,
        Icons.cloud_off_outlined,
      ),
      _ => (s.contentTitle, s.contentBody, Icons.check_circle_outline),
    };
    return RwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Icon(icon, size: RwSize.icon),
          ),
          const SizedBox(height: RwSpace.md),
          Semantics(
            liveRegion: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: RwSpace.xs),
          Text(body),
          if (state != RwViewState.content) ...[
            const SizedBox(height: RwSpace.lg),
            RwButton.secondary(
              label: state == RwViewState.empty ? s.runSetup : s.retry,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.outlineVariant,
      borderRadius: BorderRadius.circular(RwRadius.sm),
    ),
  );
}
