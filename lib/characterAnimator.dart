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
    _controller.stop();
    _controller.reset();
    _controller.repeat(
      period: Duration(seconds: 5),
    );
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
        MaterialButton(
          onPressed: () {
            _startAnimation();
          },
          child: Text("Animate"),
        ),
        FittedBox(
          child: SizedBox(
            width: 1024,
            height: 1024,
            child: CustomPaint(
                painter: StrokePainter(strokes[0],
                    showStroke: true,
                    strokeColor: Colors.blue,
                    showOutline: true,
                    outlineColor: Colors.red,
                    animate: true,
                    animation: _controller,
                    median: medians[0])),
          ),
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
  final bool showOutline;
  final bool showStroke;
  final List<List<int>> median;

  Path visibleStroke = Path();
  Path medianPath;

  StrokePainter(
    this.strokeOutlinePath, {
    this.showStroke = true,
    this.strokeColor = Colors.grey,
    this.showOutline = false,
    this.outlineColor = Colors.black,
    this.animate = false,
    this.animation,
    this.median = const [<int>[]],
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {

    if (medianPath == null) {
      medianPath = Path();
      medianPath.moveTo(median[0][0].toDouble(), median[0][1].toDouble());
      for (var point in median) {
        medianPath.lineTo(point[0].toDouble(), point[1].toDouble());
      }
    }

    var strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 4.0
      ..style = PaintingStyle.fill;

    if (showStroke) {
      if (animate == true && animation != null && median[0].isNotEmpty) {
        Path brush = Path();
        brush.addArc(
            Rect.fromCenter(
                center: Offset(median[0][0].toDouble(),
                    median[0][1].toDouble() + 100 * animation.value),
                width: 50,
                height: 50),
            0,
            2 * pi);
        canvas.drawPath(brush, Paint()..style = PaintingStyle.stroke);
        canvas.drawPath(medianPath, Paint()..style = PaintingStyle.stroke);

        // Combine (union) the current intersection of brush and stroke with what was previously drawn
        visibleStroke = Path.combine(PathOperation.union, visibleStroke,
            Path.combine(PathOperation.intersect, brush, strokeOutlinePath));

        canvas.drawPath(visibleStroke, strokePaint);
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
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
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
