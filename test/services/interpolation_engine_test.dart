import 'package:flutter_test/flutter_test.dart';
import 'package:relevix/models/dataset.dart';
import 'package:relevix/models/interpolation_result.dart';
import 'package:relevix/services/interpolation_engine.dart';

void main() {
  late Dataset dataset;

  setUp(() {
    dataset = Dataset(
      columns: ['T', 'Z_POS'],
      rows: [
        DataRow(values: {'T': 0.0, 'Z_POS': 0.0}),
        DataRow(values: {'T': 1.0, 'Z_POS': 10.0}),
        DataRow(values: {'T': 2.0, 'Z_POS': 20.0}),
        DataRow(values: {'T': 3.0, 'Z_POS': 30.0}),
        DataRow(values: {'T': 4.0, 'Z_POS': 50.0}),
        DataRow(values: {'T': 5.0, 'Z_POS': 80.0}),
      ],
      sourceName: 'test.csv',
    );
  });

  group('Exact Match', () {
    test('returns exact value when input matches a data point', () {
      final engine = InterpolationEngine(
        dataset: dataset,
        inputColumn: 'T',
        outputColumn: 'Z_POS',
      );

      final result = engine.compute(2.0);
      expect(result.value, equals(20.0));
      expect(result.method, equals(InterpolationMethod.exact));
    });

    test('returns exact value at boundary (first point)', () {
      final engine = InterpolationEngine(
        dataset: dataset,
        inputColumn: 'T',
        outputColumn: 'Z_POS',
      );

      final result = engine.compute(0.0);
      expect(result.value, equals(0.0));
      expect(result.method, equals(InterpolationMethod.exact));
    });

    test('returns exact value at boundary (last point)', () {
      final engine = InterpolationEngine(
        dataset: dataset,
        inputColumn: 'T',
        outputColumn: 'Z_POS',
      );

      final result = engine.compute(5.0);
      expect(result.value, equals(80.0));
      expect(result.method, equals(InterpolationMethod.exact));
    });
  });

  group('Linear Interpolation', () {
    test('interpolates correctly between two points (linear segment)', () {
      final engine = InterpolationEngine(
        dataset: dataset,
        inputColumn: 'T',
        outputColumn: 'Z_POS',
      );

      final result = engine.compute(1.5);
      expect(result.value, equals(15.0));
      expect(result.method, equals(InterpolationMethod.interpolated));
    });

    test('interpolates correctly between non-linear segment', () {
      final engine = InterpolationEngine(
        dataset: dataset,
        inputColumn: 'T',
        outputColumn: 'Z_POS',
      );

      final result = engine.compute(3.5);
      expect(result.value, equals(40.0));
      expect(result.method, equals(InterpolationMethod.interpolated));
    });

    test('interpolates near the lower boundary', () {
      final engine = InterpolationEngine(
        dataset: dataset,
        inputColumn: 'T',
        outputColumn: 'Z_POS',
      );

      final result = engine.compute(0.5);
      expect(result.value, equals(5.0));
      expect(result.method, equals(InterpolationMethod.interpolated));
    });
  });

  group('Out-of-Range (Nearest Fallback)', () {
    test('returns nearest value for input below range', () {
      final engine = InterpolationEngine(
        dataset: dataset,
        inputColumn: 'T',
        outputColumn: 'Z_POS',
      );

      final result = engine.compute(-1.0);
      expect(result.value, equals(0.0));
      expect(result.method, equals(InterpolationMethod.nearest));
    });

    test('returns nearest value for input above range', () {
      final engine = InterpolationEngine(
        dataset: dataset,
        inputColumn: 'T',
        outputColumn: 'Z_POS',
      );

      final result = engine.compute(10.0);
      expect(result.value, equals(80.0));
      expect(result.method, equals(InterpolationMethod.nearest));
    });
  });

  group('Duplicate Values (Averaging)', () {
    test('averages output when multiple exact matches exist', () {
      final dupeDataset = Dataset(
        columns: ['T', 'Z_POS'],
        rows: [
          DataRow(values: {'T': 1.0, 'Z_POS': 10.0}),
          DataRow(values: {'T': 1.0, 'Z_POS': 20.0}),
          DataRow(values: {'T': 2.0, 'Z_POS': 30.0}),
        ],
        sourceName: 'dupes.csv',
      );

      final engine = InterpolationEngine(
        dataset: dupeDataset,
        inputColumn: 'T',
        outputColumn: 'Z_POS',
      );

      final result = engine.compute(1.0);
      expect(result.value, equals(15.0));
      expect(result.method, equals(InterpolationMethod.averaged));
    });
  });

  group('Bidirectional Mapping', () {
    test('works in reverse direction (Z_POS → T)', () {
      final engine = InterpolationEngine(
        dataset: dataset,
        inputColumn: 'Z_POS',
        outputColumn: 'T',
      );

      final result = engine.compute(20.0);
      expect(result.value, equals(2.0));
      expect(result.method, equals(InterpolationMethod.exact));
    });

    test('interpolates in reverse direction', () {
      final engine = InterpolationEngine(
        dataset: dataset,
        inputColumn: 'Z_POS',
        outputColumn: 'T',
      );

      final result = engine.compute(15.0);
      expect(result.value, equals(1.5));
      expect(result.method, equals(InterpolationMethod.interpolated));
    });
  });

  group('Edge Cases', () {
    test('throws on empty dataset', () {
      final emptyDataset = Dataset(
        columns: ['T', 'Z_POS'],
        rows: [],
        sourceName: 'empty.csv',
      );

      final engine = InterpolationEngine(
        dataset: emptyDataset,
        inputColumn: 'T',
        outputColumn: 'Z_POS',
      );

      expect(() => engine.compute(1.0), throwsStateError);
    });

    test('handles single-row dataset', () {
      final singleDataset = Dataset(
        columns: ['T', 'Z_POS'],
        rows: [
          DataRow(values: {'T': 5.0, 'Z_POS': 50.0}),
        ],
        sourceName: 'single.csv',
      );

      final engine = InterpolationEngine(
        dataset: singleDataset,
        inputColumn: 'T',
        outputColumn: 'Z_POS',
      );

      final exact = engine.compute(5.0);
      expect(exact.value, equals(50.0));
      expect(exact.method, equals(InterpolationMethod.exact));

      final nearest = engine.compute(3.0);
      expect(nearest.value, equals(50.0));
      expect(nearest.method, equals(InterpolationMethod.nearest));
    });
  });

  group('Data Range', () {
    test('minInput and maxInput are correct', () {
      final engine = InterpolationEngine(
        dataset: dataset,
        inputColumn: 'T',
        outputColumn: 'Z_POS',
      );

      expect(engine.minInput, equals(0.0));
      expect(engine.maxInput, equals(5.0));
    });
  });
}
