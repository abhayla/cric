import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/chart_data.dart';

/// Worm chart showing cumulative runs for both innings as line charts.
///
/// First innings: solid blue line. Second innings: dashed red line.
class WormChart extends StatelessWidget {
  const WormChart({
    super.key,
    required this.data,
    this.firstInningsColor = const Color(0xFF1565C0),
    this.secondInningsColor = const Color(0xFFC62828),
  });

  final MatchChartData data;
  final Color firstInningsColor;
  final Color secondInningsColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = data.firstInnings;
    final second = data.secondInnings;

    if (first.worm.length <= 1 && second.worm.length <= 1) {
      return const Center(child: Text('No data available'));
    }

    final maxRuns = _maxCumulativeRuns();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cumulative Runs Comparison',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildLegend(theme),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                maxY: (maxRuns + 10).ceilToDouble(),
                minY: 0,
                lineBarsData: [
                  _buildLine(first.worm, firstInningsColor, false),
                  _buildLine(second.worm, secondInningsColor, true),
                ],
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max && value % 5 != 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${value.toInt()}',
                            style: theme.textTheme.labelSmall,
                          ),
                        );
                      },
                      reservedSize: 22,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
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
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFE0E0E0),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final isFirst = spot.barIndex == 0;
                        return LineTooltipItem(
                          'Over ${spot.x.toInt()}: ${spot.y.toInt()} runs',
                          TextStyle(
                            color: isFirst
                                ? firstInningsColor
                                : secondInningsColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
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

  LineChartBarData _buildLine(
    List<WormDataPoint> points,
    Color color,
    bool isDashed,
  ) {
    return LineChartBarData(
      spots: points
          .map((p) => FlSpot(p.overNumber.toDouble(), p.cumulativeRuns.toDouble()))
          .toList(),
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      dashArray: isDashed ? [8, 4] : null,
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    final first = data.firstInnings;
    final second = data.secondInnings;

    return Row(
      children: [
        Expanded(
          child: _legendItem(
            theme,
            firstInningsColor,
            '${first.teamName} — ${first.scoreDisplay}',
            isDashed: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _legendItem(
            theme,
            secondInningsColor,
            '${second.teamName} — ${second.scoreDisplay}',
            isDashed: true,
          ),
        ),
      ],
    );
  }

  Widget _legendItem(
    ThemeData theme,
    Color color,
    String label, {
    required bool isDashed,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 3,
          child: isDashed
              ? Row(
                  children: [
                    Container(width: 6, height: 3, color: color),
                    const SizedBox(width: 4),
                    Container(width: 6, height: 3, color: color),
                  ],
                )
              : Container(color: color),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  double _maxCumulativeRuns() {
    double max = 0;
    for (final p in data.firstInnings.worm) {
      if (p.cumulativeRuns > max) max = p.cumulativeRuns.toDouble();
    }
    for (final p in data.secondInnings.worm) {
      if (p.cumulativeRuns > max) max = p.cumulativeRuns.toDouble();
    }
    return max;
  }
}
