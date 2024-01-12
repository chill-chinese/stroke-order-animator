import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stroke_order_animator/strokeOrderAnimationController.dart';
import 'package:stroke_order_animator/stroke_order.dart';

import 'test_strokes.dart';

void main() {
  const tickerProvider = TestVSync();
  debugSemanticsDisableAnimations = true;

  test('Assign new stroke order to existing controller', () {
    final controller = StrokeOrderAnimationController(
      StrokeOrder(strokeOrderJsons['永']!),
      tickerProvider,
    );

    // Check that current stroke gets reset
    controller.nextStroke();
    expect(controller.currentStroke, 1);
    controller.strokeOrder = StrokeOrder(strokeOrderJsons['你']!);
    expect(controller.currentStroke, 0);

    // Check that quizzing gets reset
    controller.startQuiz();
    expect(controller.isQuizzing, true);
    controller.strokeOrder = StrokeOrder(strokeOrderJsons['永']!);
    expect(controller.isQuizzing, false);
  });

  group('Test animation controls', () {
    final controller = StrokeOrderAnimationController(
      StrokeOrder(strokeOrderJsons['永']!),
      tickerProvider,
    );

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
      expect(controller.currentStroke, controller.strokeOrder.nStrokes);
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
    final controller = StrokeOrderAnimationController(
      StrokeOrder(strokeOrderJsons['永']!),
      tickerProvider,
    );

    final controller2 = StrokeOrderAnimationController(
      StrokeOrder(strokeOrderJsons['你']!),
      tickerProvider,
    );

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
        for (final nMistakes in controller.summary.mistakes) {
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
        controller.checkStroke([Offset.zero, Offset.zero]);
        expect(controller.summary.nTotalMistakes, 0);
      });

      group('Correct stroke paths get saved', () {
        test(
            'Summary has a list of stroke paths with length == number of strokes',
            () {
          controller.reset();
          expect(
            controller.summary.correctStrokePaths.length,
            controller.summary.nStrokes,
          );
        });

        test('Correct stroke gets added to the list', () {
          controller.reset();
          controller.checkStroke(correctStroke00);
          expect(controller.summary.correctStrokePaths[0].isNotEmpty, true);
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
      final controller = StrokeOrderAnimationController(
        StrokeOrder(strokeOrderJsonForQuizTests),
        tickerProvider,
      );

      late QuizSummary summary1;
      int nCalledOnQuizComplete1 = 0;

      void onQuizComplete1(QuizSummary summary) {
        summary1 = summary;
        nCalledOnQuizComplete1++;
      }

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

        void onQuizComplete2(QuizSummary summary) {
          summary2 = summary;
          nCalledOnQuizComplete2++;
        }

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

        void onWrongStroke(int iStroke) {
          wrongStroke = iStroke;
        }

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

        void onCorrectStroke(int iStroke) {
          correctStroke = iStroke;
        }

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
