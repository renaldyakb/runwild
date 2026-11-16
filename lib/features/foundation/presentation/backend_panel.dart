import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_card.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';

class BackendPanel extends ConsumerWidget {
  const BackendPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final status = ref.watch(backendStatusProvider);
    final message = status.when(
      data: (value) => switch (value) {
        BackendStatus.local => s.backendLocal,
        BackendStatus.ready => s.backendReady,
        BackendStatus.invalid => s.backendInvalid,
        BackendStatus.failed => s.backendError,
      },
      loading: () => s.backendConnecting,
      error: (error, stack) => s.backendError,
    );
    return RwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.backend, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: RwSpace.xs),
          Semantics(liveRegion: true, child: Text(message)),
          if (status.isLoading) ...[
            const SizedBox(height: RwSpace.sm),
            Container(
              height: RwSize.skeleton,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ],
          if (status.hasError ||
              status.asData?.value == BackendStatus.failed) ...[
            const SizedBox(height: RwSpace.md),
            RwButton.secondary(
              label: s.retry,
              onPressed: () => ref.invalidate(backendStatusProvider),
            ),
          ],
        ],
      ),
    );
  }
}
