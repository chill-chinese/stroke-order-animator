import 'package:flutter/material.dart';

/// A custom painter for drawing brush strokes.
class Brush extends CustomPainter {
  Brush(
    this.points, {
    required this.brushColor,
    required this.brushWidth,
  });
  final List<Offset> points;
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
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }
}
