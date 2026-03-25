import 'package:flutter_test/flutter_test.dart';
import 'package:relevix/models/dataset.dart';
import 'package:relevix/services/data_validator.dart';

void main() {
  group('DataValidator.validate', () {
    test('valid dataset with numeric columns', () {
      final dataset = Dataset(
        columns: ['T', 'Z_POS', 'PRESSURE'],
        rows: [
          DataRow(values: {'T': 1.0, 'Z_POS': 10.0, 'PRESSURE': 100.0}),
          DataRow(values: {'T': 2.0, 'Z_POS': 20.0, 'PRESSURE': 200.0}),
        ],
        sourceName: 'test.csv',
      );

      final result = DataValidator.validate(dataset);
      expect(result.isValid, isTrue);
      expect(result.numericColumns.length, greaterThanOrEqualTo(2));
    });

    test('rejects dataset with no columns', () {
      final dataset = Dataset(columns: [], rows: [], sourceName: 'empty.csv');
      final result = DataValidator.validate(dataset);
      expect(result.isValid, isFalse);
      expect(result.error, contains('No headers'));
    });

    test('rejects dataset with no rows', () {
      final dataset = Dataset(
        columns: ['A', 'B'],
        rows: [],
        sourceName: 'norows.csv',
      );
      final result = DataValidator.validate(dataset);
      expect(result.isValid, isFalse);
      expect(result.error, contains('no data rows'));
    });
  });

  group('DataValidator.validateSchemaMatch', () {
    test('matches identical schemas', () {
      final ref = Dataset(
        columns: ['T', 'Z_POS'],
        rows: [DataRow(values: {'T': 1.0, 'Z_POS': 10.0})],
        sourceName: 'ref.csv',
      );
      final candidate = Dataset(
        columns: ['T', 'Z_POS'],
        rows: [DataRow(values: {'T': 2.0, 'Z_POS': 20.0})],
        sourceName: 'cand.csv',
      );

      final result = DataValidator.validateSchemaMatch(ref, candidate);
      expect(result.isValid, isTrue);
    });

    test('rejects mismatched schemas', () {
      final ref = Dataset(
        columns: ['T', 'Z_POS'],
        rows: [DataRow(values: {'T': 1.0, 'Z_POS': 10.0})],
        sourceName: 'ref.csv',
      );
      final candidate = Dataset(
        columns: ['T', 'VELOCITY'],
        rows: [DataRow(values: {'T': 2.0, 'VELOCITY': 5.0})],
        sourceName: 'cand.csv',
      );

      final result = DataValidator.validateSchemaMatch(ref, candidate);
      expect(result.isValid, isFalse);
      expect(result.error, contains('Schema mismatch'));
    });
  });
}
