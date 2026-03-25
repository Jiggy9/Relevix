import '../models/dataset.dart';
import '../models/interpolation_result.dart';

class InterpolationEngine {
  final Dataset dataset;
  final String inputColumn;
  final String outputColumn;
  late final List<DataRow> _sortedRows;

  InterpolationEngine({
    required this.dataset,
    required this.inputColumn,
    required this.outputColumn,
  }) {
    _sortedRows = List<DataRow>.from(dataset.rows)
      ..sort((a, b) {
        final aVal = a[inputColumn] ?? double.infinity;
        final bVal = b[inputColumn] ?? double.infinity;
        return aVal.compareTo(bVal);
      });
  }

  InterpolationResult compute(double inputValue) {
    if (_sortedRows.isEmpty) {
      throw StateError('Dataset is empty. Cannot interpolate.');
    }

    final exactMatches = _findExactMatches(inputValue);
    if (exactMatches.isNotEmpty) {
      if (exactMatches.length == 1) {
        return InterpolationResult(
          value: exactMatches.first,
          method: InterpolationMethod.exact,
          description: 'Exact match found for $inputColumn = $inputValue',
        );
      }
      final avg = exactMatches.reduce((a, b) => a + b) / exactMatches.length;
      return InterpolationResult(
        value: avg,
        method: InterpolationMethod.averaged,
        description:
            'Multiple exact matches (${exactMatches.length}) averaged for $inputColumn = $inputValue',
      );
    }

    final bounds = _findBounds(inputValue);

    if (bounds == null) {
      return _fallbackNearest(inputValue);
    }

    final lowerRow = bounds.$1;
    final upperRow = bounds.$2;
    final x0 = lowerRow[inputColumn]!;
    final y0 = lowerRow[outputColumn]!;
    final x1 = upperRow[inputColumn]!;
    final y1 = upperRow[outputColumn]!;

    if ((x1 - x0).abs() < 1e-12) {
      final avg = (y0 + y1) / 2;
      return InterpolationResult(
        value: avg,
        method: InterpolationMethod.averaged,
        description: 'Bounds are identical; averaged output values.',
      );
    }

    final interpolatedValue = y0 + (inputValue - x0) * (y1 - y0) / (x1 - x0);

    return InterpolationResult(
      value: interpolatedValue,
      method: InterpolationMethod.interpolated,
      description:
          'Linear interpolation between ($x0, $y0) and ($x1, $y1)',
    );
  }

  List<double> _findExactMatches(double inputValue) {
    final results = <double>[];
    for (final row in _sortedRows) {
      final val = row[inputColumn];
      if (val != null && (val - inputValue).abs() < 1e-9) {
        final output = row[outputColumn];
        if (output != null) results.add(output);
      }
    }
    return results;
  }

  (DataRow, DataRow)? _findBounds(double inputValue) {
    int low = 0;
    int high = _sortedRows.length - 1;

    final firstVal = _sortedRows.first[inputColumn];
    final lastVal = _sortedRows.last[inputColumn];

    if (firstVal == null || lastVal == null) return null;
    if (inputValue < firstVal || inputValue > lastVal) return null;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final midVal = _sortedRows[mid][inputColumn];
      if (midVal == null) {
        high = mid - 1;
        continue;
      }
      if (midVal < inputValue) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    final upperIdx = low;
    final lowerIdx = upperIdx - 1;

    if (lowerIdx < 0 || upperIdx >= _sortedRows.length) return null;

    final lowerRow = _sortedRows[lowerIdx];
    final upperRow = _sortedRows[upperIdx];

    if (lowerRow[inputColumn] == null ||
        lowerRow[outputColumn] == null ||
        upperRow[inputColumn] == null ||
        upperRow[outputColumn] == null) {
      return null;
    }

    return (lowerRow, upperRow);
  }

  InterpolationResult _fallbackNearest(double inputValue) {
    double minDist = double.infinity;
    final nearestOutputs = <double>[];

    for (final row in _sortedRows) {
      final val = row[inputColumn];
      final output = row[outputColumn];
      if (val == null || output == null) continue;

      final dist = (val - inputValue).abs();
      if (dist < minDist - 1e-9) {
        minDist = dist;
        nearestOutputs.clear();
        nearestOutputs.add(output);
      } else if ((dist - minDist).abs() < 1e-9) {
        nearestOutputs.add(output);
      }
    }

    if (nearestOutputs.isEmpty) {
      throw StateError('No valid data points found for interpolation.');
    }

    if (nearestOutputs.length == 1) {
      return InterpolationResult(
        value: nearestOutputs.first,
        method: InterpolationMethod.nearest,
        description:
            'Input $inputValue is outside data range. Using nearest value.',
      );
    }

    final avg =
        nearestOutputs.reduce((a, b) => a + b) / nearestOutputs.length;
    return InterpolationResult(
      value: avg,
      method: InterpolationMethod.averaged,
      description:
          'Input $inputValue is outside data range. Averaged ${nearestOutputs.length} nearest values.',
    );
  }

  bool get isInputInRange {
    if (_sortedRows.isEmpty) return false;
    return true;
  }

  double? get minInput => _sortedRows.isNotEmpty
      ? _sortedRows.first[inputColumn]
      : null;

  double? get maxInput => _sortedRows.isNotEmpty
      ? _sortedRows.last[inputColumn]
      : null;
}
