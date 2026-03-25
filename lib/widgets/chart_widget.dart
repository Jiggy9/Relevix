import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/dataset.dart';

class ChartWidget extends StatelessWidget {
  final Dataset dataset;
  final String xColumn;
  final String yColumn;

  const ChartWidget({
    super.key,
    required this.dataset,
    required this.xColumn,
    required this.yColumn,
  });

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpots();

    if (spots.isEmpty) {
      return Card(
        child: Center(
          child: Text(
            'No data to display',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textLight,
                ),
          ),
        ),
      );
    }

    final xValues = spots.map((s) => s.x).toList();
    final yValues = spots.map((s) => s.y).toList();
    final minX = xValues.reduce((a, b) => a < b ? a : b);
    final maxX = xValues.reduce((a, b) => a > b ? a : b);
    final minY = yValues.reduce((a, b) => a < b ? a : b);
    final maxY = yValues.reduce((a, b) => a > b ? a : b);

    final xPadding = (maxX - minX) * 0.05;
    final yPadding = (maxY - minY) * 0.05;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 12),
              child: Text(
                '$yColumn vs $xColumn',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryBrown,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Expanded(
              child: LineChart(
                LineChartData(
                  minX: minX - xPadding,
                  maxX: maxX + xPadding,
                  minY: minY - yPadding,
                  maxY: maxY + yPadding,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.2,
                      color: AppTheme.primaryBrown,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: spots.length <= 100,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 3,
                          color: AppTheme.surfaceWhite,
                          strokeWidth: 2,
                          strokeColor: AppTheme.primaryBrown,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primaryBrown.withAlpha(20),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text(
                        xColumn,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.min || value == meta.max) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _formatAxisValue(value),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textLight,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(
                        yColumn,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.min || value == meta.max) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              _formatAxisValue(value),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textLight,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: null,
                    verticalInterval: null,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.accentTan.withAlpha(51),
                      strokeWidth: 0.8,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: AppTheme.accentTan.withAlpha(51),
                      strokeWidth: 0.8,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(
                        color: AppTheme.accentTan.withAlpha(102),
                      ),
                      bottom: BorderSide(
                        color: AppTheme.accentTan.withAlpha(102),
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (LineBarSpot _) => AppTheme.darkBrown,
                      tooltipRoundedRadius: 10,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '$xColumn: ${spot.x.toStringAsFixed(4)}\n'
                            '$yColumn: ${spot.y.toStringAsFixed(4)}',
                            const TextStyle(
                              color: AppTheme.backgroundBeige,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    final spots = <FlSpot>[];
    for (final row in dataset.rows) {
      final x = row[xColumn];
      final y = row[yColumn];
      if (x != null && y != null && !x.isNaN && !y.isNaN) {
        spots.add(FlSpot(x, y));
      }
    }
    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }

  String _formatAxisValue(double value) {
    if (value.abs() >= 1000) {
      return value.toStringAsFixed(0);
    } else if (value.abs() >= 1) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(3);
    }
  }
}
