import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/dataset.dart';

class ChartWidget extends StatefulWidget {
  final Dataset dataset;
  final String xColumn;
  final List<String> yColumns;

  const ChartWidget({
    super.key,
    required this.dataset,
    required this.xColumn,
    required this.yColumns,
  });

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  late Set<String> _enabledColumns;
  // Global X data bounds
  double? _minX, _maxX;
  // Current X view window (only X is user-controlled)
  double? _viewMinX, _viewMaxX;

  static const List<Color> _lineColors = [
    Color(0xFF5C3D2E),
    Color(0xFF1976D2),
    Color(0xFFE65100),
    Color(0xFF2E7D32),
    Color(0xFF8E24AA),
    Color(0xFFC62828),
    Color(0xFF00838F),
    Color(0xFFFF8F00),
    Color(0xFF4527A0),
    Color(0xFF558B2F),
    Color(0xFFAD1457),
    Color(0xFF00695C),
  ];

  @override
  void initState() {
    super.initState();
    _enabledColumns = Set<String>.from(widget.yColumns);
    _calculateDataBounds();
  }

  @override
  void didUpdateWidget(ChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.xColumn != widget.xColumn ||
        oldWidget.yColumns != widget.yColumns) {
      _enabledColumns = Set<String>.from(widget.yColumns);
      _calculateDataBounds();
      _resetView();
    }
  }

  void _calculateDataBounds() {
    double minX = double.infinity, maxX = -double.infinity;
    for (final col in widget.yColumns) {
      for (final row in widget.dataset.rows) {
        final x = row[widget.xColumn];
        final y = row[col];
        if (x != null && y != null && !x.isNaN && !y.isNaN) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
        }
      }
    }
    if (minX.isFinite && maxX.isFinite) {
      final xPad = (maxX - minX) * 0.02;
      _minX = minX - xPad;
      _maxX = maxX + xPad;
      _viewMinX = _minX;
      _viewMaxX = _maxX;
    }
  }

  /// Compute Y bounds from data points visible in the current X window.
  (double, double) _computeYBounds() {
    double minY = double.infinity, maxY = -double.infinity;
    for (final col in _enabledColumns) {
      for (final row in widget.dataset.rows) {
        final x = row[widget.xColumn];
        final y = row[col];
        if (x != null && y != null && !x.isNaN && !y.isNaN &&
            x >= _viewMinX! && x <= _viewMaxX!) {
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    if (!minY.isFinite || !maxY.isFinite || minY == maxY) {
      // Fallback: use all data or add small range
      return (minY.isFinite ? minY - 1 : 0, maxY.isFinite ? maxY + 1 : 1);
    }
    final yPad = (maxY - minY) * 0.08;
    return (minY - yPad, maxY + yPad);
  }

  void _resetView() {
    setState(() {
      _viewMinX = _minX;
      _viewMaxX = _maxX;
    });
  }

  void _toggleColumn(String column) {
    setState(() {
      if (_enabledColumns.contains(column)) {
        if (_enabledColumns.length > 1) {
          _enabledColumns.remove(column);
        }
      } else {
        _enabledColumns.add(column);
      }
    });
  }

  Color _colorForColumn(String column) {
    final index = widget.yColumns.indexOf(column);
    return _lineColors[index % _lineColors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (_minX == null || _maxX == null) {
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

    final (viewMinY, viewMaxY) = _computeYBounds();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Data vs ${widget.xColumn}',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.primaryBrown,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    tooltip: 'Reset view',
                    color: AppTheme.textLight,
                    onPressed: _resetView,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen_rounded, size: 20),
                    tooltip: 'Full screen',
                    color: AppTheme.textLight,
                    onPressed: () => _openFullScreen(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    _handleScroll(event);
                  }
                },
                child: GestureDetector(
                  onScaleUpdate: (details) => _handleZoomPan(details),
                  child: LineChart(
                    LineChartData(
                      minX: _viewMinX,
                      maxX: _viewMaxX,
                      minY: viewMinY,
                      maxY: viewMaxY,
                      clipData: const FlClipData.all(),
                      lineBarsData: _buildLineBars(),
                      titlesData: _buildTitles(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppTheme.accentTan.withAlpha(40),
                          strokeWidth: 0.6,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: AppTheme.accentTan.withAlpha(40),
                          strokeWidth: 0.6,
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          left: BorderSide(
                              color: AppTheme.accentTan.withAlpha(102)),
                          bottom: BorderSide(
                              color: AppTheme.accentTan.withAlpha(102)),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (LineBarSpot _) =>
                              AppTheme.darkBrown,
                          tooltipRoundedRadius: 10,
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          maxContentWidth: 200,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final colName = _enabledColumns
                                  .elementAt(spot.barIndex);
                              final color = _colorForColumn(colName);
                              return LineTooltipItem(
                                '$colName: ${spot.y.toStringAsFixed(4)}',
                                TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
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
              ),
            ),
            const SizedBox(height: 8),
            _buildToggleChips(),
          ],
        ),
      ),
    );
  }

  List<LineChartBarData> _buildLineBars() {
    final bars = <LineChartBarData>[];
    for (final col in _enabledColumns) {
      final spots = _buildSpots(col);
      if (spots.isEmpty) continue;
      final color = _colorForColumn(col);
      bars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.15,
          color: color,
          barWidth: 1.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }
    return bars;
  }

  List<FlSpot> _buildSpots(String yColumn) {
    final spots = <FlSpot>[];
    for (final row in widget.dataset.rows) {
      final x = row[widget.xColumn];
      final y = row[yColumn];
      if (x != null && y != null && !x.isNaN && !y.isNaN) {
        spots.add(FlSpot(x, y));
      }
    }
    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }

  FlTitlesData _buildTitles() {
    return FlTitlesData(
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      bottomTitles: AxisTitles(
        axisNameWidget: Text(
          widget.xColumn,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          getTitlesWidget: (value, meta) {
            if (value == meta.min || value == meta.max) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatAxisValue(value),
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textLight,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 48,
          getTitlesWidget: (value, meta) {
            if (value == meta.min || value == meta.max) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                _formatAxisValue(value),
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textLight,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildToggleChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: widget.yColumns.map((col) {
        final isEnabled = _enabledColumns.contains(col);
        final color = _colorForColumn(col);
        return GestureDetector(
          onTap: () => _toggleColumn(col),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isEnabled ? color.withAlpha(25) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isEnabled ? color : AppTheme.accentTan.withAlpha(76),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? color
                        : AppTheme.accentTan.withAlpha(76),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  col,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isEnabled ? color : AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleZoomPan(ScaleUpdateDetails details) {
    if (_viewMinX == null || _viewMaxX == null) {
      return;
    }
    setState(() {
      final xRange = _viewMaxX! - _viewMinX!;
      final fullXRange = _maxX! - _minX!;
      double newMinX = _viewMinX!;
      double newMaxX = _viewMaxX!;

      // Pinch zoom: only affects X axis
      if (details.scale != 1.0) {
        final zoomFactor = 1.0 + (1.0 - details.scale) * 0.02;
        final xCenter = (newMinX + newMaxX) / 2;
        final newXRange =
            (xRange * zoomFactor).clamp(fullXRange * 0.05, fullXRange * 2.0);
        newMinX = xCenter - newXRange / 2;
        newMaxX = xCenter + newXRange / 2;
      }

      // Pan: only affects X axis
      final dx = -details.focalPointDelta.dx * xRange * 0.002;
      newMinX += dx;
      newMaxX += dx;

      // Clamp X
      final xPadLimit = fullXRange * 0.1;
      if (newMinX < _minX! - xPadLimit) {
        newMaxX += (_minX! - xPadLimit) - newMinX;
        newMinX = _minX! - xPadLimit;
      }
      if (newMaxX > _maxX! + xPadLimit) {
        newMinX -= newMaxX - (_maxX! + xPadLimit);
        newMaxX = _maxX! + xPadLimit;
      }

      _viewMinX = newMinX;
      _viewMaxX = newMaxX;
    });
  }

  void _handleScroll(PointerScrollEvent event) {
    if (_viewMinX == null || _viewMaxX == null) {
      return;
    }
    setState(() {
      final xRange = _viewMaxX! - _viewMinX!;
      final fullXRange = _maxX! - _minX!;
      final zoomFactor = event.scrollDelta.dy > 0 ? 1.1 : 0.9;
      final xCenter = (_viewMinX! + _viewMaxX!) / 2;
      final newXRange =
          (xRange * zoomFactor).clamp(fullXRange * 0.05, fullXRange * 2.0);
      _viewMinX = xCenter - newXRange / 2;
      _viewMaxX = xCenter + newXRange / 2;
    });
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullScreenChart(
          dataset: widget.dataset,
          xColumn: widget.xColumn,
          yColumns: widget.yColumns,
          enabledColumns: Set<String>.from(_enabledColumns),
        ),
      ),
    );
  }

  String _formatAxisValue(double value) {
    if (value.abs() >= 10000) {
      return value.toStringAsExponential(1);
    } else if (value.abs() >= 1000) {
      return value.toStringAsFixed(0);
    } else if (value.abs() >= 1) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(3);
    }
  }
}

// ─────────────────────────────────────────────
//  Full Screen Chart
// ─────────────────────────────────────────────

class _FullScreenChart extends StatefulWidget {
  final Dataset dataset;
  final String xColumn;
  final List<String> yColumns;
  final Set<String> enabledColumns;

  const _FullScreenChart({
    required this.dataset,
    required this.xColumn,
    required this.yColumns,
    required this.enabledColumns,
  });

  @override
  State<_FullScreenChart> createState() => _FullScreenChartState();
}

class _FullScreenChartState extends State<_FullScreenChart> {
  late Set<String> _enabledColumns;
  double? _minX, _maxX;
  double? _viewMinX, _viewMaxX;

  static const List<Color> _lineColors = [
    Color(0xFF5C3D2E),
    Color(0xFF1976D2),
    Color(0xFFE65100),
    Color(0xFF2E7D32),
    Color(0xFF8E24AA),
    Color(0xFFC62828),
    Color(0xFF00838F),
    Color(0xFFFF8F00),
    Color(0xFF4527A0),
    Color(0xFF558B2F),
    Color(0xFFAD1457),
    Color(0xFF00695C),
  ];

  @override
  void initState() {
    super.initState();
    _enabledColumns = Set<String>.from(widget.enabledColumns);
    _calculateBounds();
  }

  void _calculateBounds() {
    double minX = double.infinity, maxX = -double.infinity;
    for (final col in widget.yColumns) {
      for (final row in widget.dataset.rows) {
        final x = row[widget.xColumn];
        final y = row[col];
        if (x != null && y != null && !x.isNaN && !y.isNaN) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
        }
      }
    }
    if (minX.isFinite) {
      final xP = (maxX - minX) * 0.02;
      _minX = minX - xP;
      _maxX = maxX + xP;
      _resetView();
    }
  }

  (double, double) _computeYBounds() {
    double minY = double.infinity, maxY = -double.infinity;
    for (final col in _enabledColumns) {
      for (final row in widget.dataset.rows) {
        final x = row[widget.xColumn];
        final y = row[col];
        if (x != null && y != null && !x.isNaN && !y.isNaN &&
            x >= _viewMinX! && x <= _viewMaxX!) {
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    if (!minY.isFinite || !maxY.isFinite || minY == maxY) {
      return (minY.isFinite ? minY - 1 : 0, maxY.isFinite ? maxY + 1 : 1);
    }
    final yPad = (maxY - minY) * 0.08;
    return (minY - yPad, maxY + yPad);
  }

  void _resetView() {
    setState(() {
      _viewMinX = _minX;
      _viewMaxX = _maxX;
    });
  }

  void _toggleColumn(String col) {
    setState(() {
      if (_enabledColumns.contains(col)) {
        if (_enabledColumns.length > 1) {
          _enabledColumns.remove(col);
        }
      } else {
        _enabledColumns.add(col);
      }
    });
  }

  Color _colorFor(String col) =>
      _lineColors[widget.yColumns.indexOf(col) % _lineColors.length];

  @override
  Widget build(BuildContext context) {
    final (viewMinY, viewMaxY) = _computeYBounds();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBeige,
      appBar: AppBar(
        title: Text('Data vs ${widget.xColumn}'),
        leading: IconButton(
          icon: const Icon(Icons.fullscreen_exit_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset view',
            onPressed: _resetView,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      _handleScroll(event);
                    }
                  },
                  child: GestureDetector(
                    onScaleUpdate: _handleZoomPan,
                    child: LineChart(
                      LineChartData(
                        minX: _viewMinX,
                        maxX: _viewMaxX,
                        minY: viewMinY,
                        maxY: viewMaxY,
                        clipData: const FlClipData.all(),
                        lineBarsData: _buildBars(),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            axisNameWidget: Text(widget.xColumn,
                                style: const TextStyle(
                                    fontSize: 11, color: AppTheme.textLight)),
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (v, meta) {
                                if (v == meta.min || v == meta.max) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(_fmt(v),
                                      style: const TextStyle(
                                          fontSize: 9,
                                          color: AppTheme.textLight)),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 48,
                              getTitlesWidget: (v, meta) {
                                if (v == meta.min || v == meta.max) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Text(_fmt(v),
                                      style: const TextStyle(
                                          fontSize: 9,
                                          color: AppTheme.textLight)),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          getDrawingHorizontalLine: (v) => FlLine(
                              color: AppTheme.accentTan.withAlpha(40),
                              strokeWidth: 0.6),
                          getDrawingVerticalLine: (v) => FlLine(
                              color: AppTheme.accentTan.withAlpha(40),
                              strokeWidth: 0.6),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            left: BorderSide(
                                color: AppTheme.accentTan.withAlpha(102)),
                            bottom: BorderSide(
                                color: AppTheme.accentTan.withAlpha(102)),
                          ),
                        ),
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => AppTheme.darkBrown,
                            tooltipRoundedRadius: 10,
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            getTooltipItems: (spots) => spots.map((s) {
                              final col =
                                  _enabledColumns.elementAt(s.barIndex);
                              return LineTooltipItem(
                                '$col: ${s.y.toStringAsFixed(4)}',
                                TextStyle(
                                    color: _colorFor(col),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              );
                            }).toList(),
                          ),
                          handleBuiltInTouches: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.yColumns.map((col) {
                  final on = _enabledColumns.contains(col);
                  final c = _colorFor(col);
                  return GestureDetector(
                    onTap: () => _toggleColumn(col),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: on ? c.withAlpha(25) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: on ? c : AppTheme.accentTan.withAlpha(76),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color:
                                  on ? c : AppTheme.accentTan.withAlpha(76),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(col,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: on ? c : AppTheme.textLight)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<LineChartBarData> _buildBars() {
    return _enabledColumns.map((col) {
      final spots = <FlSpot>[];
      for (final row in widget.dataset.rows) {
        final x = row[widget.xColumn];
        final y = row[col];
        if (x != null && y != null && !x.isNaN && !y.isNaN) {
          spots.add(FlSpot(x, y));
        }
      }
      spots.sort((a, b) => a.x.compareTo(b.x));
      return LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.15,
        color: _colorFor(col),
        barWidth: 1.5,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      );
    }).toList();
  }

  void _handleZoomPan(ScaleUpdateDetails details) {
    if (_viewMinX == null || _viewMaxX == null) {
      return;
    }
    setState(() {
      final xRange = _viewMaxX! - _viewMinX!;
      final fxR = _maxX! - _minX!;
      double nMinX = _viewMinX!, nMaxX = _viewMaxX!;

      if (details.scale != 1.0) {
        final z = 1.0 + (1.0 - details.scale) * 0.02;
        final cx = (nMinX + nMaxX) / 2;
        final nxR = (xRange * z).clamp(fxR * 0.05, fxR * 2.0);
        nMinX = cx - nxR / 2;
        nMaxX = cx + nxR / 2;
      }

      nMinX += -details.focalPointDelta.dx * xRange * 0.002;
      nMaxX += -details.focalPointDelta.dx * xRange * 0.002;

      final xPad = fxR * 0.1;
      if (nMinX < _minX! - xPad) {
        nMaxX += (_minX! - xPad) - nMinX;
        nMinX = _minX! - xPad;
      }
      if (nMaxX > _maxX! + xPad) {
        nMinX -= nMaxX - (_maxX! + xPad);
        nMaxX = _maxX! + xPad;
      }

      _viewMinX = nMinX;
      _viewMaxX = nMaxX;
    });
  }

  void _handleScroll(PointerScrollEvent event) {
    if (_viewMinX == null || _viewMaxX == null) {
      return;
    }
    setState(() {
      final xRange = _viewMaxX! - _viewMinX!;
      final fxR = _maxX! - _minX!;
      final zoomFactor = event.scrollDelta.dy > 0 ? 1.1 : 0.9;
      final cx = (_viewMinX! + _viewMaxX!) / 2;
      final nxR = (xRange * zoomFactor).clamp(fxR * 0.05, fxR * 2.0);
      _viewMinX = cx - nxR / 2;
      _viewMaxX = cx + nxR / 2;
    });
  }

  String _fmt(double v) {
    if (v.abs() >= 10000) return v.toStringAsExponential(1);
    if (v.abs() >= 1000) return v.toStringAsFixed(0);
    if (v.abs() >= 1) return v.toStringAsFixed(1);
    return v.toStringAsFixed(3);
  }
}
