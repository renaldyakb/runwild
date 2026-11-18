import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constants/calibration_limits.dart';
import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../domain/tracking/gps_calibration.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/gps_calibration.dart';
import '../application/run_permissions.dart';

const _calibrationAnimation = 'assets/lottie/gps_calibration.json';

Future<void> showGpsCalibrationSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const GpsCalibrationSheet(),
    );

/// Animasi ring sinyal. Saat gerak dikurangi atau aset gagal dimuat, tampil
/// ikon satelit statis supaya tetap terbaca tanpa loop yang mengganggu.
class GpsCalibrationBadge extends StatelessWidget {
  const GpsCalibrationBadge({this.size = 96, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.satellite_alt_rounded,
      size: size * 0.55,
      color: RwColors.lime700,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      return SizedBox(width: size, height: size, child: fallback);
    }
    return Lottie.asset(
      _calibrationAnimation,
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: true,
      errorBuilder: (context, error, stackTrace) =>
          SizedBox(width: size, height: size, child: fallback),
    );
  }
}

class GpsCalibrationSheet extends ConsumerStatefulWidget {
  const GpsCalibrationSheet({super.key});

  @override
  ConsumerState<GpsCalibrationSheet> createState() =>
      _GpsCalibrationSheetState();
}

class _GpsCalibrationSheetState extends ConsumerState<GpsCalibrationSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(gpsCalibrationControllerProvider.notifier).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final view = ref.watch(gpsCalibrationControllerProvider);
    final controller = ref.read(gpsCalibrationControllerProvider.notifier);

    return RwPage(
      children: [
        Text(
          s.calibrationTitle,
          style: const TextStyle(
            fontFamily: RwType.family,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: RwColors.ink950,
          ),
        ),
        const SizedBox(height: RwSpace.xs),
        Text(
          s.calibrationIntro,
          style: const TextStyle(
            fontFamily: RwType.family,
            fontSize: 13,
            color: RwColors.mutedTextOnLight,
          ),
        ),
        const SizedBox(height: RwSpace.md),
        Center(child: GpsCalibrationBadge(size: 128)),
        const SizedBox(height: RwSpace.md),
        ..._body(s, view),
        const SizedBox(height: RwSpace.lg),
        ..._actions(context, s, view, controller),
      ],
    );
  }

  List<Widget> _body(AppLocalizations s, GpsCalibrationView view) {
    switch (view.phase) {
      case GpsCalibrationPhase.idle:
        return const [];
      case GpsCalibrationPhase.sampling:
        final seconds = view.samples.isEmpty
            ? 0
            : view.samples.last.capturedAt.inSeconds;
        final progress = (view.samples.length / CalibrationLimits.targetSamples)
            .clamp(0.0, 1.0);
        final accuracy = view.report?.medianAccuracyMeters;
        return [
          Semantics(
            liveRegion: true,
            child: Text(
              s.calibrationMeasuring,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: RwType.family,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: RwColors.ink950,
              ),
            ),
          ),
          const SizedBox(height: RwSpace.xs),
          Text(
            s.calibrationProgress(
              seconds,
              CalibrationLimits.maximumDuration.inSeconds,
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: RwType.family,
              fontSize: 12,
              color: RwColors.mutedTextOnLight,
            ),
          ),
          const SizedBox(height: RwSpace.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(RwRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: RwColors.paper50,
              color: RwColors.lime500,
            ),
          ),
          if (accuracy != null) ...[
            const SizedBox(height: RwSpace.xs),
            Text(
              s.calibrationAccuracy(accuracy.round()),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: RwType.family,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
                color: RwColors.ink950,
              ),
            ),
          ],
        ];
      case GpsCalibrationPhase.done:
        final report = view.report;
        final grade = report?.grade;
        if (report == null || grade == null) {
          return [
            Text(
              s.calibrationFailed,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: RwType.family,
                fontSize: 13,
                color: RwColors.mutedTextOnLight,
              ),
            ),
          ];
        }
        final meters = report.medianAccuracyMeters.round();
        final copy = switch (grade) {
          GpsCalibrationGrade.good => (
            title: s.calibrationGoodTitle,
            body: s.calibrationGoodBody(meters),
          ),
          GpsCalibrationGrade.fair => (
            title: s.calibrationFairTitle,
            body: s.calibrationFairBody(meters),
          ),
          GpsCalibrationGrade.poor => (
            title: s.calibrationPoorTitle,
            body: s.calibrationPoorBody(meters),
          ),
        };
        return [
          Text(
            copy.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: RwType.family,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: RwColors.ink950,
            ),
          ),
          const SizedBox(height: RwSpace.xs),
          Text(
            copy.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: RwType.family,
              fontSize: 13,
              color: RwColors.mutedTextOnLight,
            ),
          ),
          if (view.saveFailed) ...[
            const SizedBox(height: RwSpace.xs),
            Text(
              s.calibrationSaveFailed,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: RwType.family,
                fontSize: 12,
                color: RwColors.mutedTextOnLight,
              ),
            ),
          ],
        ];
      case GpsCalibrationPhase.failed:
        return [
          Text(
            view.serviceDisabled
                ? s.calibrationServiceOff
                : s.calibrationFailed,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: RwType.family,
              fontSize: 13,
              color: RwColors.ink950,
            ),
          ),
        ];
    }
  }

  List<Widget> _actions(
    BuildContext context,
    AppLocalizations s,
    GpsCalibrationView view,
    GpsCalibrationController controller,
  ) {
    void close() => Navigator.of(context).pop();
    switch (view.phase) {
      case GpsCalibrationPhase.idle:
        return [
          RwButton.primary(
            label: s.calibrationStart,
            onPressed: controller.start,
          ),
          const SizedBox(height: RwSpace.xs),
          RwButton.secondary(label: s.close, onPressed: close),
        ];
      case GpsCalibrationPhase.sampling:
        return [
          RwButton.secondary(
            label: s.calibrationCancel,
            onPressed: controller.cancel,
          ),
        ];
      case GpsCalibrationPhase.done:
        if (view.report?.grade == GpsCalibrationGrade.poor) {
          return [
            RwButton.primary(
              label: s.calibrationRetry,
              onPressed: controller.start,
            ),
            const SizedBox(height: RwSpace.xs),
            RwButton.secondary(label: s.close, onPressed: close),
          ];
        }
        return [
          RwButton.primary(label: s.calibrationDone, onPressed: close),
          const SizedBox(height: RwSpace.xs),
          RwButton.secondary(
            label: s.calibrationRetry,
            onPressed: controller.start,
          ),
        ];
      case GpsCalibrationPhase.failed:
        return [
          if (view.serviceDisabled) ...[
            RwButton.primary(
              label: s.runLocationServiceEnable,
              onPressed: () => unawaited(_openLocationSettings()),
            ),
            const SizedBox(height: RwSpace.xs),
          ] else ...[
            RwButton.primary(
              label: s.calibrationRetry,
              onPressed: controller.start,
            ),
            const SizedBox(height: RwSpace.xs),
          ],
          RwButton.secondary(label: s.close, onPressed: close),
        ];
    }
  }

  Future<void> _openLocationSettings() async {
    final opened = await ref
        .read(runPermissionsProvider)
        .openLocationSettings();
    if (!opened) {
      debugPrint('Location settings could not be opened');
    }
  }
}
