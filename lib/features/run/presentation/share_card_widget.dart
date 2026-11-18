import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/components/rw_route_view.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../domain/tracking/run_summary.dart';
import '../../../l10n/generated/app_localizations.dart';

enum ShareCardTheme { primeLime, cleanPaper, boldCharcoal }

enum ShareCardFormat {
  story, // 9:16
  square, // 1:1
}

String _formatDuration(Duration duration) {
  final seconds = duration.inSeconds;
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String _formatPace(double? secondsPerKm) {
  if (secondsPerKm == null || secondsPerKm <= 0 || secondsPerKm.isInfinite) {
    return '—';
  }
  final totalSec = secondsPerKm.round();
  final m = totalSec ~/ 60;
  final s = totalSec % 60;
  return '$m\'${s.toString().padLeft(2, '0')}"';
}

class ShareCardWidget extends StatelessWidget {
  const ShareCardWidget({
    required this.summary,
    required this.theme,
    required this.format,
    required this.hideRoute,
    this.routePoints = const [],
    this.segmentStarts = const {},
    this.encodedPolyline,
    this.backgroundImageBytes,
    this.personalBests = const [],
    super.key,
  });
  final RunSummary summary;
  final ShareCardTheme theme;
  final ShareCardFormat format;
  final bool hideRoute;
  final List<LatLngPoint> routePoints;
  final Set<int> segmentStarts;
  final String? encodedPolyline;
  final Uint8List? backgroundImageBytes;
  final List<String> personalBests;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final story = format == ShareCardFormat.story;
    final photo = backgroundImageBytes;
    final light = photo == null && theme != ShareCardTheme.boldCharcoal;
    final ink = light ? RwColors.ink950 : RwColors.paper100;
    final background = switch (theme) {
      ShareCardTheme.primeLime => RwColors.lime500,
      ShareCardTheme.cleanPaper => RwColors.paper50,
      ShareCardTheme.boldCharcoal => RwColors.ink950,
    };
    final points = hideRoute
        ? const <LatLngPoint>[]
        : routePoints.isNotEmpty
        ? routePoints
        : decodePolylinePoints(encodedPolyline ?? '');
    final hasRoute = !hideRoute && points.length >= 2;
    TextStyle type(double size, {FontWeight weight = FontWeight.w600}) =>
        TextStyle(
          fontFamily: RwType.family,
          fontSize: size,
          fontWeight: weight,
          color: ink,
          height: 1.1,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    // Fixed artwork canvas keeps the PNG identical to its scaled preview.
    return AspectRatio(
      aspectRatio: story ? 9 / 16 : 1,
      child: FittedBox(
        child: SizedBox(
          width: RwSize.shareCanvas,
          height: story ? RwSize.shareStoryHeight : RwSize.shareCanvas,
          child: MediaQuery.withNoTextScaling(
            child: ColoredBox(
              color: background,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photo != null) ...[
                    Image.memory(photo, fit: BoxFit.cover),
                    ColoredBox(color: RwColors.ink950.withValues(alpha: 0.70)),
                  ],
                  Padding(
                    padding: const EdgeInsets.all(RwSpace.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'RUNWILD',
                              style: type(RwType.body, weight: FontWeight.w900),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('dd.MM.yyyy')
                                  .format(summary.startedAt),
                              style: type(RwType.label),
                            ),
                          ],
                        ),
                        SizedBox(height: story ? RwSpace.xxl : RwSpace.md),
                        Text(s.shareRun, style: type(RwType.label)),
                        const SizedBox(height: RwSpace.xs),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  (summary.distanceMeters / 1000)
                                      .toStringAsFixed(2),
                                  style: type(
                                    RwType.displayXL,
                                    weight: FontWeight.w900,
                                  ).copyWith(letterSpacing: RwType.tight),
                                ),
                              ),
                            ),
                            const SizedBox(width: RwSpace.xs),
                            Text(
                              s.shareDistanceUnit,
                              style: type(RwType.title),
                            ),
                          ],
                        ),
                        Expanded(
                          child: SizedBox.expand(
                            child: hasRoute
                                ? RunRouteView(
                                    points: points,
                                    segmentStarts: segmentStarts,
                                    routeColor: light
                                        ? RwColors.ink950
                                        : RwColors.lime500,
                                    startMarkerColor: ink,
                                    finishMarkerColor: ink,
                                    backgroundColor: RwColors.transparent,
                                    padding: RwSpace.lg,
                                    strokeWidth: RwSize.focus,
                                  )
                                : Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      s.shareTagline,
                                      style: type(
                                        story ? RwType.displayL : RwType.title,
                                        weight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        if (personalBests.isNotEmpty) ...[
                          Text(
                            s.shareRecord,
                            style: type(RwType.label, weight: FontWeight.w800),
                          ),
                          const SizedBox(height: RwSpace.xs),
                        ],
                        Divider(
                          color: ink.withValues(alpha: 0.35),
                          height: RwSpace.md,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                label: s.shareDuration,
                                value: _formatDuration(summary.movingTime),
                                color: ink,
                              ),
                            ),
                            Expanded(
                              child: _Metric(
                                label: s.sharePace,
                                value: _formatPace(summary.averagePace),
                                color: ink,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: story ? RwSpace.lg : RwSpace.sm),
                        Text(
                          hideRoute
                              ? s.shareRouteHidden
                              : hasRoute
                              ? 'RUN. TRACK. IMPROVE. GO WILD.'
                              : s.shareNoRoute,
                          style: type(RwType.label),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontFamily: RwType.family,
          color: color,
          fontSize: RwType.label,
        ),
      ),
      const SizedBox(height: RwSpace.xxs),
      Text(
        value,
        style: TextStyle(
          fontFamily: RwType.family,
          color: color,
          fontSize: RwType.title,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}
