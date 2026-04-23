import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../models/dataset.dart';

class FileParser {
  static Future<Dataset> parse({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'csv':
        return _parseCsv(bytes, fileName);
      case 'xlsx':
      case 'xls':
        return _parseExcel(bytes, fileName);
      default:
        throw FormatException('Unsupported file type: .$extension');
    }
  }

  static Dataset _parseCsv(Uint8List bytes, String fileName) {
    final csvString = String.fromCharCodes(bytes);

    // Auto-detect delimiter: tab or comma
    final delimiter = csvString.contains('\t') ? '\t' : ',';

    final rows = const CsvToListConverter()
        .convert(csvString, fieldDelimiter: delimiter);

    if (rows.isEmpty) {
      throw FormatException('CSV file is empty: $fileName');
    }

    // Find the header row: first row where all cells are short non-numeric
    // strings (column names), followed by at least one row of numeric data.
    int headerIndex = _findHeaderRow(rows);

    final headers =
        rows[headerIndex].map((e) => e.toString().trim()).toList();

    if (headers.isEmpty) {
      throw FormatException('No headers found in: $fileName');
    }

    // Identify numeric columns by scanning all data rows
    final numericColumns = _detectNumericColumns(
      headers,
      rows.sublist(headerIndex + 1),
    );

    if (numericColumns.isEmpty) {
      throw FormatException(
          'No numeric columns found in: $fileName');
    }

    final dataRows = <DataRow>[];
    for (var i = headerIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length != headers.length) continue;

      final values = <String, double>{};
      bool hasData = false;

      for (final col in numericColumns) {
        final colIndex = headers.indexOf(col);
        final parsed = _tryParseDouble(row[colIndex]);
        if (parsed != null && !parsed.isNaN) {
          values[col] = parsed;
          hasData = true;
        }
      }

      if (hasData) {
        dataRows.add(DataRow(values: values));
      }
    }

    return Dataset(
      columns: numericColumns,
      rows: dataRows,
      sourceName: fileName,
    );
  }

  /// Finds the header row index by scanning for the first row where:
  /// - It has ≥ 2 cells
  /// - All cells are short, non-numeric strings (i.e. column names)
  /// - The next row contains parseable numeric data
  /// Falls back to row 0 if no such row is found.
  static int _findHeaderRow(List<List<dynamic>> rows) {
    for (var i = 0; i < rows.length - 1; i++) {
      final row = rows[i];
      if (row.length < 2) continue;

      // Check: all cells in this row are non-numeric short strings
      final allNonNumeric = row.every((cell) {
        final str = cell.toString().trim();
        if (str.isEmpty) return false;
        return _tryParseDouble(str) == null && str.length < 50;
      });

      if (!allNonNumeric) continue;

      // Check: the next row has at least some numeric values
      final nextRow = rows[i + 1];
      if (nextRow.length != row.length) continue;
      final hasNumeric =
          nextRow.any((cell) => _tryParseDouble(cell) != null);

      if (hasNumeric) return i;
    }
    return 0; // fallback
  }


  static Dataset _parseExcel(Uint8List bytes, String fileName) {
    final excel = Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) {
      throw FormatException('Excel file has no sheets: $fileName');
    }

    final sheet = excel.tables[excel.tables.keys.first]!;
    final sheetRows = sheet.rows;

    if (sheetRows.isEmpty) {
      throw FormatException('Excel sheet is empty: $fileName');
    }

    final headers = sheetRows.first
        .map((cell) => cell?.value?.toString().trim() ?? '')
        .where((h) => h.isNotEmpty)
        .toList();

    if (headers.isEmpty) {
      throw FormatException('No headers found in: $fileName');
    }

    // Build raw data for numeric column detection
    final rawData = <List<dynamic>>[];
    for (var i = 1; i < sheetRows.length; i++) {
      final row = sheetRows[i];
      if (row.length < headers.length) continue;
      rawData.add(
          List.generate(headers.length, (j) => row[j]?.value));
    }

    final numericColumns = _detectNumericColumns(headers, rawData);

    if (numericColumns.isEmpty) {
      throw FormatException(
          'No numeric columns found in: $fileName');
    }

    final dataRows = <DataRow>[];
    for (final rawRow in rawData) {
      final values = <String, double>{};
      bool hasData = false;

      for (final col in numericColumns) {
        final colIndex = headers.indexOf(col);
        final parsed = _tryParseDouble(rawRow[colIndex]);
        if (parsed != null && !parsed.isNaN) {
          values[col] = parsed;
          hasData = true;
        }
      }

      if (hasData) {
        dataRows.add(DataRow(values: values));
      }
    }

    return Dataset(
      columns: numericColumns,
      rows: dataRows,
      sourceName: fileName,
    );
  }

  /// Scans all data rows to find columns where at least half the values
  /// are parseable as doubles. Returns the list of numeric column names.
  static List<String> _detectNumericColumns(
      List<String> headers, List<List<dynamic>> dataRows) {
    if (dataRows.isEmpty) return [];

    final numericColumns = <String>[];
    for (var j = 0; j < headers.length; j++) {
      int numericCount = 0;
      for (final row in dataRows) {
        if (j < row.length && _tryParseDouble(row[j]) != null) {
          numericCount++;
        }
      }
      // A column is numeric if at least half its values parse as numbers
      if (numericCount > dataRows.length / 2) {
        numericColumns.add(headers[j]);
      }
    }
    return numericColumns;
  }

  static double? _tryParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }
}
