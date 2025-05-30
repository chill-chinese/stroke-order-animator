import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stroke_order_animator/src/distance_2_d.dart';
import 'package:stroke_order_animator/stroke_order_animator.dart';

import 'resources/test_strokes.dart';

void main() {
  const tickerProvider = TestVSync();
  debugSemanticsDisableAnimations = true;

  test('Test 2D distance', () {
    const point1 = Offset.zero;
    const point2 = Offset(1.0, 1.0);
    const point3 = Offset(-1.0, -1.0);
    const point4 = Offset(-1.0, 1.0);

    expect(distance2D(point1, point1), 0);
    expect(distance2D(point1, point2), sqrt(2));
    expect(distance2D(point1, point3), sqrt(2));
    expect(distance2D(point1, point4), sqrt(2));
    expect(distance2D(point2, point1), sqrt(2));
    expect(distance2D(point2, point3), 2 * sqrt(2));
    expect(distance2D(point2, point4), 2);
    expect(distance2D(point3, point1), sqrt(2));
    expect(distance2D(point3, point2), 2 * sqrt(2));
    expect(distance2D(point3, point4), 2);
    expect(distance2D(point4, point1), sqrt(2));
    expect(distance2D(point4, point2), 2);
    expect(distance2D(point4, point3), 2);
    expect(distance2D(point4, point4), 0);
  });

  group('Test strokes written by user', () {
    testWidgets(
        'There are brush strokes according to the number of correct strokes',
        (WidgetTester tester) async {
      final controller = StrokeOrderAnimationController(
        StrokeOrder(strokeOrderJsons['永']!),
        tickerProvider,
      );

      controller.startQuiz();
      controller.setShowOutline(false);
      controller.setShowUserStroke(true);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StrokeOrderAnimator(controller),
        ),
      );

      final customPaintFinder = find.byType(CustomPaint);
      // Only the character itself is painted
      expect(customPaintFinder, findsNWidgets(1));

      // One correct stroke
      controller.checkStroke(correctStroke00);
      await tester.pump();
      expect(customPaintFinder, findsNWidgets(1 + 1));

      // One incorrect stroke
      controller.checkStroke(wrongStroke00);
      await tester.pump();
      expect(customPaintFinder, findsNWidgets(1 + 1));

      // One more correct stroke
      controller.checkStroke(correctStroke01);
      await tester.pump();
      expect(customPaintFinder, findsNWidgets(1 + 2));
    });

    testWidgets('Strokes stay on screen after quiz finished',
        (WidgetTester tester) async {
      final controller = StrokeOrderAnimationController(
        StrokeOrder(strokeOrderJsonForQuizTests),
        tickerProvider,
      );

      controller.startQuiz();
      controller.setShowOutline(false);
      controller.setShowUserStroke(true);

      controller.checkStroke(correctStroke50);
      controller.checkStroke(correctStroke51);
      controller.checkStroke(correctStroke52);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StrokeOrderAnimator(controller),
        ),
      );

      await tester.pump();
      final customPaintFinder = find.byType(CustomPaint);
      expect(customPaintFinder, findsNWidgets(1 + 3));
    });

    testWidgets('Strokes stay on screen only if enabled',
        (WidgetTester tester) async {
      final controller = StrokeOrderAnimationController(
        StrokeOrder(strokeOrderJsonForQuizTests),
        tickerProvider,
      );

      controller.startQuiz();
      controller.setShowOutline(false);

      controller.checkStroke(correctStroke50);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StrokeOrderAnimator(controller),
        ),
      );

      await tester.pump();
      final Finder customPaintFinder = find.byType(CustomPaint);
      // Only the character itself is painted
      expect(customPaintFinder, findsNWidgets(1));

      controller.setShowUserStroke(true);
      await tester.pump();
      expect(customPaintFinder, findsNWidgets(1 + 1));
    });
  });
}
