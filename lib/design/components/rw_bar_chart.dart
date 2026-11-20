import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';
import '../tokens/rw_tokens.dart';

class RwBarChartItem {
  const RwBarChartItem({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });
  final String label;
  final double value;
  final bool isHighlight;
}

class RwBarChart extends StatelessWidget {
  const RwBarChart({
    required this.items,
    this.height = 130,
    this.semanticsLabel,
    this.barColor = RwColors.chartBar,
    this.highlightColor = RwColors.chartBarToday,
    this.emptyBarColor = RwColors.chartTrack,
    super.key,
  });

  final List<RwBarChartItem> items;
  final double height;

  /// Ringkasan teks grafik untuk pembaca layar; grafik kanvas tidak dapat
  /// dibaca tanpa label ini.
  final String? semanticsLabel;
  final Color barColor;
  final Color highlightColor;
  final Color emptyBarColor;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    if (items.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            s.chartEmpty,
            style: const TextStyle(
              fontFamily: RwType.family,
              fontSize: 12,
              color: RwColors.mutedTextOnLight,
            ),
          ),
        ),
      );
    }

    var maxY = 1.0;
    for (final item in items) {
      if (item.value > maxY) maxY = item.value;
    }
    // Tambahkan 15% headroom pada puncak grafik
    maxY = (maxY * 1.15).ceilToDouble();

    return Semantics(
      label: semanticsLabel ?? s.chartLabel,
      container: true,
      child: SizedBox(
        height: height,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            minY: 0,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            alignment: BarChartAlignment.spaceAround,
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= items.length) {
                      return const SizedBox.shrink();
                    }
                    final item = items[idx];
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: RwType.family,
                          fontSize: 10,
                          fontWeight: item.isHighlight
                              ? FontWeight.w900
                              : FontWeight.w700,
                          color: item.isHighlight
                              ? RwColors.ink950
                              : RwColors.mutedTextOnLight,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => RwColors.ink950,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final item = items[group.x];
                  return BarTooltipItem(
                    '${item.label}\n',
                    const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: RwColors.paper200,
                    ),
                    children: [
                      TextSpan(
                        text: s.chartTooltipKm(item.value),
                        style: const TextStyle(
                          fontFamily: RwType.family,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: RwColors.lime500,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            barGroups: [
              for (var i = 0; i < items.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: items[i].value > 0 ? items[i].value : 0.08,
                      color: items[i].value > 0
                          ? (items[i].isHighlight ? highlightColor : barColor)
                          : emptyBarColor,
                      width: items.length <= 7 ? 16 : 10,
                      borderRadius: BorderRadius.circular(4),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: RwColors.chartTrackSoft,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
