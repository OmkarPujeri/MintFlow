import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/insights.dart';
import '../../theme.dart';
import 'chart_placeholder.dart';

/// Smooth area line chart for a rewarded-view / completion trend.
class TrendAreaChart extends StatelessWidget {
  const TrendAreaChart({super.key, required this.points, this.height = 200});

  final List<TimeSeriesPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Empty OR all-zero (the repo always emits a full series) → placeholder
    // instead of a flat line pinned to the axis.
    if (points.isEmpty || !points.any((p) => p.value > 0)) {
      return ChartPlaceholder(
        icon: Icons.show_chart,
        message: 'No activity in this period yet.',
        height: height,
      );
    }

    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value),
    ];
    final maxY = points
            .map((p) => p.value)
            .fold<double>(0, (m, v) => v > m ? v : m) *
        1.25;
    final interval = (points.length / 4).ceilToDouble().clamp(1.0, 999.0);

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY == 0 ? 1 : maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY == 0 ? 1 : maxY / 3,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.lineSoft, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval,
                reservedSize: 26,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final date = points[i].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(
                        color: AppColors.faint,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.ink,
              getTooltipItems: (spots) => spots
                  .map(
                    (s) => LineTooltipItem(
                      s.y.round().toString(),
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.32,
              barWidth: 3,
              gradient: const LinearGradient(
                colors: [AppColors.mintGlow, AppColors.mint],
              ),
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.mint.withValues(alpha: 0.22),
                    AppColors.mint.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
