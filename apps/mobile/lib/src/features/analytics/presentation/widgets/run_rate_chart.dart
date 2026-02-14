import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/chart_data.dart';

/// Run Rate chart showing runs per over for both innings as line charts.
///
/// Includes horizontal reference lines at common run rate thresholds.
class RunRateChart extends StatelessWidget {
  const RunRateChart({
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

    if (first.runRate.isEmpty && second.runRate.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final maxRate = _maxRunRate();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Run Rate Per Over',
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
                maxY: (maxRate + 3).ceilToDouble().clamp(15, 36),
                minY: 0,
                lineBarsData: [
                  _buildLine(first.runRate, firstInningsColor, false),
                  _buildLine(second.runRate, secondInningsColor, true),
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
                      reservedSize: 28,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) {
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
                  horizontalInterval: 3,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFE0E0E0),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    _referenceLine(6, theme),
                    _referenceLine(9, theme),
                    _referenceLine(12, theme),
                  ],
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final isFirst = spot.barIndex == 0;
                        return LineTooltipItem(
                          'Over ${spot.x.toInt()}: ${spot.y.toStringAsFixed(1)}',
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
    List<RunRateDataPoint> points,
    Color color,
    bool isDashed,
  ) {
    return LineChartBarData(
      spots: points
          .map((p) => FlSpot(p.overNumber.toDouble(), p.runRate))
          .toList(),
      isCurved: false,
      color: color,
      barWidth: 2,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 0,
        ),
      ),
      dashArray: isDashed ? [8, 4] : null,
      belowBarData: BarAreaData(show: false),
    );
  }

  HorizontalLine _referenceLine(double y, ThemeData theme) {
    return HorizontalLine(
      y: y,
      color: const Color(0xFFBDBDBD),
      strokeWidth: 0.5,
      dashArray: [4, 4],
      label: HorizontalLineLabel(
        show: true,
        alignment: Alignment.topRight,
        style: theme.textTheme.labelSmall?.copyWith(
          color: const Color(0xFF9E9E9E),
          fontSize: 9,
        ),
        labelResolver: (line) => '${y.toInt()}',
      ),
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
            '${first.teamName} Run Rate',
            isDashed: false,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _legendItem(
            theme,
            secondInningsColor,
            '${second.teamName} Run Rate',
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

  double _maxRunRate() {
    double max = 0;
    for (final p in data.firstInnings.runRate) {
      if (p.runRate > max) max = p.runRate;
    }
    for (final p in data.secondInnings.runRate) {
      if (p.runRate > max) max = p.runRate;
    }
    return max;
  }
}
