import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../../design/components/rw_route_view.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../domain/tracking/run_summary.dart';

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

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  if (month >= 1 && month <= 12) return months[month - 1];
  return '';
}

class ShareCardWidget extends StatelessWidget {
  const ShareCardWidget({
    required this.summary,
    required this.theme,
    required this.format,
    required this.hideRoute,
    this.routePoints = const [],
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
  final String? encodedPolyline;
  final Uint8List? backgroundImageBytes;
  final List<String> personalBests;

  @override
  Widget build(BuildContext context) {
    final aspectRatio = format == ShareCardFormat.story ? (9 / 16) : 1.0;
    final isSquare = format == ShareCardFormat.square;
    final hasCustomBg = backgroundImageBytes != null;

    final (
      bgColor,
      hudBg,
      hudBorder,
      primaryText,
      accentText,
      labelText,
      badgeBg,
      badgeFg,
      routeColor,
    ) = hasCustomBg
        ? (
            Colors.black,
            Colors.black.withValues(alpha: 0.58),
            Colors.white.withValues(alpha: 0.22),
            Colors.white,
            RwColors.lime500,
            Colors.white.withValues(alpha: 0.75),
            RwColors.lime500,
            RwColors.ink950,
            RwColors.lime500,
          )
        : switch (theme) {
            ShareCardTheme.primeLime => (
              RwColors.ink950,
              const Color(0xFF1B1D16),
              RwColors.lime500.withValues(alpha: 0.32),
              RwColors.paper50,
              RwColors.lime500,
              const Color(0xFFA6ACA0),
              RwColors.lime500,
              RwColors.ink950,
              RwColors.lime500,
            ),
            ShareCardTheme.cleanPaper => (
              RwColors.paper50,
              Colors.white,
              const Color(0xFFE2E6DC),
              RwColors.ink950,
              RwColors.ink950,
              RwColors.mutedTextOnLight,
              RwColors.ink950,
              RwColors.lime500,
              RwColors.ink950,
            ),
            ShareCardTheme.boldCharcoal => (
              const Color(0xFF0F100D),
              const Color(0xFF1B1C18),
              const Color(0xFF2C3026),
              Colors.white,
              Colors.white,
              const Color(0xFFA6ACA0),
              Colors.white,
              RwColors.ink950,
              RwColors.lime500,
            ),
          };

    final distanceKm = (summary.distanceMeters / 1000.0).toStringAsFixed(2);
    final movingFormatted = _formatDuration(summary.movingTime);
    final avgPaceFormatted = _formatPace(summary.averagePace);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(RwRadius.lg),
          border: Border.all(color: hudBorder, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background Foto Kustom Jika Tersedia ───────────────────
            if (hasCustomBg) ...[
              Image.memory(
                backgroundImageBytes!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              // Gradien multi-stop sinematik agar teks terbaca tajam
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.35, 0.65, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.65),
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.50),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
            ],

            // ── Foreground Content Layout ─────────────────────────────
            Padding(
              padding: EdgeInsets.all(isSquare ? RwSpace.md : RwSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header: Brand Identity & Privacy / Mode ─────────
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(RwRadius.sm),
                          boxShadow: [
                            if (badgeBg == RwColors.lime500)
                              BoxShadow(
                                color: RwColors.lime500.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                          ],
                        ),
                        child: Icon(
                          Icons.directions_run_rounded,
                          color: badgeFg,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: RwSpace.xs + 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'RUNWILD',
                              style: TextStyle(
                                fontFamily: RwType.family,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                                color: primaryText,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              'RUN FREE, GO WILD.',
                              style: TextStyle(
                                fontFamily: RwType.family,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: labelText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hideRoute) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: hudBg,
                            borderRadius: BorderRadius.circular(RwRadius.pill),
                            border: Border.all(
                              color: hudBorder.withValues(alpha: 0.6),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_rounded,
                                size: 11,
                                color: labelText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Privasi',
                                style: TextStyle(
                                  fontFamily: RwType.family,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: labelText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: hudBg,
                            borderRadius: BorderRadius.circular(RwRadius.pill),
                            border: Border.all(
                              color: hudBorder.withValues(alpha: 0.6),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            summary.interval != null
                                ? 'INTERVAL'
                                : 'LARI BEBAS',
                            style: TextStyle(
                              fontFamily: RwType.family,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: accentText,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // ── Center Content: Route & Personal Best ───────────
                  Expanded(
                    child: Stack(
                      children: [
                        // Rute lari presisi jika tidak disembunyikan
                        if (!hideRoute)
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: RunRouteView(
                                points: routePoints,
                                encodedPolyline: encodedPolyline,
                                routeColor: routeColor,
                                strokeWidth: 3.8,
                              ),
                            ),
                          )
                        else
                          // Subtle geometric accent saat rute disembunyikan
                          Center(
                            child: Icon(
                              Icons.shield_outlined,
                              size: isSquare ? 54 : 72,
                              color: labelText.withValues(alpha: 0.15),
                            ),
                          ),

                        // Rekor Pribadi Pill Badge (Posisi Melayang Atletis)
                        if (personalBests.isNotEmpty)
                          Positioned(
                            top: 8,
                            left: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: RwColors.lime500,
                                borderRadius: BorderRadius.circular(
                                  RwRadius.pill,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.emoji_events_rounded,
                                    size: 12,
                                    color: RwColors.ink950,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'REKOR PRIBADI · ${personalBests.first.toUpperCase()}',
                                    style: const TextStyle(
                                      fontFamily: RwType.family,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: RwColors.ink950,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Bottom Floating Athletic HUD Card ───────────────
                  Container(
                    decoration: BoxDecoration(
                      color: hudBg,
                      borderRadius: BorderRadius.circular(RwRadius.md),
                      border: Border.all(color: hudBorder, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Hero Distance Section
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: RwSpace.sm,
                            vertical: isSquare ? RwSpace.xs : RwSpace.sm,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    distanceKm,
                                    style: TextStyle(
                                      fontFamily: RwType.family,
                                      fontSize: isSquare ? 42 : 52,
                                      fontWeight: FontWeight.w900,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                      color: accentText,
                                      letterSpacing: -1.0,
                                      height: 0.95,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'KILOMETER',
                                  style: TextStyle(
                                    fontFamily: RwType.family,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    color: labelText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Hairline Divider
                        Container(
                          height: 0.8,
                          color: hudBorder.withValues(alpha: 0.5),
                        ),

                        // Secondary 3-Column Metrics Grid
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: RwSpace.sm,
                            vertical: isSquare ? RwSpace.xs - 2 : RwSpace.xs,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _HudMetric(
                                  label: 'DURASI',
                                  value: movingFormatted,
                                  textColor: primaryText,
                                  labelColor: labelText,
                                ),
                              ),
                              Container(
                                width: 0.8,
                                height: 22,
                                color: hudBorder.withValues(alpha: 0.5),
                              ),
                              Expanded(
                                child: _HudMetric(
                                  label: 'PACE',
                                  value: '$avgPaceFormatted/km',
                                  textColor: primaryText,
                                  labelColor: labelText,
                                ),
                              ),
                              Container(
                                width: 0.8,
                                height: 22,
                                color: hudBorder.withValues(alpha: 0.5),
                              ),
                              Expanded(
                                child: _HudMetric(
                                  label: 'KALORI',
                                  value: '${summary.estimatedCalories} kcal',
                                  textColor: primaryText,
                                  labelColor: labelText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Footer Note & Date ──────────────────────────────
                  SizedBox(height: isSquare ? RwSpace.xs : RwSpace.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${summary.startedAt.day} ${_monthName(summary.startedAt.month)} ${summary.startedAt.year}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: RwType.family,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: labelText,
                          ),
                        ),
                      ),
                      Text(
                        summary.interval != null ? 'INTERVAL' : 'LARI BEBAS',
                        style: TextStyle(
                          fontFamily: RwType.family,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: accentText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudMetric extends StatelessWidget {
  const _HudMetric({
    required this.label,
    required this.value,
    required this.textColor,
    required this.labelColor,
  });

  final String label;
  final String value;
  final Color textColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: RwType.family,
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: RwType.family,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}
