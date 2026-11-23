import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/services/app_update_service.dart';
import '../../../core/utils/day_greeting.dart';
import '../../../core/utils/duration_format.dart';
import '../../../design/components/rw_bar_chart.dart';
import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_card.dart';
import '../../../design/components/rw_motion.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../domain/stats/stats_engine.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../profile/application/profile_service.dart';
import '../application/home_stats_provider.dart';
import '../application/run_reminder.dart';
import '../application/weather_kind.dart';
import '../application/weather_service.dart';
import 'app_update_dialog.dart';
import 'weather_animation.dart';
import 'weather_detail_screen.dart';

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({required this.onStart, super.key});

  final VoidCallback? onStart;

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard>
    with WidgetsBindingObserver {
  static bool _hasCheckedUpdateThisSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!_hasCheckedUpdateThisSession) {
      _hasCheckedUpdateThisSession = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAppUpdate());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(weatherProvider);
      ref.invalidate(runRemindersProvider);
    }
  }

  Future<void> _checkAppUpdate() async {
    try {
      final updateService = ref.read(appUpdateServiceProvider);
      final updateInfo = await updateService.checkForUpdate(notify: true);
      if (mounted && updateInfo != null && updateInfo.hasUpdate) {
        unawaited(AppUpdateDialog.show(context, updateInfo));
      }
    } on Object catch (error) {
      // Kegagalan cek pembaruan tidak boleh mengganggu beranda maupun
      // menyisakan error asinkron setelah layar selesai dirender.
      debugPrint('App update check failed: ${error.runtimeType}');
    }
  }

  @override
  Widget build(BuildContext context) => RwPage(
    children: [
      RwEntrance(order: 0, child: _HeroCard(onStart: widget.onStart)),
      const SizedBox(height: RwSpace.md),
      const RwEntrance(order: 1, child: _WeekSection()),
      const SizedBox(height: RwSpace.md),
      RwEntrance(order: 2, child: _RecommendationCard(onStart: widget.onStart)),
      const SizedBox(height: RwSpace.md),
      const RwEntrance(order: 3, child: _ReminderRow()),
      const SizedBox(height: RwSpace.md),
      const RwEntrance(order: 4, child: _ProgressRow()),
      const SizedBox(height: RwSpace.lg),
    ],
  );
}

/// Salam beranda mengikuti jam lokal pengguna.
String _greetingFor(AppLocalizations s, int hour) =>
    switch (dayGreetingFor(hour)) {
      DayGreeting.morning => s.greetingMorning,
      DayGreeting.afternoon => s.greetingAfternoon,
      DayGreeting.evening => s.greetingEvening,
      DayGreeting.night => s.greetingNight,
    };

/// Kartu hero atletis: motif outdoor arang (`ink950`), sapaan personal, judul
/// tegas, satu CTA utama "Mulai berlari", panel cuaca interaktif, dan jadwal
/// lari terdekat (tanpa menduplikasi metrik mingguan dari kartu di bawahnya).
class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.onStart});

  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final user = ref.watch(currentProfileUserProvider);
    final name = user.displayName ?? s.runnerFallbackName;

    return ClipRRect(
      borderRadius: BorderRadius.circular(RwRadius.lg),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: RwColors.ink950),
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: CustomPaint(painter: _HeroOutdoorBackdrop()),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(RwSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: RwColors.lime500,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: RwSpace.xs),
                      Expanded(
                        child: Text(
                          s.homeGreetingLine(
                            _greetingFor(
                              s,
                              ref.watch(homeClockProvider)().hour,
                            ),
                            firstNameOf(name),
                          ),
                          style: const TextStyle(
                            fontFamily: RwType.family,
                            color: RwColors.paper200,
                            fontSize: RwType.label,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: RwSpace.md),
                  Text(
                    s.homeTitle,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      color: RwColors.paper100,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      height: 1.04,
                    ),
                  ),
                  Text(
                    s.homeAccent,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      color: RwColors.lime500,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      height: 1.04,
                    ),
                  ),
                  const SizedBox(height: RwSpace.xs),
                  Text(
                    s.homeSessionHint,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      color: RwColors.paper200,
                      fontSize: RwType.bodySmall,
                    ),
                  ),
                  const SizedBox(height: RwSpace.lg),
                  RwButton.primary(
                    label: s.homeStart,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: onStart,
                  ),
                  const SizedBox(height: RwSpace.md),
                  const _WeatherBlock(),
                  const _HeroNextReminder(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dekorasi outdoor samar di tepi kartu hero (non-interaktif, sesuai DESIGN.md
/// §9.4): siluet punggung bukit dan busur lintasan tanpa mengganggu teks.
class _HeroOutdoorBackdrop extends CustomPainter {
  const _HeroOutdoorBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final arcPaint = Paint()
      ..color = RwColors.ink800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final origin = Offset(size.width * 0.96, size.height * 0.08);
    canvas
      ..drawCircle(origin, size.width * 0.28, arcPaint)
      ..drawCircle(origin, size.width * 0.44, arcPaint);

    final slashPaint = Paint()
      ..color = RwColors.lime500.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    final slash = Path()
      ..moveTo(size.width * 0.78, 0)
      ..lineTo(size.width * 0.90, 0)
      ..lineTo(size.width * 0.72, size.height * 0.34)
      ..lineTo(size.width * 0.64, size.height * 0.34)
      ..close();
    canvas.drawPath(slash, slashPaint);

    final ridgePaint = Paint()
      ..color = RwColors.ink900.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    final ridge = Path()
      ..moveTo(size.width * 0.42, size.height)
      ..lineTo(size.width * 0.62, size.height * 0.78)
      ..lineTo(size.width * 0.74, size.height * 0.88)
      ..lineTo(size.width * 0.90, size.height * 0.68)
      ..lineTo(size.width, size.height * 0.78)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(ridge, ridgePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bagian cuaca di dalam kartu hero: memuat, izin lokasi belum aktif, gagal
/// ambil data, atau isi cuaca dalam panel arang gelap yang dapat diketuk.
class _WeatherBlock extends ConsumerWidget {
  const _WeatherBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final weather = ref.watch(weatherProvider);
    return Container(
      decoration: BoxDecoration(
        color: RwColors.ink900,
        borderRadius: BorderRadius.circular(RwRadius.md),
        border: Border.all(color: RwColors.ink700),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: RwSpace.md,
        vertical: RwSpace.sm,
      ),
      child: weather.when(
        loading: () => const _WeatherLoading(),
        error: (_, _) => Row(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: RwColors.paper200,
              size: 20,
            ),
            const SizedBox(width: RwSpace.sm),
            Expanded(
              child: Text(
                s.weatherError,
                style: const TextStyle(
                  fontFamily: RwType.family,
                  color: RwColors.paper100,
                  fontSize: RwType.bodySmall,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: RwColors.lime500),
              onPressed: () => ref.invalidate(weatherProvider),
              child: Text(s.weatherRetry),
            ),
          ],
        ),
        data: (forecast) => forecast == null
            ? Row(
                children: [
                  const Icon(
                    Icons.location_off_outlined,
                    color: RwColors.paper200,
                    size: 20,
                  ),
                  const SizedBox(width: RwSpace.sm),
                  Expanded(
                    child: Text(
                      s.weatherPermission,
                      style: const TextStyle(
                        fontFamily: RwType.family,
                        color: RwColors.paper200,
                        fontSize: RwType.bodySmall,
                      ),
                    ),
                  ),
                ],
              )
            : _WeatherContent(forecast: forecast),
      ),
    );
  }
}

/// Placeholder memuat cuaca: menyebut apa yang sedang dimuat, bukan "..." saja.
class _WeatherLoading extends StatelessWidget {
  const _WeatherLoading();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      child: Text(
        s.weatherLoading,
        style: const TextStyle(
          fontFamily: RwType.family,
          color: RwColors.paper200,
          fontSize: RwType.bodySmall,
        ),
      ),
    );
  }
}

class _WeatherContent extends StatelessWidget {
  const _WeatherContent({required this.forecast});
  final WeatherForecast forecast;

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WeatherDetailScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(RwRadius.sm),
      onTap: () => _openDetail(context),
      child: Row(
        children: [
          IconButton(
            tooltip: s.weatherDetailLink,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: () => _openDetail(context),
            icon: WeatherAnimation(
              kind: weatherKindFor(forecast.code),
              size: RwSize.touch,
              animate: true,
            ),
          ),
          const SizedBox(width: RwSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: RwColors.lime500,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        forecast.city ?? s.weatherCityUnknown,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: RwType.family,
                          color: RwColors.paper200,
                          fontSize: RwType.label,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${forecast.temperature.round()}°C · ${weatherKindLabel(s, weatherKindFor(forecast.code))}',
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    color: RwColors.paper100,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: RwColors.paper200,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Kartu ringkasan minggu: satu kartu untuk satu pertanyaan "bagaimana minggu
/// ini?". Memuat metrik, grafik dengan jawaban satu kalimat, progres target, dan
/// rentetan minggu. Setiap keadaan (memuat, kosong, gagal) punya penjelasannya.
class _WeekSection extends ConsumerWidget {
  const _WeekSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekAsync = ref.watch(weekSummaryProvider);
    return weekAsync.when(
      loading: () => const _CardSkeleton(),
      error: (_, _) => _WeekErrorCard(
        onRetry: () {
          ref.invalidate(weekSummaryProvider);
          ref.invalidate(allFinishedSessionsProvider);
        },
      ),
      data: (summary) => _WeekCard(summary: summary),
    );
  }
}

class _WeekErrorCard extends StatelessWidget {
  const _WeekErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return RwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.error_outline, size: RwSize.icon),
          ),
          const SizedBox(height: RwSpace.md),
          Semantics(
            liveRegion: true,
            child: Text(
              s.homeWeekErrorTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: RwSpace.xs),
          Text(s.homeWeekErrorBody),
          const SizedBox(height: RwSpace.lg),
          RwButton.secondary(label: s.retry, onPressed: onRetry),
        ],
      ),
    );
  }
}

/// Metrik pendamping di kartu minggu (durasi, sesi).
class _WeekMetric extends StatelessWidget {
  const _WeekMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: RwType.family,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: RwColors.mutedTextOnLight,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          fontFamily: RwType.family,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: RwColors.ink950,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    ],
  );
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.summary});

  final WeekSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final locale = s.localeName;
    final rangeLabel =
        '${DateFormat('d MMM', locale).format(summary.weekStart)} – '
        '${DateFormat('d MMM', locale).format(summary.weekEnd)}';

    if (summary.sessionCount == 0 && summary.totalDistanceMeters <= 0) {
      return RwCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WeekHeader(rangeLabel: rangeLabel),
            const SizedBox(height: RwSpace.md),
            Semantics(
              liveRegion: true,
              child: Text(
                s.homeWeekEmptyTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: RwSpace.xs),
            Text(s.homeWeekEmptyBody),
          ],
        ),
      );
    }

    final target = summary.targetSessions;
    final completed = summary.sessionCount;
    final reached = target > 0 && completed >= target;
    final ratio = target > 0 ? (completed / target).clamp(0.0, 1.0) : 0.0;
    final percent = (ratio * 100).round();
    final runDays = [
      for (final bar in summary.dailyBars)
        if (bar.distanceKm > 0) bar,
    ].length;
    final answer = s.homeChartAnswer(runDays, summary.dailyBars.length);
    final distKm = (summary.totalDistanceMeters / 1000.0).toStringAsFixed(2);

    return RwCard(
      color: reached ? RwColors.lime100 : null,
      borderColor: reached ? RwColors.lime700 : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WeekHeader(rangeLabel: rangeLabel),
          const SizedBox(height: RwSpace.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    distKm,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      fontFeatures: [FontFeature.tabularFigures()],
                      letterSpacing: -1,
                      color: RwColors.ink950,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                s.homeKmUnit,
                style: const TextStyle(
                  fontFamily: RwType.family,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: RwColors.mutedTextOnLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: RwSpace.sm),
          Row(
            children: [
              Expanded(
                child: _WeekMetric(
                  label: s.homeDuration,
                  value: formatClockDuration(summary.totalMovingTime),
                ),
              ),
              Expanded(
                child: _WeekMetric(
                  label: s.homeWeeklyGoal,
                  value: '$completed/$target',
                ),
              ),
            ],
          ),
          const SizedBox(height: RwSpace.md),
          Text(
            answer,
            style: const TextStyle(
              fontFamily: RwType.family,
              fontSize: 13,
              color: RwColors.mutedTextOnLight,
            ),
          ),
          const SizedBox(height: RwSpace.xs),
          RwBarChart(
            items: [
              for (final bar in summary.dailyBars)
                RwBarChartItem(
                  label: bar.dayLabel,
                  value: bar.distanceKm,
                  isHighlight: bar.isToday,
                ),
            ],
            height: 110,
            semanticsLabel: answer,
          ),
          const SizedBox(height: RwSpace.md),
          if (reached) ...[
            Text(
              s.homeWeeklyGoalDone,
              style: const TextStyle(
                fontFamily: RwType.family,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: RwColors.ink950,
              ),
            ),
            Text(
              s.homeWeeklyGoalDoneDetail(completed, target),
              style: const TextStyle(
                fontFamily: RwType.family,
                fontSize: 12,
                color: RwColors.mutedTextOnLight,
              ),
            ),
          ] else
            Text(
              s.homeWeeklyGoalProgress(completed, target, percent),
              style: const TextStyle(
                fontFamily: RwType.family,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: RwColors.ink950,
              ),
            ),
          const SizedBox(height: RwSpace.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(RwRadius.pill),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: RwColors.chartTrack,
              valueColor: AlwaysStoppedAnimation<Color>(
                reached ? RwColors.chartBarToday : RwColors.chartBar,
              ),
            ),
          ),
          if (summary.streakWeeks > 0) ...[
            const SizedBox(height: RwSpace.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: RwSpace.xs,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: RwColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(RwRadius.pill),
                ),
                child: Text(
                  s.homeStreak(summary.streakWeeks),
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: RwColors.ink950,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Judul kartu minggu beserta rentang tanggalnya.
class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.rangeLabel});

  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            s.homeWeekLabel,
            style: const TextStyle(
              fontFamily: RwType.family,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: RwColors.ink950,
            ),
          ),
        ),
        Text(
          rangeLabel,
          style: const TextStyle(
            fontFamily: RwType.family,
            fontSize: 12,
            color: RwColors.mutedTextOnLight,
          ),
        ),
      ],
    );
  }
}

/// Saran sesi hari ini. Aksi utama layar tetap satu (tombol di hero), jadi di
/// sini aksinya berupa tautan teks yang membuka alur persiapan sesi.
class _RecommendationCard extends ConsumerWidget {
  const _RecommendationCard({required this.onStart});

  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final recommendation = ref.watch(recommendedSessionProvider);
    return recommendation.when(
      loading: () => const _CardSkeleton(),
      // Kegagalan membaca data sesi sudah dijelaskan di kartu minggu beserta
      // tombol coba lagi, jadi kartu saran cukup disembunyikan di sini.
      error: (_, _) => const SizedBox.shrink(),
      data: (rec) => RwCard(
        padding: const EdgeInsets.all(RwSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(RwSpace.xs),
                  decoration: BoxDecoration(
                    color: RwColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(RwRadius.sm),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 16,
                    color: RwColors.ink950,
                  ),
                ),
                const SizedBox(width: RwSpace.xs),
                Expanded(
                  child: Text(
                    s.homeRecommendationTitle,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: RwColors.mutedTextOnLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: RwSpace.sm),
            Text(
              rec.title,
              style: const TextStyle(
                fontFamily: RwType.family,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: RwColors.ink950,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              rec.description,
              style: const TextStyle(
                fontFamily: RwType.family,
                fontSize: 13,
                color: RwColors.mutedTextOnLight,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: RwColors.limeTextOnLight,
                ),
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(s.homeStartRecommended),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris ringkas menuju halaman pengelolaan jadwal. Pengingat dipasang sekali di
/// awal, jadi tempatnya di bawah informasi minggu, bukan di atasnya.
class _ReminderRow extends ConsumerWidget {
  const _ReminderRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final reminders = ref.watch(runRemindersProvider).asData?.value;
    final next = (reminders == null || reminders.isEmpty)
        ? null
        : reminders.first;
    final subtitle = next == null
        ? s.reminderRowNone
        : s.reminderRowNext(
            DateFormat.yMMMd(s.localeName).add_Hm().format(next.time),
          );
    return Semantics(
      button: true,
      hint: s.reminderRowManage,
      child: RwCard(
        padding: const EdgeInsets.all(RwSpace.md),
        onTap: () => context.push('/reminders'),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: RwColors.surfaceMuted,
                borderRadius: BorderRadius.circular(RwRadius.sm),
              ),
              child: const Icon(
                Icons.alarm_outlined,
                size: 22,
                color: RwColors.ink950,
              ),
            ),
            const SizedBox(width: RwSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.reminderTitle,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: RwColors.ink950,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 12,
                      color: RwColors.mutedTextOnLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: RwColors.mutedTextOnLight,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tautan ke halaman Progress & Rekor.
class _ProgressRow extends StatelessWidget {
  const _ProgressRow();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return RwCard(
      padding: const EdgeInsets.all(RwSpace.md),
      onTap: () => context.push('/progress'),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: RwColors.surfaceMuted,
              borderRadius: BorderRadius.circular(RwRadius.sm),
            ),
            child: const Icon(
              Icons.insights_rounded,
              size: 22,
              color: RwColors.ink950,
            ),
          ),
          const SizedBox(width: RwSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.progressTitle,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: RwColors.ink950,
                  ),
                ),
                Text(
                  s.homeSeeProgress,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 12,
                    color: RwColors.mutedTextOnLight,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: RwColors.mutedTextOnLight,
          ),
        ],
      ),
    );
  }
}

/// Skeleton kartu: balok diam tanpa animasi berulang.
class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 14,
            width: 120,
            decoration: BoxDecoration(
              color: RwColors.borderCard,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: RwSpace.md),
          Container(
            height: 32,
            width: 80,
            decoration: BoxDecoration(
              color: RwColors.borderCard,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    ),
  );
}

class _HeroNextReminder extends ConsumerWidget {
  const _HeroNextReminder();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(runRemindersProvider).asData?.value;
    final now = DateTime.now();
    final upcoming = reminders?.where((item) => item.time.isAfter(now)).toList()
      ?..sort((a, b) => a.time.compareTo(b.time));
    if (upcoming == null || upcoming.isEmpty) return const SizedBox.shrink();
    final s = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: RwSpace.sm),
      child: Material(
        color: RwColors.ink900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RwRadius.md),
          side: const BorderSide(color: RwColors.ink700),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(RwRadius.md),
          onTap: () => context.push('/reminders'),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: RwSpace.md,
              vertical: RwSpace.sm,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.alarm_outlined,
                  color: RwColors.lime500,
                  size: 20,
                ),
                const SizedBox(width: RwSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.heroNextReminder,
                        style: const TextStyle(
                          fontFamily: RwType.family,
                          color: RwColors.paper200,
                          fontSize: RwType.label,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat.yMMMd(s.localeName)
                            .add_Hm()
                            .format(upcoming.first.time),
                        style: const TextStyle(
                          fontFamily: RwType.family,
                          color: RwColors.paper100,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: RwColors.paper200,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
