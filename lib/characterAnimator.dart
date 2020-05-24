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
      _controller.repeat(
        period: Duration(seconds: 5),
      );
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

  Path visibleStroke = Path();
  CostumPath customMedianPath;

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
    if (customMedianPath == null) {
      customMedianPath = CostumPath(median);
    }

    var strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 4.0
      ..style = PaintingStyle.fill;

    if (showStroke) {
      if (animate == true && animation != null && median[0].isNotEmpty) {
        final brushPosition = customMedianPath
            .getCoordinatesAt(animation.value * customMedianPath.pathLength);

        Path brush = Path();
        brush.addArc(
            Rect.fromCenter(
                center: Offset(brushPosition[0], brushPosition[1]),
                width: 50,
                height: 50),
            0,
            2 * pi);
        canvas.drawPath(brush, Paint()..style = PaintingStyle.stroke);

        // Combine (union) the current intersection of brush and stroke with what was previously drawn
        // visibleStroke = Path.combine(PathOperation.union, visibleStroke,
        //     Path.combine(PathOperation.intersect, brush, strokeOutlinePath));

        canvas.drawPath(
            Path.combine(PathOperation.intersect, brush, strokeOutlinePath),
            strokePaint);
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

class CostumPath {
  // final List<List<int>> median;
  final List<Segment> _segments = [];
  final List<double> _segmentStartLengths = [0];

  double pathLength = 0;

  CostumPath(List<List<int>> median) {
    // Split the stroke into segments
    // Every segment has start and end position and a length
    for (var iSegment = 0; iSegment < median.length - 1; iSegment++) {
      _segments.add(Segment([
        median[iSegment][0].toDouble(),
        median[iSegment][1].toDouble()
      ], [
        median[iSegment + 1][0].toDouble(),
        median[iSegment + 1][1].toDouble()
      ]));
    }

    for (var iSegment = 1; iSegment < _segments.length; iSegment++) {
      _segmentStartLengths.add(
          _segmentStartLengths[iSegment - 1] + _segments[iSegment - 1].length);
    }

    pathLength = _segmentStartLengths.last + _segments.last.length;
  }

  // Return the coordinates of the point at a given percentage of the whole path
  List<double> getCoordinatesAt(double length) {
    length = length.clamp(0, pathLength - 0.1);

    for (var iSegment = 0; iSegment < _segments.length; iSegment++) {
      final segment = _segments[iSegment];
      final segmentStartLength = _segmentStartLengths[iSegment];

      // Check if queried length is on the segment
      if (segmentStartLength + segment.length > length) {
        final fractionOfSegment =
            (length - segmentStartLength) / segment.length;

        final xOffset = (segment.end[0] - segment.start[0]) * fractionOfSegment;
        final yOffset = (segment.end[1] - segment.start[1]) * fractionOfSegment;

        return [segment.start[0] + xOffset, segment.start[1] + yOffset];
      }
    }

    return [0, 0];
  }
}

class Segment {
  final List<double> start;
  final List<double> end;
  double length;
  Segment(this.start, this.end) {
    length = sqrt(pow((end[0] - start[0]), 2) + pow((end[1] - start[1]), 2));
  }
}

// showCharacter(List<Path> strokes, Color color) {
//   return Expanded(
//       child: Stack(
//     children: <Widget>[
//       ...List.generate(
//         strokes.length,
//         (index) => FittedBox(
//           child: SizedBox(
//             width: 1024,
//             height: 1024,
//             child: CustomPaint(painter: StrokePainter(strokes[index], color)),
//           ),
//         ),
//       ),
//     ],
//   ));
// }
