import 'package:flutter_test/flutter_test.dart';
import 'package:relevix/models/dataset.dart';
import 'package:relevix/services/dataset_merger.dart';

void main() {
  group('DatasetMerger.merge', () {
    test('merges two datasets with same columns', () {
      final ds1 = Dataset(
        columns: ['T', 'Z_POS'],
        rows: [
          DataRow(values: {'T': 1.0, 'Z_POS': 10.0}),
          DataRow(values: {'T': 2.0, 'Z_POS': 20.0}),
        ],
        sourceName: 'file1.csv',
      );
      final ds2 = Dataset(
        columns: ['T', 'Z_POS'],
        rows: [
          DataRow(values: {'T': 3.0, 'Z_POS': 30.0}),
        ],
        sourceName: 'file2.csv',
      );

      final merged = DatasetMerger.merge([ds1, ds2]);
      expect(merged.rowCount, equals(3));
      expect(merged.columns, equals(['T', 'Z_POS']));
    });

    test('returns single dataset unchanged', () {
      final ds = Dataset(
        columns: ['A'],
        rows: [DataRow(values: {'A': 1.0})],
        sourceName: 'only.csv',
      );

      final merged = DatasetMerger.merge([ds]);
      expect(merged, same(ds));
    });

    test('throws on empty list', () {
      expect(() => DatasetMerger.merge([]), throwsArgumentError);
    });
  });

  group('DatasetMerger.removeDuplicateRows', () {
    test('removes duplicate rows by key column', () {
      final ds = Dataset(
        columns: ['T', 'Z_POS'],
        rows: [
          DataRow(values: {'T': 1.0, 'Z_POS': 10.0}),
          DataRow(values: {'T': 1.0, 'Z_POS': 15.0}),
          DataRow(values: {'T': 2.0, 'Z_POS': 20.0}),
        ],
        sourceName: 'dupes.csv',
      );

      final deduped = DatasetMerger.removeDuplicateRows(ds, 'T');
      expect(deduped.rowCount, equals(2));
    });
  });

  group('DatasetMerger.removeInvalidRows', () {
    test('removes rows with NaN values', () {
      final ds = Dataset(
        columns: ['T', 'Z_POS'],
        rows: [
          DataRow(values: {'T': 1.0, 'Z_POS': 10.0}),
          DataRow(values: {'T': double.nan, 'Z_POS': 20.0}),
          DataRow(values: {'T': 3.0, 'Z_POS': 30.0}),
        ],
        sourceName: 'nan.csv',
      );

      final cleaned = DatasetMerger.removeInvalidRows(ds);
      expect(cleaned.rowCount, equals(2));
    });
  });
}
