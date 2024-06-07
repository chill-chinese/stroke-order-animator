import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:stroke_order_animator/src/distance_2_d.dart';
import 'package:stroke_order_animator/src/stroke_order.dart';
import 'package:stroke_order_animator/src/stroke_order_animation_controller.dart';

final _contourCache = <StrokeOrder, List<(PathMetric, PathMetric)?>>{};

/// A custom painter for displaying a stroke order diagram.
///
/// The painter draws the stroke order diagram based on the provided
/// [StrokeOrderAnimationController].
class CharacterPainter extends CustomPainter {
  CharacterPainter(this.controller)
      : animationController = _getAnimationController(controller),
        shouldPaintStroke = _getWhichStrokesToPaint(controller),
        outlinePaint = Paint()
          ..color = controller.outlineColor
          ..strokeWidth = controller.outlineWidth
          ..style = PaintingStyle.stroke,
        backgroundPaint = Paint()
          ..color = controller.backgroundColor
          ..style = PaintingStyle.fill,
        medianPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = controller.medianWidth
          ..color = controller.medianColor,
        strokePaints = _getStrokePaints(controller),
        contourPaths = _getContourPaths(controller.strokeOrder),
        super(repaint: _getAnimationController(controller));

  final StrokeOrderAnimationController controller;

  final Animation<double>? animationController;

  final List<bool> shouldPaintStroke;

  final Paint outlinePaint;
  final Paint backgroundPaint;
  final List<Paint> strokePaints;
  final Paint medianPaint;

  final List<(PathMetric, PathMetric)?> contourPaths;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackgroundAndOutline(canvas, size);

    for (var i = 0; i < controller.strokeOrder.strokeOutlines.length; i++) {
      if (i == controller.currentStroke &&
          animationController != null &&
          contourPaths[i] != null) {
        _paintAnimatedStroke(canvas, size, i);
      } else if (shouldPaintStroke[i]) {
        _paintStroke(canvas, size, i);
      }

      if (controller.showMedian) {
        _paintMedian(canvas, size, i);
      }
    }
  }

  void _paintBackgroundAndOutline(Canvas canvas, Size size) {
    final outlines = controller.strokeOrder.strokeOutlines;
    for (var i = 0; i < outlines.length; i++) {
      // Paint the background and outline only for those strokes that are not
      // getting painted with the actual stroke color later
      if (!shouldPaintStroke[i]) {
        if (controller.showBackground) {
          canvas.drawPath(
            _scalePath(outlines[i], size),
            backgroundPaint,
          );
        }
        if (controller.showOutline) {
          canvas.drawPath(
            _scalePath(outlines[i], size),
            outlinePaint,
          );
        }
      }
    }
  }

  void _paintStroke(Canvas canvas, Size size, int i) {
    canvas.drawPath(
      _scalePath(controller.strokeOrder.strokeOutlines[i], size),
      strokePaints[i],
    );
    if (controller.showOutline) {
      canvas.drawPath(
        _scalePath(controller.strokeOrder.strokeOutlines[i], size),
        outlinePaint,
      );
    }
  }

  void _paintAnimatedStroke(Canvas canvas, Size size, int i) {
    final firstPath = contourPaths[i]!.$1;
    final secondPath = contourPaths[i]!.$2;

    final animationProgress = animationController?.value ?? 1;

    Path getFirstPathFragment() {
      return firstPath.extractPath(0, animationProgress * firstPath.length);
    }

    final secondPathFragment = secondPath.extractPath(
      secondPath.length - animationProgress * secondPath.length,
      secondPath.length,
    );

    canvas.drawPath(
      _scalePath(
        getFirstPathFragment()..extendWithPath(secondPathFragment, Offset.zero),
        size,
      ),
      strokePaints[i],
    );

    if (controller.showOutline) {
      canvas.drawPath(
        _scalePath(getFirstPathFragment(), size),
        outlinePaint,
      );
      canvas.drawPath(
        _scalePath(secondPathFragment, size),
        outlinePaint,
      );
    }
  }

  void _paintMedian(Canvas canvas, Size size, int i) {
    final medianPath = Path();
    medianPath.moveTo(
      controller.strokeOrder.medians[i][0].dx,
      controller.strokeOrder.medians[i][0].dy,
    );
    for (final point in controller.strokeOrder.medians[i]) {
      medianPath.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      _scalePath(medianPath, size),
      medianPaint,
    );
  }

  @override
  bool shouldRepaint(CharacterPainter oldDelegate) => true;
}

AnimationController? _getAnimationController(
  StrokeOrderAnimationController controller,
) {
  if (controller.isQuizzing) {
    return controller.hintAnimationController;
  }

  if (controller.isAnimating) {
    return controller.strokeAnimationController;
  }

  return null;
}

/// Determine whether to use standard stroke color, radical color, or hint color.
List<Paint> _getStrokePaints(StrokeOrderAnimationController controller) {
  return List.generate(controller.strokeOrder.nStrokes, (index) {
    if (controller.highlightRadical &&
        controller.strokeOrder.radicalStrokeIndices.contains(index)) {
      return Paint()..color = controller.radicalColor;
    }

    if (controller.isQuizzing && index == controller.currentStroke) {
      return Paint()..color = controller.hintColor;
    }

    return Paint()..color = controller.strokeColor;
  });
}

List<bool> _getWhichStrokesToPaint(StrokeOrderAnimationController controller) {
  return List.generate(
    controller.strokeOrder.nStrokes,
    (index) => controller.showStroke && index < controller.currentStroke,
  );
}

List<(PathMetric, PathMetric)?> _getContourPaths(
  StrokeOrder strokeOrder,
) {
  if (_contourCache.containsKey(strokeOrder)) {
    return _contourCache[strokeOrder]!;
  }

  final contourPaths = List.generate(strokeOrder.nStrokes, (i) {
    if (strokeOrder.medians[i].isEmpty) {
      return null;
    }

    final start = _getClosestPointOnPathAsDistanceOnPath(
      strokeOrder.strokeOutlines[i],
      strokeOrder.medians[i].first,
    );

    final end = _getClosestPointOnPathAsDistanceOnPath(
      strokeOrder.strokeOutlines[i],
      strokeOrder.medians[i].last,
    );

    if (start < 0 || end < 0) {
      return null;
    }

    final List<Path> contourPaths = _extractContourPaths(
      strokeOrder.strokeOutlines[i],
      start,
      end,
    );

    return (
      contourPaths.first.computeMetrics().first,
      contourPaths.last.computeMetrics().first
    );
  });

  _contourCache[strokeOrder] = contourPaths;

  return contourPaths;
}

/// Split the original path into two paths that follow the outline
/// of the stroke from strokeStart to strokeEnd clockwise and counter-clockwise
List<Path> _extractContourPaths(
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

double _getClosestPointOnPathAsDistanceOnPath(Path path, Offset queryPoint) {
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

// Scale a path from the 1024x1024 coordinate system to the given size.
Path _scalePath(Path path, Size size) {
  if (size == const Size(1024, 1024)) {
    return path;
  }

  return path.transform(
    Matrix4(
      size.width / 1024,
      0,
      0,
      0,
      0,
      size.height / 1024,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      1,
    ).storage,
  );
}
