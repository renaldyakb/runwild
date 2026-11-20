import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

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
            error: (_, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.weatherError),
                  TextButton(
                    onPressed: () => ref.invalidate(weatherProvider),
                    child: Text(s.weatherRetry),
                  ),
                ],
              ),
            ),
            data: (data) {
              if (data == null) return Center(child: Text(s.weatherPermission));
              return RwPage(
                children: [
                  Text(
                    data.city ?? s.weatherCityUnknown,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: RwSpace.lg),
                  Row(
                    children: [
                      _WeatherIcon(code: data.code, large: true),
                      const SizedBox(width: RwSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${data.temperature.round()}°C',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            Text(
                              weatherKindLabel(s, weatherKindFor(data.code)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: RwSpace.lg),
                  Text(
                    s.weatherHourlyTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: RwSpace.xs),
                  Text(s.weatherForecastNote),
                  const SizedBox(height: RwSpace.lg),
                  for (final hour in data.hourly)
                    Padding(
                      padding: const EdgeInsets.only(bottom: RwSpace.md),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                DateFormat.Hm(s.localeName).format(hour.time),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(width: RwSpace.md),
                              _WeatherIcon(code: hour.code),
                              const SizedBox(width: RwSpace.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      weatherKindLabel(
                                        s,
                                        weatherKindFor(hour.code),
                                      ),
                                    ),
                                    Text(
                                      '${s.weatherChance}: ${hour.probability}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                        ],
                      ),
                    ),
                  Text(s.weatherSource),
                  Text(s.weatherLocationSource),
                ],
              );
            },
          ),
    );
  }
}

class _WeatherIcon extends StatelessWidget {
  const _WeatherIcon({required this.code, this.large = false});
  final int code;
  final bool large;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(RwSpace.xxs),
    decoration: BoxDecoration(
      color: RwColors.ink950,
      borderRadius: BorderRadius.circular(RwRadius.sm),
    ),
    child: WeatherAnimation(
      kind: weatherKindFor(code),
      size: large ? RwSize.pause : RwSize.touch,
      animate: large,
    ),
  );
}
