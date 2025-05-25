import 'package:flutter_test/flutter_test.dart';
import 'package:stroke_order_animator/stroke_order_animator.dart';

import 'resources/test_strokes.dart';

void main() {
  group('Valid JSON inputs', () {
    const strokeCounts = <String, (int, int)>{
      '永': (5, 4),
      '你': (7, 2),
      '㼌': (10, 5),
      '丸': (3, 1),
      '亟': (8, 0),
    };

    strokeCounts.forEach((character, info) {
      final (nStrokes, nRadicalStrokes) = info;
      final strokeOrder = StrokeOrder(strokeOrderJsons[character]!);

      test('$character: Number of strokes gets parsed correctly', () {
        expect(strokeOrder.nStrokes, nStrokes);
      });

      test('$character: Stroke outlines get parsed correctly', () {
        expect(strokeOrder.strokeOutlines.length, nStrokes);
      });
      test('$character: Medians get parsed correctly', () {
        expect(strokeOrder.medians.length, nStrokes);
      });
      test('$character: Radical stroke indices get parsed correctly', () {
        expect(strokeOrder.radicalStrokeIndices.length, nRadicalStrokes);
      });
    });
  });

  group('Invalid JSON inputs throw format exceptions', () {
    const invalidInputs = {
      'Invalid JSON string for stroke order': '...',
      'Missing strokes in stroke order JSON':
          "{'medians': $validMedians, 'radStrokes': $validRadicalStrokes}",
      'Invalid strokes in stroke order JSON':
          "{'strokes': [5], 'medians': $validMedians, 'radStrokes': $validRadicalStrokes}",
      'Missing medians in stroke order JSON':
          "{'strokes': $validStrokeOutlines, 'radStrokes': $validRadicalStrokes}",
      'Invalid medians in stroke order JSON':
          "{'strokes': $validStrokeOutlines, 'medians': [[[428]]], 'radStrokes': $validRadicalStrokes}",
      'Number of strokes and medians not equal in stroke order JSON':
          "{'strokes': $validStrokeOutlines, 'medians': [[[428, 824]], [[1, 2]]], 'radStrokes': $validRadicalStrokes}",
      'Invalid radical stroke indices in stroke order JSON':
          "{'strokes': $validStrokeOutlines, 'medians': $validMedians, 'radStrokes': ['12', 3, 4]}",
    };

    invalidInputs.forEach((errorMessage, jsonInput) {
      test(errorMessage, () {
        expect(
          () => StrokeOrder(jsonInput),
          throwsA(
            predicate(
              (e) =>
                  e is FormatException &&
                  e.toString() == 'FormatException: $errorMessage',
            ),
          ),
        );
      });
    });
  });

  test('Stroke order equality and hashing', () {
    expect(
      StrokeOrder(strokeOrderJsons['永']!).hashCode,
      StrokeOrder(strokeOrderJsons['永']!).hashCode,
    );

    expect(
      StrokeOrder(strokeOrderJsons['永']!),
      StrokeOrder(strokeOrderJsons['永']!),
    );
  });
}
