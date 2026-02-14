import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/chart_data.dart';

/// Manhattan chart showing runs scored per over as a bar chart.
///
/// Wicket overs are highlighted in a different color.
class ManhattanChart extends StatelessWidget {
  const ManhattanChart({
    super.key,
    required this.data,
    this.teamColor = const Color(0xFF1565C0),
    this.wicketColor = const Color(0xFFC62828),
  });

  final InningsChartData data;
  final Color teamColor;
  final Color wicketColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.manhattan.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxRuns = data.manhattan
        .fold<int>(0, (max, o) => o.runs > max ? o.runs : max)
        .toDouble();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Runs Per Over — ${data.teamName} Innings',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildLegend(theme),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxRuns + 2).ceilToDouble(),
                barGroups: data.manhattan.map((over) {
                  return BarChartGroupData(
                    x: over.overNumber,
                    barRods: [
                      BarChartRodData(
                        toY: over.runs.toDouble(),
                        color: over.hasWicket ? wicketColor : teamColor,
                        width: 12,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(2),
                          topRight: Radius.circular(2),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final over = value.toInt();
                        // Show every 5th label: 1, 5, 10, 15, 20
                        if (over == 1 || over % 5 == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$over',
                              style: theme.textTheme.labelSmall,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 22,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == meta.min) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          '${value.toInt()}',
                          style: theme.textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxRuns > 10 ? 5 : 2,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFE0E0E0),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        'Over ${group.x}: ${rod.toY.toInt()} runs',
                        theme.textTheme.labelSmall!.copyWith(
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Row(
      children: [
        _legendItem(theme, teamColor, 'Runs'),
        const SizedBox(width: 16),
        _legendItem(theme, wicketColor, 'Wicket Over'),
      ],
    );
  }

  Widget _legendItem(ThemeData theme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
