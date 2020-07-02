import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:stroke_order_animator/strokeOrderAnimator.dart';

void main() {
  final point1 = Offset(0.0, 0.0);
  final point2 = Offset(1.0, 1.0);
  final point3 = Offset(-1.0, -1.0);
  final point4 = Offset(-1.0, 1.0);

  test("Test 2D distance", () {
    expect(distance2D(point1, point1), 0);
    expect(distance2D(point1, point2), sqrt(2));
    expect(distance2D(point1, point3), sqrt(2));
    expect(distance2D(point1, point4), sqrt(2));
    expect(distance2D(point2, point1), sqrt(2));
    expect(distance2D(point2, point3), 2*sqrt(2));
    expect(distance2D(point2, point4), 2);
    expect(distance2D(point3, point1), sqrt(2));
    expect(distance2D(point3, point2), 2*sqrt(2));
    expect(distance2D(point3, point4), 2);
    expect(distance2D(point4, point1), sqrt(2));
    expect(distance2D(point4, point2), 2);
    expect(distance2D(point4, point3), 2);
    expect(distance2D(point4, point4), 0);
  });
}