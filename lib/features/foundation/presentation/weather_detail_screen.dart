import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_card.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/weather_kind.dart';
import '../application/weather_service.dart';
import 'weather_animation.dart';

class WeatherDetailScreen extends ConsumerWidget {
  const WeatherDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.weatherDetailTitle)),
      body: ref
          .watch(weatherProvider)
          .when(
            loading: () => Center(child: Text(s.weatherLoading)),
            error: (_, _) => RwPage(
              children: [
                RwCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(
                          Icons.cloud_off_rounded,
                          size: RwSize.icon,
                          color: RwColors.ink950,
                        ),
                      ),
                      const SizedBox(height: RwSpace.sm),
                      Text(s.weatherError),
                      const SizedBox(height: RwSpace.md),
                      RwButton.secondary(
                        label: s.weatherRetry,
                        onPressed: () => ref.invalidate(weatherProvider),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            data: (data) {
              if (data == null) {
                return RwPage(
                  children: [RwCard(child: Text(s.weatherPermission))],
                );
              }
              return RwPage(
                children: [
                  // ── Hero Kondisi Saat Ini ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(RwSpace.lg),
                    decoration: BoxDecoration(
                      color: RwColors.ink950,
                      borderRadius: BorderRadius.circular(RwRadius.lg),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: RwColors.lime500,
                            ),
                            const SizedBox(width: RwSpace.xxs),
                            Expanded(
                              child: Text(
                                data.city ?? s.weatherCityUnknown,
                                style: const TextStyle(
                                  fontFamily: RwType.family,
                                  color: RwColors.paper200,
                                  fontSize: RwType.bodySmall,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: RwSpace.md),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(RwSpace.xs),
                              decoration: BoxDecoration(
                                color: RwColors.ink900,
                                borderRadius: BorderRadius.circular(
                                  RwRadius.md,
                                ),
                                border: Border.all(color: RwColors.ink700),
                              ),
                              child: WeatherAnimation(
                                kind: weatherKindFor(data.code),
                                size: RwSize.pause,
                                animate: true,
                              ),
                            ),
                            const SizedBox(width: RwSpace.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${data.temperature.round()}°C',
                                    style: const TextStyle(
                                      fontFamily: RwType.family,
                                      color: RwColors.paper100,
                                      fontSize: 44,
                                      fontWeight: FontWeight.w900,
                                      height: 1.0,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: RwSpace.xxs),
                                  Text(
                                    weatherKindLabel(
                                      s,
                                      weatherKindFor(data.code),
                                    ),
                                    style: const TextStyle(
                                      fontFamily: RwType.family,
                                      color: RwColors.lime500,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: RwSpace.md),
                        Text(
                          s.weatherForecastNote,
                          style: const TextStyle(
                            fontFamily: RwType.family,
                            color: RwColors.paper200,
                            fontSize: RwType.label,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: RwSpace.lg),

                  // ── Prakiraan 12 Jam ──────────────────────────────────────
                  Text(
                    s.weatherHourlyTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: RwSpace.sm),
                  RwCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: RwSpace.md,
                      vertical: RwSpace.xs,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < data.hourly.length; i++) ...[
                          _HourlyRow(hour: data.hourly[i]),
                          if (i < data.hourly.length - 1)
                            const Divider(
                              color: RwColors.borderCard,
                              height: 1,
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: RwSpace.md),
                  Text(
                    s.weatherSource,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: RwColors.mutedTextOnLight),
                  ),
                  Text(
                    s.weatherLocationSource,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: RwColors.mutedTextOnLight),
                  ),
                ],
              );
            },
          ),
    );
  }
}

class _HourlyRow extends StatelessWidget {
  const _HourlyRow({required this.hour});
  final HourlyWeather hour;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final wet = isWetHour(hour.code, hour.probability);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RwSpace.sm),
      child: Row(
        children: [
          Text(
            DateFormat.Hm(s.localeName).format(hour.time),
            style: const TextStyle(
              fontFamily: RwType.family,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: RwColors.ink950,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: RwSpace.md),
          Container(
            padding: const EdgeInsets.all(RwSpace.xxs),
            decoration: BoxDecoration(
              color: RwColors.ink950,
              borderRadius: BorderRadius.circular(RwRadius.sm),
            ),
            child: WeatherAnimation(
              kind: weatherKindFor(hour.code),
              size: 36,
              animate: false,
            ),
          ),
          const SizedBox(width: RwSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weatherKindLabel(s, weatherKindFor(hour.code)),
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: RwColors.ink950,
                  ),
                ),
                Text(
                  '${s.weatherChance}: ${hour.probability}%',
                  style: TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 12,
                    fontWeight: wet ? FontWeight.w700 : FontWeight.w500,
                    color: wet ? RwColors.lime700 : RwColors.mutedTextOnLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
