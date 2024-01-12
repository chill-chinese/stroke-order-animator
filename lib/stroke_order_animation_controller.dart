// ignore_for_file: avoid_dynamic_calls, argument_type_not_assignable, return_of_invalid_type_from_closure

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:stroke_order_animator/stroke_order.dart';
import 'package:stroke_order_animator/stroke_order_animator.dart';

/// A ChangeNotifier that controls the behavior of a stroke order diagram.
/// It must be passed as an argument to a [StrokeOrderAnimator] that handles
/// the actual presentation of the diagram. It can be consumed by the
/// [StrokeOrderAnimator] and an app to allow for synchronization of, e.g.,
/// control buttons with the animations.
class StrokeOrderAnimationController extends ChangeNotifier {
  StrokeOrderAnimationController(
    this._strokeOrder,
    TickerProvider tickerProvider, {
    double strokeAnimationSpeed = 1,
    double hintAnimationSpeed = 3,
    bool showStroke = true,
    bool showOutline = true,
    bool showMedian = false,
    bool showUserStroke = false,
    bool highlightRadical = false,
    Color strokeColor = Colors.blue,
    Color outlineColor = Colors.black,
    Color medianColor = Colors.black,
    Color radicalColor = Colors.red,
    Color brushColor = Colors.black,
    double brushWidth = 8.0,
    int hintAfterStrokes = 3,
    Color hintColor = Colors.lightBlueAccent,
    Function? onQuizCompleteCallback,
    Function? onWrongStrokeCallback,
    Function? onCorrectStrokeCallback,
  })  : _strokeColor = strokeColor,
        _showStroke = showStroke,
        _showOutline = showOutline,
        _showMedian = showMedian,
        _showUserStroke = showUserStroke,
        _highlightRadical = highlightRadical,
        _outlineColor = outlineColor,
        _medianColor = medianColor,
        _radicalColor = radicalColor,
        _brushColor = brushColor,
        _brushWidth = brushWidth,
        _hintAfterStrokes = hintAfterStrokes,
        _hintColor = hintColor,
        _strokeAnimationSpeed = strokeAnimationSpeed,
        _hintAnimationSpeed = hintAnimationSpeed,
        _strokeAnimationController = AnimationController(
          vsync: tickerProvider,
        ),
        _hintAnimationController = AnimationController(
          vsync: tickerProvider,
        ) {
    _strokeAnimationController.addStatusListener(_strokeCompleted);

    _hintAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _hintAnimationController.reset();
      }
    });

    _setCurrentStroke(0);
    _summary = QuizSummary(strokeOrder.nStrokes);

    addOnQuizCompleteCallback(onQuizCompleteCallback);
    addOnWrongStrokeCallback(onWrongStrokeCallback);
    addOnCorrectStrokeCallback(onCorrectStrokeCallback);

    notifyListeners();
  }
  StrokeOrder _strokeOrder;
  StrokeOrder get strokeOrder => _strokeOrder;
  set strokeOrder(StrokeOrder value) {
    _strokeOrder = value;
    stopQuiz();
    reset();
  }

  int _currentStroke = 0;
  int get currentStroke => _currentStroke;

  final AnimationController _strokeAnimationController;
  AnimationController get strokeAnimationController =>
      _strokeAnimationController;
  final AnimationController _hintAnimationController;
  AnimationController get hintAnimationController => _hintAnimationController;
  bool _isAnimating = false;
  bool get isAnimating => _isAnimating;
  bool _isQuizzing = false;
  bool get isQuizzing => _isQuizzing;
  double _strokeAnimationSpeed = 1;
  double _hintAnimationSpeed = 3;

  QuizSummary _summary = QuizSummary(0);
  QuizSummary get summary => _summary;

  final List<Function> _onQuizCompleteCallbacks = [];
  final List<Function> _onWrongStrokeCallbacks = [];
  final List<Function> _onCorrectStrokeCallbacks = [];

  bool _showStroke;
  bool _showOutline;
  bool _showMedian;
  bool _showUserStroke;
  bool _highlightRadical;

  bool get showStroke => _showStroke;
  bool get showOutline => _showOutline;
  bool get showMedian => _showMedian;
  bool get showUserStroke => _showUserStroke;
  bool get highlightRadical => _highlightRadical;

  Color _strokeColor;
  Color _outlineColor;
  Color _medianColor;
  Color _radicalColor;
  Color _brushColor;
  Color _hintColor;

  Color get strokeColor => _strokeColor;
  Color get outlineColor => _outlineColor;
  Color get medianColor => _medianColor;
  Color get radicalColor => _radicalColor;
  Color get brushColor => _brushColor;
  Color get hintColor => _hintColor;

  double _brushWidth;
  double get brushWidth => _brushWidth;

  int _hintAfterStrokes;
  int get hintAfterStrokes => _hintAfterStrokes;

  @override
  void dispose() {
    _strokeAnimationController.dispose();
    _hintAnimationController.dispose();
    _onCorrectStrokeCallbacks.clear();
    _onWrongStrokeCallbacks.clear();
    _onQuizCompleteCallbacks.clear();
    super.dispose();
  }

  void startAnimation() {
    if (!_isAnimating && !_isQuizzing) {
      if (currentStroke == strokeOrder.nStrokes) {
        _setCurrentStroke(0);
      }
      _isAnimating = true;
      _strokeAnimationController.forward();
      notifyListeners();
    }
  }

  void stopAnimation() {
    if (_isAnimating) {
      _setCurrentStroke(currentStroke + 1);
      _isAnimating = false;
      _strokeAnimationController.reset();
      notifyListeners();
    }
  }

  void startQuiz() {
    if (!_isQuizzing) {
      _isAnimating = false;
      _setCurrentStroke(0);
      summary.reset();
      _strokeAnimationController.reset();
      _isQuizzing = true;
      notifyListeners();
    }
  }

  void stopQuiz() {
    if (_isQuizzing) {
      _isAnimating = false;
      _strokeAnimationController.reset();
      _isQuizzing = false;
      notifyListeners();
    }
  }

  void nextStroke() {
    if (!_isQuizzing) {
      if (currentStroke == strokeOrder.nStrokes) {
        _setCurrentStroke(1);
      } else if (_isAnimating) {
        _setCurrentStroke(currentStroke + 1);
        _strokeAnimationController.reset();

        if (currentStroke < strokeOrder.nStrokes) {
          _strokeAnimationController.forward();
        } else {
          _isAnimating = false;
        }
      } else {
        if (currentStroke < strokeOrder.nStrokes) {
          _setCurrentStroke(currentStroke + 1);
        }
      }

      notifyListeners();
    }
  }

  void previousStroke() {
    if (!_isQuizzing) {
      if (currentStroke != 0) {
        _setCurrentStroke(currentStroke - 1);
      }

      if (_isAnimating) {
        _strokeAnimationController.reset();
        _strokeAnimationController.forward();
      }

      notifyListeners();
    }
  }

  void reset() {
    _setCurrentStroke(0);
    _isAnimating = false;
    _strokeAnimationController.reset();
    summary.reset();
    notifyListeners();
  }

  void showFullCharacter() {
    if (!_isQuizzing) {
      _setCurrentStroke(strokeOrder.nStrokes);
      _isAnimating = false;
      _strokeAnimationController.reset();
      notifyListeners();
    }
  }

  void _strokeCompleted(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _setCurrentStroke(currentStroke + 1);
      _strokeAnimationController.reset();
      if (currentStroke < strokeOrder.nStrokes) {
        _strokeAnimationController.forward();
      } else {
        _isAnimating = false;
      }
    }
    notifyListeners();
  }

  void setShowStroke(bool value) {
    _showStroke = value;
    notifyListeners();
  }

  void setShowUserStroke(bool value) {
    _showUserStroke = value;
    notifyListeners();
  }

  void setShowOutline(bool value) {
    _showOutline = value;
    notifyListeners();
  }

  void setShowMedian(bool value) {
    _showMedian = value;
    notifyListeners();
  }

  void setHighlightRadical(bool value) {
    _highlightRadical = value;
    notifyListeners();
  }

  void setStrokeColor(Color value) {
    _strokeColor = value;
    notifyListeners();
  }

  void setOutlineColor(Color value) {
    _outlineColor = value;
    notifyListeners();
  }

  void setMedianColor(Color value) {
    _medianColor = value;
    notifyListeners();
  }

  void setRadicalColor(Color value) {
    _radicalColor = value;
    notifyListeners();
  }

  void setBrushColor(Color value) {
    _brushColor = value;
    notifyListeners();
  }

  void setHintColor(Color value) {
    _hintColor = value;
    notifyListeners();
  }

  void setBrushWidth(double value) {
    _brushWidth = value;
    notifyListeners();
  }

  void setHintAfterStrokes(int value) {
    _hintAfterStrokes = value;
    notifyListeners();
  }

  void setStrokeAnimationSpeed(double value) {
    _strokeAnimationSpeed = value;
    _setCurrentStroke(currentStroke);
  }

  void setHintAnimationSpeed(double value) {
    _hintAnimationSpeed = value;
    _setCurrentStroke(currentStroke);
  }

  void _setNormalizedStrokeAnimationSpeed(double normFactor) {
    _strokeAnimationController.duration = Duration(
      milliseconds: (normFactor / _strokeAnimationSpeed * 1000).toInt(),
    );
  }

  void _setNormalizedHintAnimationSpeed(double normFactor) {
    _hintAnimationController.duration = Duration(
      milliseconds: (normFactor / _hintAnimationSpeed * 1000).toInt(),
    );
  }

  void addOnQuizCompleteCallback(Function? onQuizCompleteCallback) {
    if (onQuizCompleteCallback != null) {
      _onQuizCompleteCallbacks.add(onQuizCompleteCallback);
    }
  }

  void addOnWrongStrokeCallback(Function? onWrongStrokeCallback) {
    if (onWrongStrokeCallback != null) {
      _onWrongStrokeCallbacks.add(onWrongStrokeCallback);
    }
  }

  void addOnCorrectStrokeCallback(Function? onCorrectStrokeCallback) {
    if (onCorrectStrokeCallback != null) {
      _onCorrectStrokeCallbacks.add(onCorrectStrokeCallback);
    }
  }

  void checkStroke(List<Offset?> rawStroke) {
    final List<Offset> stroke = getNonNullPointsFrom(rawStroke);
    final strokeLength = getLength(stroke);

    if (isQuizzing &&
        currentStroke < strokeOrder.nStrokes &&
        strokeLength > 0) {
      if (strokeIsCorrect(strokeLength, stroke)) {
        notifyCorrectStrokeCallbacks();
        _summary.correctStrokePaths[currentStroke] = stroke;
        _setCurrentStroke(currentStroke + 1);

        if (currentStroke == strokeOrder.nStrokes) {
          stopQuiz();
          notifyQuizCompleteCallbacks();
        }
      } else {
        summary.mistakes[currentStroke] += 1;
        notifyWrongStrokeCallbacks();

        if (summary.mistakes[currentStroke] >= hintAfterStrokes) {
          animateHint();
        }
      }

      notifyListeners();
    }
  }

  bool strokeIsCorrect(double strokeLength, List<Offset> stroke) {
    final median = strokeOrder.medians[currentStroke];
    final medianLength = getLength(median);

    final List<double> allowedLengthRange = getAllowedLengthRange(medianLength);
    final double startEndMargin = getStartEndMargin(medianLength);

    bool isCorrect = false;

    if (strokeLengthWithinBounds(strokeLength, allowedLengthRange) &&
        strokeStartIsWithinMargin(stroke, median, startEndMargin) &&
        strokeEndIsWithinMargin(stroke, median, startEndMargin) &&
        strokeHasRightDirection(stroke, median)) {
      isCorrect = true;
    }
    return isCorrect;
  }

  void animateHint() {
    if (!(debugSemanticsDisableAnimations ?? false)) {
      _hintAnimationController.reset();
      _hintAnimationController.forward();
    }
  }

  void notifyWrongStrokeCallbacks() {
    for (final callback in _onWrongStrokeCallbacks) {
      callback(currentStroke);
    }
  }

  void notifyQuizCompleteCallbacks() {
    for (final callback in _onQuizCompleteCallbacks) {
      callback(summary);
    }
  }

  void notifyCorrectStrokeCallbacks() {
    for (final callback in _onCorrectStrokeCallbacks) {
      callback(currentStroke);
    }
  }

  double getStartEndMargin(double medianLength) {
    double startEndMargin;

    // Be more lenient on short strokes
    if (medianLength < 150) {
      startEndMargin = 200;
    } else {
      startEndMargin = 150;
    }
    return startEndMargin;
  }

  List<double> getAllowedLengthRange(double medianLength) {
    List<double> lengthRange;

    // Be more lenient on short strokes
    if (medianLength < 150) {
      lengthRange = [0.2, 3];
    } else {
      lengthRange = [0.5, 1.5];
    }

    return lengthRange.map((e) => e * medianLength).toList();
  }

  bool strokeHasRightDirection(
    List<Offset> points,
    List<Offset> currentMedian,
  ) {
    return (distance2D(points.first, currentMedian.first) <
            distance2D(points.last, currentMedian.first)) ||
        (distance2D(points.last, currentMedian.last) <
            distance2D(points.first, currentMedian.last));
  }

  bool strokeStartIsWithinMargin(
    List<Offset> points,
    List<Offset> currentMedian,
    double startEndMargin,
  ) {
    final strokeStartWithinMargin =
        points.first.dx > currentMedian.first.dx - startEndMargin &&
            points.first.dx < currentMedian.first.dx + startEndMargin &&
            points.first.dy > currentMedian.first.dy - startEndMargin &&
            points.first.dy < currentMedian.first.dy + startEndMargin;
    return strokeStartWithinMargin;
  }

  bool strokeEndIsWithinMargin(
    List<Offset> points,
    List<Offset> currentMedian,
    double startEndMargin,
  ) {
    final strokeEndWithinMargin =
        points.last.dx > currentMedian.last.dx - startEndMargin &&
            points.last.dx < currentMedian.last.dx + startEndMargin &&
            points.last.dy > currentMedian.last.dy - startEndMargin &&
            points.last.dy < currentMedian.last.dy + startEndMargin;
    return strokeEndWithinMargin;
  }

  bool strokeLengthWithinBounds(double strokeLength, List<double> lengthRange) {
    return strokeLength > lengthRange[0] && strokeLength < lengthRange[1];
  }

  double getLength(List<Offset> points) {
    double pathLength = 0;

    final path = convertOffsetsToPath(points);
    final pathMetrics = path.computeMetrics().toList();

    if (pathMetrics.isNotEmpty) {
      pathLength = pathMetrics.first.length;
    }
    return pathLength;
  }

  Path convertOffsetsToPath(List<Offset> points) {
    final path = Path();

    if (points.length > 1) {
      path.moveTo(points[0].dx, points[0].dy);
      for (final point in points) {
        path.lineTo(point.dx, point.dy);
      }
    }

    return path;
  }

  List<Offset> getNonNullPointsFrom(List<Offset?> rawPoints) {
    final List<Offset> points = [];

    for (final point in rawPoints) {
      if (point != null) {
        points.add(point);
      }
    }

    return points;
  }

  void _setCurrentStroke(int value) {
    _currentStroke = value;

    // Normalize the animation speed to the length of the stroke
    // The first stroke of 你 (length 520) is taken as reference
    if (currentStroke < strokeOrder.nStrokes) {
      final currentMedian = strokeOrder.medians[currentStroke];

      final medianPath = Path();
      if (currentMedian.length > 1) {
        medianPath.moveTo(currentMedian[0].dx, currentMedian[0].dy);
        for (final point in currentMedian) {
          medianPath.lineTo(point.dx, point.dy);
        }
      }

      final medianLength = medianPath.computeMetrics().first.length;

      if (medianLength > 0) {
        final normFactor = (medianLength / 520).clamp(0.5, 1.5);
        _setNormalizedStrokeAnimationSpeed(normFactor);
        _setNormalizedHintAnimationSpeed(normFactor);
      }
    }

    notifyListeners();
  }
}

class QuizSummary {
  QuizSummary(this._nStrokes) {
    reset();
  }
  final int _nStrokes;
  int get nStrokes => _nStrokes;

  late List<int> mistakes;
  late List<List<Offset>> correctStrokePaths;

  int get nTotalMistakes =>
      mistakes.fold(0, (previous, current) => previous + current);

  void reset() {
    mistakes = List.generate(nStrokes, (index) => 0);
    correctStrokePaths = List.generate(nStrokes, (index) => []);
  }
}
