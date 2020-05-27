import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:stroke_order_animator/strokeOrderAnimationController.dart';

class StrokeOrderAnimator extends StatefulWidget {
  final StrokeOrderAnimationController _controller;

  StrokeOrderAnimator(this._controller);

  @override
  _StrokeOrderAnimatorState createState() => _StrokeOrderAnimatorState();
}

class _StrokeOrderAnimatorState extends State<StrokeOrderAnimator> {
  static AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = widget._controller.animationController;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Stack(
          children: <Widget>[
            ...List.generate(
              widget._controller.strokes.length,
              (index) => FittedBox(
                child: SizedBox(
                  width: 1024,
                  height: 1024,
                  child: CustomPaint(
                      painter: StrokePainter(widget._controller.strokes[index],
                          showStroke: widget._controller.showStroke &&
                              index < widget._controller.currentStroke,
                          strokeColor: widget._controller.strokeColor,
                          showOutline: widget._controller.showOutline &&
                              widget._controller.showOutline,
                          outlineColor: widget._controller.outlineColor,
                          showMedian: widget._controller.showMedian,
                          medianColor: widget._controller.medianColor,
                          animate: widget._controller.isAnimating &&
                              index == widget._controller.currentStroke,
                          animation: _animationController,
                          median: widget._controller.medians[index])),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class StrokePainter extends CustomPainter {
  // If the stroke should be animated, an animation and the median have to be provided
  final bool animate;
  final Animation<double> animation;
  final Path strokeOutlinePath;
  final Color strokeColor;
  final Color outlineColor;
  final Color medianColor;
  final bool showOutline;
  final bool showStroke;
  final bool showMedian;
  final List<List<int>> median;

  List<double> strokeStart = [];
  List<double> strokeEnd = [];

  Path visibleStroke = Path();

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
    this.median = const [<int>[]],
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (strokeStart.isEmpty) {
      // Calculate the points on strokeOutlinePath that are closest to the start and end points of the median
      strokeStart = getClosestPointOnPath(strokeOutlinePath, median.first);
      strokeEnd = getClosestPointOnPath(strokeOutlinePath, median.last);
    }

    var strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    if (animate == true && animation != null && median[0].isNotEmpty) {
      if (strokeStart.isNotEmpty && strokeEnd.isNotEmpty) {
        // Split the original path into two paths that follow the outline
        // of the stroke from strokeStart to strokeEnd clockwise and counter-clockwise
        List<Path> contourPaths = extractContourPaths(
            strokeOutlinePath, strokeStart.last, strokeEnd.last);

        // Go on the first contourPath first, then jump over to the second path and go back to the start
        final lenFirstPath = contourPaths.first.computeMetrics().first.length;
        final lenSecondPath = contourPaths.last.computeMetrics().first.length;

        Path finalOutlinePath = contourPaths.first
            .computeMetrics()
            .first
            .extractPath(0, animation.value * lenFirstPath);
        finalOutlinePath.extendWithPath(
            contourPaths.last.computeMetrics().first.extractPath(
                lenSecondPath - animation.value * lenSecondPath, lenSecondPath),
            Offset(0, 0));

        canvas.drawPath(finalOutlinePath, strokePaint);
      }
    } else if (showStroke) {
      canvas.drawPath(strokeOutlinePath, strokePaint);
    }

    if (showOutline) {
      var borderPaint = Paint()
        ..color = outlineColor
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(strokeOutlinePath, borderPaint);
    }

    if (showMedian) {
      final medianPath = Path();
      medianPath.moveTo(median[0][0].toDouble(), median[0][1].toDouble());
      for (var point in median) {
        medianPath.lineTo(point[0].toDouble(), point[1].toDouble());
      }
      canvas.drawPath(
          medianPath,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = medianColor);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

List<Path> extractContourPaths(
    Path strokeOutlinePath, double strokeStartLength, double strokeEndLength) {
  Path path1 = Path();
  Path path2 = Path();

  final metrics = strokeOutlinePath.computeMetrics().toList()[0];

  if (strokeEndLength > strokeStartLength) {
    path1 = metrics.extractPath(strokeStartLength, strokeEndLength);
    path2 = metrics.extractPath(strokeEndLength, metrics.length);
    path2.extendWithPath(
        metrics.extractPath(0, strokeStartLength), Offset(0, 0));
  } else {
    path1 = metrics.extractPath(strokeStartLength, metrics.length);
    path1.extendWithPath(metrics.extractPath(0, strokeEndLength), Offset(0, 0));
    path2 = metrics.extractPath(strokeEndLength, strokeStartLength);
  }

  // path1 leads from start to end, path2 continues from end to start
  return [path1, path2];
}

List<double> getClosestPointOnPath(Path path, List<int> queryPoint) {
  PathMetric metrics = path.computeMetrics().toList()[0];

  int nSteps = 100;
  double pathLength = metrics.length;
  double stepSize = pathLength / nSteps;

  List<List<double>> pointsOnPath = [];

  double minDistance = double.infinity;

  // x, y, and length on the path where that point lies
  List<double> closestPoint = [0, 0, 0];

  // Sample nSteps points on the path
  for (var step = 0.0; step < pathLength; step += stepSize) {
    final tangent = metrics.getTangentForOffset(step);
    pointsOnPath.add([tangent.position.dx, tangent.position.dy]);
  }

  // Find the point on the path closest to the query
  for (var iPoint = 0; iPoint < pointsOnPath.length; iPoint++) {
    final point = pointsOnPath[iPoint];
    final distance =
        distance2D(point, queryPoint.map((e) => e.toDouble()).toList());
    if (distance < minDistance) {
      minDistance = distance;
      closestPoint = [point[0], point[1], iPoint * stepSize];
    }
  }

  return closestPoint;
}

double distance2D(List<double> p, List<double> q) {
  return sqrt(pow(p[0] - q[0], 2) + pow(p[1] - q[1], 2));
}
