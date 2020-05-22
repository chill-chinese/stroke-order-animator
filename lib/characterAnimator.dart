import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:svg_path_parser/svg_path_parser.dart';

class CharacterAnimator extends StatelessWidget {
  final String strokeOrder;

  CharacterAnimator(this.strokeOrder);

  @override
  Widget build(BuildContext context) {
    var parsedJson = json.decode(strokeOrder.replaceAll("'", '"'));

    final List<Path> strokes = List.generate(
        parsedJson['strokes'].length,
        (index) => parseSvgPath(parsedJson['strokes'][index]).transform(
            Matrix4(1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 0, 900, 0, 1)
                .storage));

    return Column(
      children: <Widget>[
        // Text('Number of strokes: ' + parsedJson['strokes'].length.toString() + '\nFirst stroke: ' + parsedJson['strokes'][0]),
        Expanded(
            child: Stack(
          children: <Widget>[
            ...List.generate(
              strokes.length,
              (index) => FittedBox(
                child: SizedBox(
                  width: 1024,
                  height: 1024,
                  child: CustomPaint(
                      painter: MyPainter(strokes[index], Colors.blue, showPath: false)),
                ),
              ),
            ),
          ],
        ))
      ],
    );
  }
}

class MyPainter extends CustomPainter {
  final Path path;
  final Color color;
  final bool showPath;
  MyPainter(this.path, this.color, {this.showPath = true});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 4.0;
    canvas.drawPath(path, paint);
    if (showPath) {
      var border = Paint()
        ..color = Colors.black
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, border);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
