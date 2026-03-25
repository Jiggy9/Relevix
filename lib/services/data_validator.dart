import '../models/dataset.dart';

class ValidationResult {
  final bool isValid;
  final String? error;
  final List<String> numericColumns;

  const ValidationResult({
    required this.isValid,
    this.error,
    this.numericColumns = const [],
  });

  factory ValidationResult.valid(List<String> numericColumns) =>
      ValidationResult(isValid: true, numericColumns: numericColumns);

  factory ValidationResult.invalid(String error) =>
      ValidationResult(isValid: false, error: error);
}

class DataValidator {
  static ValidationResult validate(Dataset dataset) {
    if (dataset.columns.isEmpty) {
      return ValidationResult.invalid('No headers found in the dataset.');
    }

    if (dataset.rows.isEmpty) {
      return ValidationResult.invalid('Dataset contains no data rows.');
    }

    final numericColumns = _detectNumericColumns(dataset);

    if (numericColumns.length < 2) {
      return ValidationResult.invalid(
        'At least 2 numeric columns are required. '
        'Found ${numericColumns.length}: ${numericColumns.join(", ")}',
      );
    }

    return ValidationResult.valid(numericColumns);
  }

  static ValidationResult validateSchemaMatch(
    Dataset reference,
    Dataset candidate,
  ) {
    final refCols = Set<String>.from(reference.columns);
    final candCols = Set<String>.from(candidate.columns);

    if (!refCols.containsAll(candCols) || !candCols.containsAll(refCols)) {
      final missing = refCols.difference(candCols);
      final extra = candCols.difference(refCols);
      final parts = <String>[];
      if (missing.isNotEmpty) parts.add('Missing columns: ${missing.join(", ")}');
      if (extra.isNotEmpty) parts.add('Extra columns: ${extra.join(", ")}');
      return ValidationResult.invalid(
        'Schema mismatch in "${candidate.sourceName}". ${parts.join(". ")}',
      );
    }

    return ValidationResult.valid(
      _detectNumericColumns(candidate),
    );
  }

  static List<String> _detectNumericColumns(Dataset dataset) {
    return dataset.columns.where((col) {
      return dataset.rows.any((row) => row[col] != null);
    }).toList();
  }
}
