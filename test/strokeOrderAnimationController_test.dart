import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stroke_order_animator/strokeOrderAnimationController.dart';

import 'testStrokes.dart';

void main() {
  final tickerProvider = TestVSync();
  debugSemanticsDisableAnimations = true;

  test("Test stroke count", () {
    final controllers = List.generate(
      strokeOrders.length,
      (index) =>
          StrokeOrderAnimationController(strokeOrders[index], tickerProvider),
    );

    expect(controllers[0].nStrokes, 5);
    expect(controllers[1].nStrokes, 7);
    expect(controllers[2].nStrokes, 10);
    expect(controllers[3].nStrokes, 3);
    expect(controllers[4].nStrokes, 8);
    expect(controllers[5].nStrokes, 3);
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

    final wrongStroke0 = [Offset(0, 0), Offset(10, 10)];
    final correctStroke0 = [Offset(430, 80), Offset(540, 160)];
    final inverseStroke0 = [Offset(540, 160), Offset(430, 80)];

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
        controller.checkStroke(correctStroke0);
        expect(controller.currentStroke, 1);
      });

      test('Wrong stroke does not get accepted', () {
        controller.reset();
        controller.checkStroke(wrongStroke0);
        expect(controller.currentStroke, 0);
      });

      test('Inverse stroke does not get accepted', () {
        controller.reset();
        controller.checkStroke(inverseStroke0);
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
        controller.checkStroke(wrongStroke0);
        expect(controller.summary.nTotalMistakes, 1);
        controller.checkStroke(wrongStroke0);
        expect(controller.summary.nTotalMistakes, 2);
      });

      test('Reset resets number of single and total mistakes', () {
        controller.checkStroke(wrongStroke0);
        controller.reset();
        expect(controller.summary.nTotalMistakes, 0);
        for (var nMistakes in controller.summary.mistakes) {
          expect(nMistakes, 0);
        }
      });

      test('Mistakes get counted separately for each stroke', () {
        controller.reset();
        controller.checkStroke(wrongStroke0);
        expect(controller.summary.mistakes[0], 1);

        controller.checkStroke(correctStroke0);
        controller.checkStroke(wrongStroke0);
        controller.checkStroke(wrongStroke0);
        expect(controller.summary.mistakes[0], 1);
        expect(controller.summary.mistakes[1], 2);
      });

      test('Summary gets reset when quiz starts', () {
        controller.reset();
        controller.checkStroke(wrongStroke0);
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
          controller.checkStroke([Offset(430, 80), Offset(540, 160)]);
          expect(controller.summary.correctStrokePaths[0].length > 0, true);
          expect(controller.summary.correctStrokePaths[0],
              [Offset(430, 80), Offset(540, 160)]);
        });

        test('Incorrect stroke does not get added to the list', () {
          controller.reset();
          controller.checkStroke([Offset(0, 0), Offset(0, 1)]);
          expect(controller.summary.correctStrokePaths[0].length, 0);
        });

        test('Reset resets saved stroke paths', () {
          controller.reset();
          controller.checkStroke([Offset(430, 80), Offset(540, 160)]);
          controller.reset();
          expect(controller.summary.correctStrokePaths[0].length, 0);
        });
      });
    });

    group('Callbacks', () {
      final controller =
          StrokeOrderAnimationController(strokeOrders[5], tickerProvider);

      final correctStroke0 = [Offset(316, 245), Offset(722, 208)];
      final correctStroke1 = [Offset(331, 493), Offset(700, 468)];
      final correctStroke2 = [Offset(127, 748), Offset(955, 726)];

      QuizSummary summary1;
      int nCalledOnQuizComplete1 = 0;

      final onQuizComplete1 = (summary) {
        summary1 = summary;
        nCalledOnQuizComplete1++;
      };

      controller.addOnQuizCompleteCallback(onQuizComplete1);

      test('Summary gets passed to callback when quiz finishes', () {
        nCalledOnQuizComplete1 = 0;
        controller.startQuiz();
        controller.checkStroke(correctStroke0);
        controller.checkStroke(correctStroke1);
        controller.checkStroke(correctStroke2);
        expect(nCalledOnQuizComplete1, 1);
      });

      test('Summary passed to callback contains correct mistakes information',
          () {
        controller.startQuiz();
        controller.reset();
        controller.checkStroke(correctStroke0);
        controller.checkStroke(wrongStroke0);
        controller.checkStroke(wrongStroke0);
        controller.checkStroke(correctStroke1);
        controller.checkStroke(wrongStroke0);
        controller.checkStroke(correctStroke2);
        expect(summary1.nTotalMistakes, 3);
        expect(summary1.mistakes[0], 0);
        expect(summary1.mistakes[1], 2);
        expect(summary1.mistakes[2], 1);
      });

      test('Summary gets passed to additional callback', () {
        QuizSummary summary2;
        int nCalledOnQuizComplete2 = 0;

        final onQuizComplete2 = (summary) {
          summary2 = summary;
          nCalledOnQuizComplete2++;
        };

        controller.addOnQuizCompleteCallback(onQuizComplete2);

        controller.startQuiz();
        controller.checkStroke(correctStroke0);
        controller.checkStroke(wrongStroke0);
        controller.checkStroke(wrongStroke0);
        controller.checkStroke(correctStroke1);
        controller.checkStroke(wrongStroke0);
        controller.checkStroke(correctStroke2);

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
        controller.checkStroke(wrongStroke0);
        expect(wrongStroke, 0);
        controller.checkStroke(correctStroke0);
        controller.checkStroke(wrongStroke0);
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
        controller.checkStroke(correctStroke0);
        expect(correctStroke, 0);
        controller.checkStroke(correctStroke1);
        expect(correctStroke, 1);
      });
    });
  });
}
