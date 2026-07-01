import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme.dart';

class DonutSlice {
  const DonutSlice({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;
}

/// Donut chart with a centre total and a compact legend on the side.
class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.slices, this.centerLabel = 'Total'});

  final List<DonutSlice> slices;
  final String centerLabel;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<int>(0, (sum, s) => sum + s.value);

    return Row(
      children: [
        SizedBox(
          width: 132,
          height: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                  startDegreeOffset: -90,
                  sections: total == 0
                      ? [
                          PieChartSectionData(
                            value: 1,
                            color: AppColors.lineSoft,
                            radius: 16,
                            showTitle: false,
                          ),
                        ]
                      : [
                          for (final slice in slices)
                            if (slice.value > 0)
                              PieChartSectionData(
                                value: slice.value.toDouble(),
                                color: slice.color,
                                radius: 16,
                                showTitle: false,
                              ),
                        ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    centerLabel,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final slice in slices)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: slice.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          slice.label,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '${slice.value}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
