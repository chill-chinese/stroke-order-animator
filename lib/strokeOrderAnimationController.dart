import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:stroke_order_animator/strokeOrderAnimator.dart';
import 'package:svg_path_parser/svg_path_parser.dart';

/// A ChangeNotifier that controls the behaviour of a stroke order diagram.
/// It must be passed as an argument to a [StrokeOrderAnimator] that handles
/// the actual presentation of the diagram. It can be consumed by the
/// [StrokeOrderAnimator] and an app to allow for synchronization of, e.g.,
/// control buttons with the animations.
class StrokeOrderAnimationController extends ChangeNotifier {
  String _strokeOrder;
  String get strokeOrder => _strokeOrder;
  List<int> _radicalStrokeIndices = List.empty();
  List<int> get radicalStrokes => _radicalStrokeIndices;

  int _nStrokes = 0;
  int get nStrokes => _nStrokes;
  int _currentStroke = 0;
  int get currentStroke => _currentStroke;
  List<Path> _strokes = List.empty();
  List<Path> get strokes => _strokes;
  List<List<Offset>> _medians = List.empty();
  List<List<Offset>> get medians => _medians;

  AnimationController _strokeAnimationController;
  AnimationController get strokeAnimationController =>
      _strokeAnimationController;
  AnimationController _hintAnimationController;
  AnimationController get hintAnimationController => _hintAnimationController;
  bool _isAnimating = false;
  bool get isAnimating => _isAnimating;
  bool _isQuizzing = false;
  bool get isQuizzing => _isQuizzing;
  double _strokeAnimationSpeed = 1;
  double _hintAnimationSpeed = 3;

  QuizSummary _summary = QuizSummary(0);
  QuizSummary get summary => _summary;

  List<Function> _onQuizCompleteCallbacks = [];
  List<Function> _onWrongStrokeCallbacks = [];
  List<Function> _onCorrectStrokeCallbacks = [];

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

  StrokeOrderAnimationController(
    this._strokeOrder,
    tickerProvider, {
    double strokeAnimationSpeed: 1,
    double hintAnimationSpeed: 3,
    bool showStroke: true,
    bool showOutline: true,
    bool showMedian: false,
    bool showUserStroke: false,
    bool highlightRadical: false,
    Color strokeColor: Colors.blue,
    Color outlineColor: Colors.black,
    Color medianColor: Colors.black,
    Color radicalColor: Colors.red,
    Color brushColor: Colors.black,
    double brushWidth: 8.0,
    int hintAfterStrokes: 3,
    Color hintColor: Colors.lightBlueAccent,
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

    setStrokeOrder(_strokeOrder);
    _setCurrentStroke(0);
    _summary = QuizSummary(_nStrokes);

    addOnQuizCompleteCallback(onQuizCompleteCallback);
    addOnWrongStrokeCallback(onWrongStrokeCallback);
    addOnCorrectStrokeCallback(onCorrectStrokeCallback);

    notifyListeners();
  }

  @override
  dispose() {
    _strokeAnimationController.dispose();
    _hintAnimationController.dispose();
    _onCorrectStrokeCallbacks.clear();
    _onWrongStrokeCallbacks.clear();
    _onQuizCompleteCallbacks.clear();
    super.dispose();
  }

  void startAnimation() {
    if (!_isAnimating && !_isQuizzing) {
      if (currentStroke == _nStrokes) {
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
      if (currentStroke == _nStrokes) {
        _setCurrentStroke(1);
      } else if (_isAnimating) {
        _setCurrentStroke(currentStroke + 1);
        _strokeAnimationController.reset();

        if (currentStroke < _nStrokes) {
          _strokeAnimationController.forward();
        } else {
          _isAnimating = false;
        }
      } else {
        if (currentStroke < _nStrokes) {
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
      _setCurrentStroke(_nStrokes);
      _isAnimating = false;
      _strokeAnimationController.reset();
      notifyListeners();
    }
  }

  void _strokeCompleted(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _setCurrentStroke(currentStroke + 1);
      _strokeAnimationController.reset();
      if (currentStroke < _nStrokes) {
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
        milliseconds: (normFactor / _strokeAnimationSpeed * 1000).toInt());
  }

  void _setNormalizedHintAnimationSpeed(double normFactor) {
    _hintAnimationController.duration = Duration(
        milliseconds: (normFactor / _hintAnimationSpeed * 1000).toInt());
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

  void setStrokeOrder(String strokeOrder) {
    dynamic parsedJson;
    List<Path> tmpStrokes;
    List<List<Offset>> tmpMedians;
    List<int> tmpRadicalStrokeIndices = [];

    try {
      parsedJson = json.decode(strokeOrder.replaceAll("'", '"'));
    } catch (e) {
      throw FormatException("Invalid JSON string for stroke order.");
    }

    try {
      tmpStrokes = List.generate(
          parsedJson['strokes'].length,
          (index) => parseSvgPath(parsedJson['strokes'][index]).transform(
              // Transformation according to the makemeahanzi documentation
              Matrix4(1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 0, 900, 0, 1)
                  .storage));
    } catch (e) {
      throw FormatException("Invalid strokes in stroke order JSON.");
    }

    try {
      tmpMedians = List.generate(parsedJson['medians'].length, (iStroke) {
        return List.generate(parsedJson['medians'][iStroke].length, (iPoint) {
          return Offset(
              (parsedJson['medians'][iStroke][iPoint][0]).toDouble(),
              (parsedJson['medians'][iStroke][iPoint][1] * -1 + 900)
                  .toDouble());
        });
      });
    } catch (e) {
      throw FormatException("Invalid medians in stroke order JSON.");
    }

    if (tmpMedians.length != tmpStrokes.length) {
      throw FormatException("Number of strokes and medians not equal.");
    }

    try {
      tmpRadicalStrokeIndices = List<int >.generate(
          parsedJson['radStrokes'].length,
          (index) => parsedJson['radStrokes'][index]);
    } catch (e) {
      print("Could not read radical stroke indices from JSON.");
      tmpRadicalStrokeIndices = [];
    }

    if (tmpStrokes.isNotEmpty) {
      _strokeOrder = strokeOrder;
      _strokes = tmpStrokes;
      _medians = tmpMedians;
      _radicalStrokeIndices = tmpRadicalStrokeIndices;
      _nStrokes = _strokes.length;
    }
  }

  void checkStroke(List<Offset?> rawStroke) {
    List<Offset> stroke = getNonNullPointsFrom(rawStroke);
    final strokeLength = getLength(stroke);

    if (isQuizzing && currentStroke < nStrokes && strokeLength > 0) {
      if (strokeIsCorrect(strokeLength, stroke)) {
        notifyCorrectStrokeCallbacks();
        _summary.correctStrokePaths[currentStroke] = stroke;
        _setCurrentStroke(currentStroke + 1);

        if (currentStroke == nStrokes) {
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
    final median = _medians[currentStroke];
    final medianLength = getLength(median);

    List<double> allowedLengthRange = getAllowedLengthRange(medianLength);
    double startEndMargin = getStartEndMargin(medianLength);

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
    for (var callback in _onWrongStrokeCallbacks) {
      callback(currentStroke);
    }
  }

  void notifyQuizCompleteCallbacks() {
    for (var callback in _onQuizCompleteCallbacks) {
      callback(summary);
    }
  }

  void notifyCorrectStrokeCallbacks() {
    for (var callback in _onCorrectStrokeCallbacks) {
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

    lengthRange = lengthRange.map((e) => e.toDouble() * medianLength).toList();

    return lengthRange;
  }

  bool strokeHasRightDirection(
      List<Offset> points, List<Offset> currentMedian) {
    return ((distance2D(points.first, currentMedian.first) <
            distance2D(points.last, currentMedian.first)) ||
        (distance2D(points.last, currentMedian.last) <
            distance2D(points.first, currentMedian.last)));
  }

  bool strokeStartIsWithinMargin(
      List<Offset> points, List<Offset> currentMedian, double startEndMargin) {
    final strokeStartWithinMargin =
        points.first.dx > currentMedian.first.dx - startEndMargin &&
            points.first.dx < currentMedian.first.dx + startEndMargin &&
            points.first.dy > currentMedian.first.dy - startEndMargin &&
            points.first.dy < currentMedian.first.dy + startEndMargin;
    return strokeStartWithinMargin;
  }

  bool strokeEndIsWithinMargin(
      List<Offset> points, List<Offset> currentMedian, double startEndMargin) {
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
      path.moveTo(points[0].dx.toDouble(), points[0].dy.toDouble());
      for (var point in points) {
        path.lineTo(point.dx.toDouble(), point.dy.toDouble());
      }
    }

    return path;
  }

  List<Offset> getNonNullPointsFrom(List<Offset?> rawPoints) {
    List<Offset> points = [];

    for (var point in rawPoints) {
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
    if (currentStroke < nStrokes) {
      final currentMedian = _medians[currentStroke];

      final medianPath = Path();
      if (currentMedian.length > 1) {
        medianPath.moveTo(currentMedian[0].dx, currentMedian[0].dy);
        for (var point in currentMedian) {
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
  int _nStrokes;
  int get nStrokes => _nStrokes;

  late List<int> mistakes;
  late List<List<Offset>> correctStrokePaths;

  int get nTotalMistakes =>
      mistakes.fold(0, (previous, current) => previous + current);

  QuizSummary(this._nStrokes) {
    reset();
  }

  void reset() {
    mistakes = List.generate(nStrokes, (index) => 0);
    correctStrokePaths = List.generate(nStrokes, (index) => []);
  }
}
