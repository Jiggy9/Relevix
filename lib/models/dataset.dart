class DataRow {
  final Map<String, double> values;

  const DataRow({required this.values});

  double? operator [](String column) => values[column];

  @override
  String toString() => 'DataRow($values)';
}

class Dataset {
  final List<String> columns;
  final List<DataRow> rows;
  final String sourceName;

  const Dataset({
    required this.columns,
    required this.rows,
    this.sourceName = '',
  });

  List<String> get numericColumns => columns;

  int get rowCount => rows.length;
  int get columnCount => columns.length;

  bool get isEmpty => rows.isEmpty;
  bool get isNotEmpty => rows.isNotEmpty;

  List<double> valuesForColumn(String column) {
    return rows
        .map((row) => row[column])
        .whereType<double>()
        .toList();
  }

  Dataset sortedBy(String column) {
    final sorted = List<DataRow>.from(rows)
      ..sort((a, b) {
        final aVal = a[column];
        final bVal = b[column];
        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return 1;
        if (bVal == null) return -1;
        return aVal.compareTo(bVal);
      });
    return Dataset(columns: columns, rows: sorted, sourceName: sourceName);
  }

  @override
  String toString() =>
      'Dataset(source: $sourceName, columns: $columns, rows: ${rows.length})';
}
