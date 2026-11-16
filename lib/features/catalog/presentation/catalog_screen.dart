import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_chip.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/components/rw_stat_tile.dart';
import '../../../design/components/rw_state_view.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../run/presentation/run_setup_sheet.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  bool interval = false;
  RwViewState viewState = RwViewState.empty;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final mode = ref.watch(themeModeProvider);
    final stateLabels = {
      RwViewState.content: s.stateContent,
      RwViewState.loading: s.stateLoading,
      RwViewState.empty: s.stateEmpty,
      RwViewState.error: s.stateError,
      RwViewState.offline: s.stateOffline,
    };
    return Scaffold(
      appBar: AppBar(title: Text(s.catalog)),
      body: RwPage(
        children: [
          Semantics(
            header: true,
            child: Text(
              s.catalogTitle,
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
          const SizedBox(height: RwSpace.md),
          Text(s.catalogBody),
          RwSectionTitle(s.appearance),
          Wrap(
            spacing: RwSpace.xs,
            runSpacing: RwSpace.xs,
            children: [
              for (final (value, label) in [
                (ThemeMode.system, s.systemTheme),
                (ThemeMode.light, s.lightTheme),
                (ThemeMode.dark, s.darkTheme),
              ])
                RwChip(
                  label: label,
                  selected: mode == value,
                  onSelected: (_) =>
                      ref.read(themeModeProvider.notifier).select(value),
                ),
            ],
          ),
          RwSectionTitle(s.actions),
          RwButton.primary(
            label: s.previewAction,
            icon: Icons.touch_app_outlined,
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(s.actionFeedback)));
            },
          ),
          const SizedBox(height: RwSpace.sm),
          RwButton.secondary(
            label: s.previewSecondary,
            onPressed: () => unawaited(
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(s.dialogTitle),
                  content: Text(s.dialogBody),
                  scrollable: true,
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(s.close),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: RwSpace.sm),
          RwButton.primary(label: s.disabledAction, onPressed: null),
          const SizedBox(height: RwSpace.sm),
          RwButton.primary(
            label: s.loadingLabel,
            loading: true,
            loadingLabel: s.loadingAction,
            onPressed: null,
          ),
          RwSectionTitle(s.choices),
          Wrap(
            spacing: RwSpace.xs,
            runSpacing: RwSpace.xs,
            children: [
              RwChip(
                label: s.freeMode,
                selected: !interval,
                onSelected: (_) => setState(() => interval = false),
              ),
              RwChip(
                label: s.intervalMode,
                selected: interval,
                onSelected: (_) => setState(() => interval = true),
              ),
            ],
          ),
          RwSectionTitle(s.metrics),
          RwStatTile(
            label: s.distance,
            value: s.noValue,
            unit: s.distanceUnit,
            semanticLabel: s.noDistance,
            icon: Icons.route_outlined,
          ),
          const SizedBox(height: RwSpace.sm),
          Text(s.metricNote),
          RwSectionTitle(s.states),
          Text(s.statePreview),
          const SizedBox(height: RwSpace.md),
          Wrap(
            spacing: RwSpace.xs,
            runSpacing: RwSpace.xs,
            children: [
              for (final entry in stateLabels.entries)
                RwChip(
                  label: entry.value,
                  selected: viewState == entry.key,
                  onSelected: (_) => setState(() => viewState = entry.key),
                ),
            ],
          ),
          const SizedBox(height: RwSpace.md),
          RwStateView(
            state: viewState,
            onAction: () {
              if (viewState == RwViewState.empty) {
                unawaited(showRunSetupSheet(context));
              } else {
                setState(() => viewState = RwViewState.content);
              }
            },
          ),
        ],
      ),
    );
  }
}
