import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:svg_path_parser/svg_path_parser.dart';

class CharacterAnimator extends StatefulWidget {
  final String strokeOrder;

  CharacterAnimator(this.strokeOrder);

  @override
  _CharacterAnimatorState createState() => _CharacterAnimatorState();
}

class _CharacterAnimatorState extends State<CharacterAnimator>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  bool isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    setState(() {
      isAnimating = true;
      _controller.stop();
      _controller.reset();
      _controller.forward();
    });
  }

  void _stopAnimation() {
    setState(() {
      _controller.stop();
      isAnimating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var parsedJson = json.decode(widget.strokeOrder.replaceAll("'", '"'));

    final List<Path> strokes = List.generate(
        parsedJson['strokes'].length,
        (index) => parseSvgPath(parsedJson['strokes'][index]).transform(
            Matrix4(1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 0, 900, 0, 1)
                .storage));

    final medians = List.generate(parsedJson['medians'].length, (iStroke) {
      return List.generate(parsedJson['medians'][iStroke].length, (iPoint) {
        return List<int>.generate(
            parsedJson['medians'][iStroke][iPoint].length,
            (iCoordinate) => iCoordinate == 0
                ? parsedJson['medians'][iStroke][iPoint][iCoordinate]
                : parsedJson['medians'][iStroke][iPoint][iCoordinate] * -1 +
                    900);
      });
    });

    return Column(
      children: <Widget>[
        Text('Number of strokes: ' + strokes.length.toString()),
        Stack(
          children: <Widget>[
            ...List.generate(
              strokes.length,
              (index) => FittedBox(
                child: SizedBox(
                  width: 1024,
                  height: 1024,
                  child: CustomPaint(
                      painter: StrokePainter(strokes[index],
                          showStroke: true,
                          strokeColor: Colors.blue,
                          showOutline: true,
                          outlineColor: Colors.red,
                          showMedian: true,
                          medianColor: Colors.black,
                          animate: isAnimating,
                          animation: _controller,
                          median: medians[index])),
                ),
              ),
            ),
          ],
        ),
        if (!isAnimating)
          MaterialButton(
            onPressed: () {
              _startAnimation();
            },
            child: Text("Start animation"),
          ),
        if (isAnimating)
          MaterialButton(
            onPressed: () {
              _stopAnimation();
            },
            child: Text("Stop animation"),
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
      ..strokeWidth = 4.0
      ..style = PaintingStyle.fill;

    if (showStroke) {
      if (animate == true && animation != null && median[0].isNotEmpty) {
        if (strokeStart.isNotEmpty && strokeEnd.isNotEmpty) {
          // Split the original path into two paths that follow the outline 
          // of the stroke from strokeStart to strokeEnd clockwise and counter-clockwise
          List<Path> contourPaths = extractContourPaths(strokeOutlinePath, strokeStart, strokeEnd);
          
          
          
          
          
          
          Path brush = Path();
            brush.addArc(
                Rect.fromCenter(
                    center: Offset(strokeStart[0], strokeStart[1]),
                    width: 50,
                    height: 50),
                0,
                2 * pi);
            brush.addArc(
                Rect.fromCenter(
                    center: Offset(strokeEnd[0], strokeEnd[1]),
                    width: 50,
                    height: 50),
                0,
                2 * pi);
            canvas.drawPath(brush, Paint()..style = PaintingStyle.stroke);
        }
      } else {
        canvas.drawPath(strokeOutlinePath, strokePaint);
      }
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

List<Path> extractContourPaths(strokeOutlinePath, strokeStart, strokeEnd) {

  return [];
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
    final distance = distance2D(point, queryPoint.map((e) => e.toDouble()).toList());
    if (distance < minDistance) {
      minDistance = distance;
      closestPoint = [point[0], point[1], iPoint*stepSize];
    }
  }

  return closestPoint;
}

double distance2D(List<double> p, List<double> q) {
  return sqrt(pow(p[0] - q[0], 2) + pow(p[1] - q[1], 2));
}
