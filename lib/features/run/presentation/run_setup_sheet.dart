import 'package:material_ui/material_ui.dart';

import '../../../design/components/rw_button.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';

Future<void> showRunSetupSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        final s = AppLocalizations.of(context);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(RwSpace.screen),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    s.comingRun,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: RwSpace.md),
                Text(s.comingRunBody),
                const SizedBox(height: RwSpace.lg),
                RwButton.primary(
                  label: s.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
