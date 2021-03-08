import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stroke_order_animator/strokeOrderAnimationController.dart';

import 'testStrokes.dart';

void main() {
  final tickerProvider = TestVSync();
  debugSemanticsDisableAnimations = true;

  group('Test stroke count and stroke order ', () {
    final controllers = List.generate(
      strokeOrders.length,
      (index) =>
          StrokeOrderAnimationController(strokeOrders[index], tickerProvider),
    );

    test('Test stroke count and stroke order after initialization', () {
      expect(controllers[0].nStrokes, 5);
      expect(controllers[0].strokeOrder, strokeOrders[0]);

      expect(controllers[1].nStrokes, 7);
      expect(controllers[1].strokeOrder, strokeOrders[1]);

      expect(controllers[2].nStrokes, 10);
      expect(controllers[2].strokeOrder, strokeOrders[2]);

      expect(controllers[3].nStrokes, 3);
      expect(controllers[3].strokeOrder, strokeOrders[3]);

      expect(controllers[4].nStrokes, 8);
      expect(controllers[4].strokeOrder, strokeOrders[4]);

      expect(controllers[5].nStrokes, 3);
      expect(controllers[5].strokeOrder, strokeOrders[5]);
    });

    test('Test stroke count and stroke after setting new character', () {
      controllers[0].setStrokeOrder(strokeOrders[1]);
      expect(controllers[0].nStrokes, 7);
      expect(controllers[0].strokeOrder, strokeOrders[1]);

      controllers[1].setStrokeOrder(strokeOrders[2]);
      expect(controllers[1].nStrokes, 10);
      expect(controllers[1].strokeOrder, strokeOrders[2]);

      controllers[2].setStrokeOrder(strokeOrders[3]);
      expect(controllers[2].nStrokes, 3);
      expect(controllers[2].strokeOrder, strokeOrders[3]);

      controllers[3].setStrokeOrder(strokeOrders[4]);
      expect(controllers[3].nStrokes, 8);
      expect(controllers[3].strokeOrder, strokeOrders[4]);

      controllers[4].setStrokeOrder(strokeOrders[5]);
      expect(controllers[4].nStrokes, 3);
      expect(controllers[4].strokeOrder, strokeOrders[5]);

      controllers[5].setStrokeOrder(strokeOrders[0]);
      expect(controllers[5].nStrokes, 5);
      expect(controllers[5].strokeOrder, strokeOrders[0]);
    });

    test('Invalid JSON string throws exception', () {
      expect(() => controllers[0].setStrokeOrder("..."), throwsFormatException);
    });

    test('Invalid strokes in JSON throw exceptions', () {
      final invalidJSONs = [
        // No strokes
        "{'medians': [[[428, 824]]], 'radStrokes': [1, 2, 3, 4]}",
        // Strokes not List of paths
        "{'strokes': [5], 'medians': [[[428, 824]]], 'radStrokes': [1, 2, 3, 4]}",
        // "{'strokes': ['5'],'medians': [[[0, 0]]], 'radStrokes': [0]}", // Missing strokes
        // "{'strokes': ['5'], 'medians': [], 'radStrokes': [0]}"
      ];

      for (var invalidJSON in invalidJSONs) {
        expect(() => controllers[0].setStrokeOrder(invalidJSON),
            throwsFormatException);
      }
    });

    test('Invalid medians in JSON throw exceptions', () {
      final invalidJSONs = [
        // No medians
        "{'strokes': ['M 440 788 Q 497 731 535 718 Q 553 717 562 732 Q 569 748 564 767 Q 546 815 477 828 Q 438 841 421 834 Q 414 831 418 817 Q 421 804 440 788 Z'], 'radStrokes': [1, 2, 3, 4]}",
        // Medians not list of list of offsets
        "{'strokes': ['M 440 788 Q 497 731 535 718 Q 553 717 562 732 Q 569 748 564 767 Q 546 815 477 828 Q 438 841 421 834 Q 414 831 418 817 Q 421 804 440 788 Z'], 'medians': [[[428]]], 'radStrokes': [1, 2, 3, 4]}",
      ];

      for (var invalidJSON in invalidJSONs) {
        expect(() => controllers[0].setStrokeOrder(invalidJSON),
            throwsFormatException);
      }
    });

    test('Unequal number of strokes and medians throws exception', () {
      expect(
          () => controllers[0].setStrokeOrder(
              "{'strokes': ['M 440 788 Q 497 731 535 718 Q 553 717 562 732 Q 569 748 564 767 Q 546 815 477 828 Q 438 841 421 834 Q 414 831 418 817 Q 421 804 440 788 Z'], 'medians': [[[428, 824]], [[1, 2]]], 'radStrokes': [1, 2, 3, 4]}"),
          throwsFormatException);
    });

    test('Invalid radical stroke indices leads to empty list', () {
      controllers[0].setStrokeOrder(
          "{'strokes': ['M 440 788 Q 497 731 535 718 Q 553 717 562 732 Q 569 748 564 767 Q 546 815 477 828 Q 438 841 421 834 Q 414 831 418 817 Q 421 804 440 788 Z'], 'medians': [[[428, 824], [1, 2]]], 'radStrokes': ['12', 3, 4]}");
      expect(controllers[0].radicalStrokes, equals([]));
    });
  });

  group("Test animation controls", () {
    final controller =
        StrokeOrderAnimationController(strokeOrders[0], tickerProvider);

    test('Next stroke', () {
      controller.reset();
      controller.nextStroke();
      controller.nextStroke();
      expect(controller.currentStroke, 2);
    });

    test('Previous stroke', () {
      controller.reset();
      controller.nextStroke();
      controller.nextStroke();
      controller.previousStroke();
      expect(controller.currentStroke, 1);
    });

    test('Show full character', () {
      controller.showFullCharacter();
      expect(controller.currentStroke, controller.nStrokes);
      expect(controller.currentStroke, 5);
    });

    test('Reset', () {
      controller.reset();
      expect(controller.currentStroke, 0);
      controller.nextStroke();
      controller.reset();
      expect(controller.currentStroke, 0);
    });
  });

  group('Test quizzing', () {
    final controller =
        StrokeOrderAnimationController(strokeOrders[0], tickerProvider);

    final controller2 =
        StrokeOrderAnimationController(strokeOrders[1], tickerProvider);

    test('Start quiz', () {
      controller.startQuiz();
      controller.reset();
      expect(controller.isQuizzing, true);
      expect(controller.isAnimating, false);
      expect(controller.currentStroke, 0);
    });

    group('Check stroke', () {
      controller.startQuiz();

      test('Empty stroke does not lead to crash', () {
        controller.checkStroke([]);
      });

      test('Correct stroke gets accepted', () {
        controller.checkStroke(correctStroke00);
        expect(controller.currentStroke, 1);
      });

      test('Wrong stroke does not get accepted', () {
        controller.reset();
        controller.checkStroke(wrongStroke00);
        expect(controller.currentStroke, 0);
      });

      test('Inverse stroke does not get accepted', () {
        controller.reset();
        controller.checkStroke(inverseStroke00);
        expect(controller.currentStroke, 0);
      });
    });

    group('Quiz summary', () {
      controller.startQuiz();

      test('Summary is initially empty', () {
        controller.reset();
        controller2.reset();
        expect(controller.summary.nStrokes, 5);
        expect(controller2.summary.nStrokes, 7);
        expect(controller.summary.nTotalMistakes, 0);
        expect(controller.summary.mistakes[0], 0);
        expect(controller.summary.mistakes[4], 0);
      });

      test('Wrong stroke increases number of total mistakes', () {
        controller.reset();
        controller.checkStroke(wrongStroke00);
        expect(controller.summary.nTotalMistakes, 1);
        controller.checkStroke(wrongStroke00);
        expect(controller.summary.nTotalMistakes, 2);
      });

      test('Reset resets number of single and total mistakes', () {
        controller.checkStroke(wrongStroke00);
        controller.reset();
        expect(controller.summary.nTotalMistakes, 0);
        for (var nMistakes in controller.summary.mistakes) {
          expect(nMistakes, 0);
        }
      });

      test('Mistakes get counted separately for each stroke', () {
        controller.reset();
        controller.checkStroke(wrongStroke00);
        expect(controller.summary.mistakes[0], 1);

        controller.checkStroke(correctStroke00);
        controller.checkStroke(wrongStroke00);
        controller.checkStroke(wrongStroke00);
        expect(controller.summary.mistakes[0], 1);
        expect(controller.summary.mistakes[1], 2);
      });

      test('Summary gets reset when quiz starts', () {
        controller.reset();
        controller.checkStroke(wrongStroke00);
        controller.stopQuiz();
        controller.startQuiz();
        expect(controller.summary.nTotalMistakes, 0);
      });

      test('Empty stroke does not count as mistake', () {
        controller.reset();
        controller.checkStroke([]);
        expect(controller.summary.nTotalMistakes, 0);
      });

      test('Stroke of length 0 does not count as mistake', () {
        controller.reset();
        controller.checkStroke([Offset(0, 0), Offset(0, 0)]);
        expect(controller.summary.nTotalMistakes, 0);
      });

      group('Correct stroke paths get saved', () {
        test(
            'Summary has a list of stroke paths with length == number of strokes',
            () {
          controller.reset();
          expect(controller.summary.correctStrokePaths.length,
              controller.summary.nStrokes);
        });

        test('Every path is a list of Offsets', () {
          controller.reset();
          expect(
              controller.summary.correctStrokePaths[0] is List<Offset>, true);
        });

        test('Correct stroke gets added to the list', () {
          controller.reset();
          controller.checkStroke(correctStroke00);
          expect(controller.summary.correctStrokePaths[0].length > 0, true);
          expect(controller.summary.correctStrokePaths[0], correctStroke00);
        });

        test('Incorrect stroke does not get added to the list', () {
          controller.reset();
          controller.checkStroke(wrongStroke00);
          expect(controller.summary.correctStrokePaths[0].length, 0);
        });

        test('Reset resets saved stroke paths', () {
          controller.reset();
          controller.checkStroke(correctStroke00);
          controller.reset();
          expect(controller.summary.correctStrokePaths[0].length, 0);
        });
      });
    });

    group('Callbacks', () {
      final controller =
          StrokeOrderAnimationController(strokeOrders[5], tickerProvider);

      late QuizSummary summary1;
      int nCalledOnQuizComplete1 = 0;

      final onQuizComplete1 = (summary) {
        summary1 = summary;
        nCalledOnQuizComplete1++;
      };

      controller.addOnQuizCompleteCallback(onQuizComplete1);

      test('Summary gets passed to callback when quiz finishes', () {
        nCalledOnQuizComplete1 = 0;
        controller.startQuiz();
        controller.checkStroke(correctStroke50);
        controller.checkStroke(correctStroke51);
        controller.checkStroke(correctStroke52);
        expect(nCalledOnQuizComplete1, 1);
      });

      test('Summary passed to callback contains correct mistakes information',
          () {
        controller.startQuiz();
        controller.reset();
        controller.checkStroke(correctStroke50);
        controller.checkStroke(wrongStroke00);
        controller.checkStroke(wrongStroke00);
        controller.checkStroke(correctStroke51);
        controller.checkStroke(wrongStroke00);
        controller.checkStroke(correctStroke52);
        expect(summary1.nTotalMistakes, 3);
        expect(summary1.mistakes[0], 0);
        expect(summary1.mistakes[1], 2);
        expect(summary1.mistakes[2], 1);
      });

      test('Summary gets passed to additional callback', () {
        late QuizSummary summary2;
        int nCalledOnQuizComplete2 = 0;

        final onQuizComplete2 = (summary) {
          summary2 = summary;
          nCalledOnQuizComplete2++;
        };

        controller.addOnQuizCompleteCallback(onQuizComplete2);

        controller.startQuiz();
        controller.checkStroke(correctStroke50);
        controller.checkStroke(wrongStroke00);
        controller.checkStroke(wrongStroke00);
        controller.checkStroke(correctStroke51);
        controller.checkStroke(wrongStroke00);
        controller.checkStroke(correctStroke52);

        expect(nCalledOnQuizComplete2, 1);
        expect(summary1.nTotalMistakes, summary2.nTotalMistakes);
        expect(summary1.mistakes[0], summary2.mistakes[0]);
        expect(summary1.mistakes[1], summary2.mistakes[1]);
        expect(summary1.mistakes[2], summary2.mistakes[2]);
      });

      test('Callback gets called on wrong stroke with the current stroke index',
          () {
        int wrongStroke = -1;

        final onWrongStroke = (iStroke) {
          wrongStroke = iStroke;
        };

        controller.addOnWrongStrokeCallback(onWrongStroke);

        controller.startQuiz();
        controller.reset();
        controller.checkStroke(wrongStroke00);
        expect(wrongStroke, 0);
        controller.checkStroke(correctStroke50);
        controller.checkStroke(wrongStroke00);
        expect(wrongStroke, 1);
      });

      test(
          'Callback gets called on correct stroke with the current stroke index',
          () {
        int correctStroke = -1;

        final onCorrectStroke = (iStroke) {
          correctStroke = iStroke;
        };

        controller.addOnCorrectStrokeCallback(onCorrectStroke);

        controller.startQuiz();
        controller.reset();
        controller.checkStroke(correctStroke50);
        expect(correctStroke, 0);
        controller.checkStroke(correctStroke51);
        expect(correctStroke, 1);
      });
    });
  });
}
