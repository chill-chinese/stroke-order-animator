// Keep the file name as is to avoid breaking the package
// ignore_for_file: file_names

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:stroke_order_animator/stroke_order_animation_controller.dart';

/// A widget for displaying a stroke order diagram.
/// Takes a `StrokeOrderAnimationController` as argument.
class StrokeOrderAnimator extends StatefulWidget {
  const StrokeOrderAnimator(this._controller, {super.key});
  final StrokeOrderAnimationController _controller;

  @override
  StrokeOrderAnimatorState createState() => StrokeOrderAnimatorState();
}

class StrokeOrderAnimatorState extends State<StrokeOrderAnimator> {
  List<Offset?> _points = <Offset>[];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (DragUpdateDetails details) {
        setState(() {
          final RenderBox box = context.findRenderObject()! as RenderBox;
          final Offset point = box.globalToLocal(details.globalPosition);

          if (point.dx >= 0 &&
              point.dx <= box.size.width &&
              point.dy >= 0 &&
              point.dy <= box.size.height) {
            _points = List.from(_points)..add(point);
          } else {
            if (_points.last != null) {
              _points = List.from(_points)..add(null);
            }
          }
        });
      },
      onPanEnd: (DragEndDetails details) {
        widget._controller.checkStroke(_points);
        setState(() {
          _points.clear();
        });
      },
      child: Stack(
        children: <Widget>[
          ...List.generate(widget._controller.strokeOrder.nStrokes, (index) {
            // Determine whether to use standard stroke color, radical color or hint color
            Color strokeColor = widget._controller.strokeColor;

            if (widget._controller.highlightRadical &&
                widget._controller.strokeOrder.radicalStrokeIndices
                    .contains(index)) {
              strokeColor = widget._controller.radicalColor;
            }

            if (widget._controller.isQuizzing &&
                index == widget._controller.currentStroke) {
              strokeColor = widget._controller.hintColor;
            }

            final animate = index == widget._controller.currentStroke &&
                (widget._controller.isAnimating ||
                    widget._controller.isQuizzing);
            final animationController = widget._controller.isQuizzing
                ? widget._controller.hintAnimationController
                : widget._controller.strokeAnimationController;

            return SizedBox(
              width: 1024,
              height: 1024,
              child: CustomPaint(
                painter: StrokePainter(
                  widget._controller.strokeOrder.strokeOutlines[index],
                  showStroke: widget._controller.showStroke &&
                      index < widget._controller.currentStroke,
                  strokeColor: strokeColor,
                  showOutline: widget._controller.showOutline,
                  outlineColor: widget._controller.outlineColor,
                  showMedian: widget._controller.showMedian,
                  medianColor: widget._controller.medianColor,
                  animate: animate,
                  animation: animationController,
                  median: widget._controller.strokeOrder.medians[index],
                ),
              ),
            );
          }),
          if (widget._controller.showUserStroke)
            ...paintCorrectStrokes(
              widget._controller.summary.correctStrokePaths,
              brushColor: widget._controller.brushColor,
              brushWidth: widget._controller.brushWidth,
            ),
          if (widget._controller.isQuizzing)
            CustomPaint(
              painter: Brush(
                _points,
                brushColor: widget._controller.brushColor,
                brushWidth: widget._controller.brushWidth,
              ),
            ),
        ],
      ),
    );
  }

  List<CustomPaint> paintCorrectStrokes(
    List<List<Offset>> correctStrokePaths, {
    Color brushColor = Colors.black,
    double brushWidth = 8,
  }) {
    final List<CustomPaint> brushStrokes = [];

    for (final strokePath in correctStrokePaths) {
      if (strokePath.isNotEmpty) {
        brushStrokes.add(
          CustomPaint(
            painter: Brush(
              strokePath,
              brushColor: brushColor,
              brushWidth: brushWidth,
            ),
          ),
        );
      }
    }

    return brushStrokes;
  }
}

class StrokePainter extends CustomPainter {
  StrokePainter(
    this.strokeOutlinePath, {
    this.showStroke = true,
    this.strokeColor = Colors.grey,
    this.showOutline = false,
    this.outlineColor = Colors.black,
    this.showMedian = false,
    this.medianColor = Colors.black,
    this.animate = false,
    this.animation,
    this.median = const [],
  }) : super(repaint: animation);
  // If the stroke should be animated, an animation and the median have to be provided
  final bool animate;
  final Animation<double>? animation;
  final Path strokeOutlinePath;
  final Color strokeColor;
  final Color outlineColor;
  final Color medianColor;
  final bool showOutline;
  final bool showStroke;
  final bool showMedian;
  final List<Offset> median;

  double strokeStart = -1;
  double strokeEnd = -1;

  Path visibleStroke = Path();

  @override
  void paint(Canvas canvas, Size size) {
    if (strokeStart < 0) {
      // Calculate the points on strokeOutlinePath that are closest to the start and end points of the median
      strokeStart = getClosestPointOnPathAsDistanceOnPath(
        strokeOutlinePath,
        median.first,
      );
      strokeEnd =
          getClosestPointOnPathAsDistanceOnPath(strokeOutlinePath, median.last);
    }

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    if (animate == true && median.isNotEmpty) {
      if (strokeStart >= 0 && strokeEnd >= 0) {
        // Split the original path into two paths that follow the outline
        // of the stroke from strokeStart to strokeEnd clockwise and counter-clockwise
        final List<Path> contourPaths =
            extractContourPaths(strokeOutlinePath, strokeStart, strokeEnd);

        // Go on the first contourPath first, then jump over to the second path and go back to the start
        final lenFirstPath = contourPaths.first.computeMetrics().first.length;
        final lenSecondPath = contourPaths.last.computeMetrics().first.length;

        final Path finalOutlinePath = contourPaths.first
            .computeMetrics()
            .first
            .extractPath(0, (animation?.value ?? 1) * lenFirstPath);
        finalOutlinePath.extendWithPath(
          contourPaths.last.computeMetrics().first.extractPath(
                lenSecondPath - (animation?.value ?? 1) * lenSecondPath,
                lenSecondPath,
              ),
          Offset.zero,
        );

        canvas.drawPath(finalOutlinePath, strokePaint);
      }
    } else if (showStroke) {
      canvas.drawPath(strokeOutlinePath, strokePaint);
    }

    if (showOutline) {
      final borderPaint = Paint()
        ..color = outlineColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(strokeOutlinePath, borderPaint);
    }

    if (showMedian) {
      final medianPath = Path();
      medianPath.moveTo(median[0].dx, median[0].dy);
      for (final point in median) {
        medianPath.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        medianPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = medianColor,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

List<Path> extractContourPaths(
  Path strokeOutlinePath,
  double strokeStartLength,
  double strokeEndLength,
) {
  Path path1 = Path();
  Path path2 = Path();

  final metrics = strokeOutlinePath.computeMetrics().toList()[0];

  if (strokeEndLength > strokeStartLength) {
    path1 = metrics.extractPath(strokeStartLength, strokeEndLength);
    path2 = metrics.extractPath(strokeEndLength, metrics.length);
    path2.extendWithPath(
      metrics.extractPath(0, strokeStartLength),
      Offset.zero,
    );
  } else {
    path1 = metrics.extractPath(strokeStartLength, metrics.length);
    path1.extendWithPath(
      metrics.extractPath(0, strokeEndLength),
      Offset.zero,
    );
    path2 = metrics.extractPath(strokeEndLength, strokeStartLength);
  }

  // path1 leads from start to end, path2 continues from end to start
  return [path1, path2];
}

double getClosestPointOnPathAsDistanceOnPath(Path path, Offset queryPoint) {
  final PathMetric metrics = path.computeMetrics().toList()[0];

  const int nSteps = 100;
  final double pathLength = metrics.length;
  final double stepSize = pathLength / nSteps;

  final List<Offset> pointsOnPath = [];

  double minDistance = double.infinity;

  // x, y, and length on the path where that point lies
  double closestPoint = -1;

  // Sample nSteps points on the path
  for (var step = 0.0; step < pathLength; step += stepSize) {
    final tangent = metrics.getTangentForOffset(step)!;
    pointsOnPath.add(tangent.position);
  }

  // Find the point on the path closest to the query
  for (var iPoint = 0; iPoint < pointsOnPath.length; iPoint++) {
    final point = pointsOnPath[iPoint];
    final distance = distance2D(point, queryPoint);
    if (distance < minDistance) {
      minDistance = distance;
      closestPoint = iPoint * stepSize;
    }
  }

  return closestPoint;
}

double distance2D(Offset p, Offset q) {
  return sqrt(pow(p.dx - q.dx, 2) + pow(p.dy - q.dy, 2));
}

class Brush extends CustomPainter {
  Brush(
    this.points, {
    this.brushColor = Colors.black,
    this.brushWidth = 8.0,
  });
  final List<Offset?> points;
  final Color brushColor;
  final double brushWidth;

  @override
  bool shouldRepaint(Brush oldDelegate) {
    return oldDelegate.points != points;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = brushColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = brushWidth;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }
}
