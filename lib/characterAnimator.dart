import 'dart:convert';
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
                painter: StrokePainter(strokes[0], strokeColor: Colors.blue, outlineColor: Colors.red,
                    animate: true, animation: _controller, showOutline: true)),
          ),
        ),
      ],
    );
  }
}

class StrokePainter extends CustomPainter {
  final bool animate;
  final Animation<double> animation;
  final Path strokeOutlinePath;
  final Color strokeColor;
  final Color outlineColor;
  final bool showOutline;

  StrokePainter(
    this.strokeOutlinePath, {
    this.strokeColor = Colors.grey,
    this.showOutline = false,
    this.outlineColor = Colors.black,
    this.animate = false,
    this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    var strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 4.0
      ..style = PaintingStyle.fill;

    if (animate == true && animation != null) {
      PathMetric pathMetric = strokeOutlinePath.computeMetrics().toList()[0];
      double pathLength = pathMetric.length;
      double pathLengthFraction = animation.value / 2 * pathLength;

      Path startPath = pathMetric.extractPath(0, pathLengthFraction);
      Path endPath =
          pathMetric.extractPath(pathLength - pathLengthFraction, pathLength);

      Path drawPath = Path.combine(PathOperation.union, startPath, endPath);
      canvas.drawPath(drawPath, strokePaint);
    }
    else {
      canvas.drawPath(strokeOutlinePath, strokePaint);
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
