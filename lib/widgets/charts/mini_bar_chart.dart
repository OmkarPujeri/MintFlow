import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme.dart';

class BarDatum {
  const BarDatum({required this.label, required this.value});

  final String label;
  final double value;
}

/// Rounded vertical bar chart used for spend-per-campaign.
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({super.key, required this.data, this.height = 200});

  final List<BarDatum> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(height: height);

    final maxY =
        data.map((d) => d.value).fold<double>(0, (m, v) => v > m ? v : m) *
            1.25;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 1 : maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY == 0 ? 1 : maxY / 3,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.lineSoft, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
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
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  final label = data[i].label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label.length > 8 ? '${label.substring(0, 7)}…' : label,
                      style: const TextStyle(
                        color: AppColors.faint,
                        fontSize: 10.5,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.ink,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                'Rs. ${rod.toY.round()}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].value,
                    width: 20,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [AppColors.mint, AppColors.mintGlow],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
