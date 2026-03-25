import '../models/dataset.dart';

class DatasetMerger {
  static Dataset merge(List<Dataset> datasets) {
    if (datasets.isEmpty) {
      throw ArgumentError('No datasets to merge.');
    }

    if (datasets.length == 1) {
      return datasets.first;
    }

    final columns = datasets.first.columns;

    final allRows = <DataRow>[];
    for (final dataset in datasets) {
      allRows.addAll(dataset.rows);
    }

    final sourceNames = datasets.map((d) => d.sourceName).join(' + ');

    return Dataset(
      columns: columns,
      rows: allRows,
      sourceName: sourceNames,
    );
  }

  static Dataset removeDuplicateRows(Dataset dataset, String keyColumn) {
    final seen = <double>{};
    final uniqueRows = <DataRow>[];

    for (final row in dataset.rows) {
      final key = row[keyColumn];
      if (key != null && !seen.contains(key)) {
        seen.add(key);
        uniqueRows.add(row);
      }
    }

    return Dataset(
      columns: dataset.columns,
      rows: uniqueRows,
      sourceName: dataset.sourceName,
    );
  }

  static Dataset removeInvalidRows(Dataset dataset) {
    final validRows = dataset.rows.where((row) {
      return row.values.values.every((v) => !v.isNaN && !v.isInfinite);
    }).toList();

    return Dataset(
      columns: dataset.columns,
      rows: validRows,
      sourceName: dataset.sourceName,
    );
  }
}
