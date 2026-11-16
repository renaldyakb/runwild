import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/components/rw_button.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/run_gps_probe.dart';

class RunGpsControls extends ConsumerWidget {
  const RunGpsControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final probe = ref.watch(runGpsProbeProvider);
    final isRunning =
        probe.status == GpsProbeStatus.waiting ||
        probe.status == GpsProbeStatus.recording;
    final message = switch (probe.status) {
      GpsProbeStatus.idle => s.runGpsReady,
      GpsProbeStatus.waiting => s.runGpsWaiting,
      GpsProbeStatus.recording => s.runGpsRecording,
      GpsProbeStatus.stopped => s.runGpsStopped,
      GpsProbeStatus.failed => s.runGpsError,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(liveRegion: true, child: Text(message)),
        if (probe.status != GpsProbeStatus.idle) ...[
          const SizedBox(height: RwSpace.xs),
          Text(s.runGpsMetrics(probe.points, probe.meters.round())),
        ],
        const SizedBox(height: RwSpace.md),
        RwButton.primary(
          label: isRunning ? s.runGpsStop : s.runGpsStart,
          onPressed: isRunning
              ? ref.read(runGpsProbeProvider.notifier).stop
              : () => unawaited(
                  ref
                      .read(runGpsProbeProvider.notifier)
                      .start(
                        notificationTitle: s.runGpsNotificationTitle,
                        notificationText: s.runGpsNotificationText,
                      ),
                ),
        ),
      ],
    );
  }
}
