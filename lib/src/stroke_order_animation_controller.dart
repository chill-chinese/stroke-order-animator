import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:stroke_order_animator/src/distance_2_d.dart';
import 'package:stroke_order_animator/stroke_order_animator.dart';

/// A [ChangeNotifier] that controls the behavior of a stroke order diagram.
///
/// It must be passed as an argument to a [StrokeOrderAnimator] that handles
/// the actual presentation of the diagram.
/// It can additionally be consumed by a [ListenableBuilder] to allow for
/// synchronization of control buttons with the animations.
/// In order to control animations, a [TickerProvider] must be passed to the
/// controller, for example using a [TickerProviderStateMixin].
///
/// To better integrate quizzes, three callbacks can be either passed to the
/// [StrokeOrderAnimationController] during instantiation or afterwards using
/// the following methods:
///
/// * [StrokeOrderAnimationController.addOnWrongStrokeCallback]
/// * [StrokeOrderAnimationController.addOnCorrectStrokeCallback]
/// * [StrokeOrderAnimationController.addOnQuizCompleteCallback]
///
/// The `onQuizCompleteCallback` receives a [QuizSummary].
/// The other two callbacks receive the index of the stroke that was written
/// (in-)correctly. All indices are zero-based.
///
/// Check out [StrokeOrderAnimationController.new] for a list of attributes that
/// control how the stroke order diagram is displayed and behaves.
///
/// A number of methods control the animation state:
///
/// * Start/stop animation
/// * Start/stop quiz
/// * Show next/previous stroke
/// * Show full character
/// * Reset animation/quiz
///
/// Don't forget to call [dispose] when the controller is no longer needed.
class StrokeOrderAnimationController extends ChangeNotifier {
  /// Creates a new [StrokeOrderAnimationController].
  ///
  /// A number of attributes can be set during initialization or via their
  /// respective setters:
  ///
  /// * Animation speed of stroke animations and hints in quiz mode (try 3 and adjust from there)
  /// * Whether to show/hide strokes
  /// * Whether to show/hide outlines
  /// * Whether to show/hide backgrounds for the strokes
  /// * Whether to show/hide medians
  /// * Whether to show/hide the correct strokes the user writes during a quiz
  /// * Whether to highlight radicals
  /// * Stroke color
  /// * Outline color
  /// * Background color (of the strokes, not the whole widget)
  /// * Median color
  /// * Radical color
  /// * Brush color in quiz mode
  /// * Brush thickness in quiz mode
  /// * Number of wrong strokes before showing a hint in quiz mode
  /// * Hint color in quiz mode
  ///
  /// Don't forget to call [dispose] when the controller is no longer needed.
  StrokeOrderAnimationController(
    this._strokeOrder,
    TickerProvider tickerProvider, {
    double strokeAnimationSpeed = 1,
    double hintAnimationSpeed = 3,
    bool showStroke = true,
    bool showOutline = true,
    bool showBackground = false,
    bool showMedian = false,
    bool showUserStroke = false,
    bool highlightRadical = false,
    Color strokeColor = Colors.blue,
    Color outlineColor = Colors.black,
    Color backgroundColor = Colors.grey,
    Color medianColor = Colors.black,
    Color radicalColor = Colors.red,
    Color brushColor = Colors.black,
    double brushWidth = 8.0,
    double outlineWidth = 2.0,
    double medianWidth = 2.0,
    int hintAfterStrokes = 3,
    Color hintColor = Colors.lightBlueAccent,
    void Function(QuizSummary)? onQuizCompleteCallback,
    void Function(int)? onWrongStrokeCallback,
    void Function(int)? onCorrectStrokeCallback,
  })  : _strokeColor = strokeColor,
        _showStroke = showStroke,
        _showOutline = showOutline,
        _showBackground = showBackground,
        _showMedian = showMedian,
        _showUserStroke = showUserStroke,
        _highlightRadical = highlightRadical,
        _outlineColor = outlineColor,
        _backgroundColor = backgroundColor,
        _medianColor = medianColor,
        _radicalColor = radicalColor,
        _brushColor = brushColor,
        _brushWidth = brushWidth,
        _outlineWidth = outlineWidth,
        _medianWidth = medianWidth,
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

    if (onQuizCompleteCallback != null) {
      addOnQuizCompleteCallback(onQuizCompleteCallback);
    }
    if (onWrongStrokeCallback != null) {
      addOnWrongStrokeCallback(onWrongStrokeCallback);
    }
    if (onCorrectStrokeCallback != null) {
      addOnCorrectStrokeCallback(onCorrectStrokeCallback);
    }

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

  final List<void Function(QuizSummary)> _onQuizCompleteCallbacks = [];
  final List<void Function(int)> _onWrongStrokeCallbacks = [];
  final List<void Function(int)> _onCorrectStrokeCallbacks = [];

  bool _showStroke;
  bool _showOutline;
  bool _showBackground;
  bool _showMedian;
  bool _showUserStroke;
  bool _highlightRadical;

  bool get showStroke => _showStroke;
  bool get showOutline => _showOutline;
  bool get showBackground => _showBackground;
  bool get showMedian => _showMedian;
  bool get showUserStroke => _showUserStroke;
  bool get highlightRadical => _highlightRadical;

  Color _strokeColor;
  Color _outlineColor;
  Color _backgroundColor;
  Color _medianColor;
  Color _radicalColor;
  Color _brushColor;
  Color _hintColor;

  Color get strokeColor => _strokeColor;
  Color get outlineColor => _outlineColor;
  Color get backgroundColor => _backgroundColor;
  Color get medianColor => _medianColor;
  Color get radicalColor => _radicalColor;
  Color get brushColor => _brushColor;
  Color get hintColor => _hintColor;

  double _brushWidth;
  double get brushWidth => _brushWidth;

  final double _outlineWidth;
  double get outlineWidth => _outlineWidth;

  final double _medianWidth;
  double get medianWidth => _medianWidth;

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

  void setShowBackground(bool value) {
    _showBackground = value;
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

  void setBackgroundColor(Color value) {
    _backgroundColor = value;
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

  void addOnQuizCompleteCallback(void Function(QuizSummary) callback) {
    _onQuizCompleteCallbacks.add(callback);
  }

  void addOnWrongStrokeCallback(void Function(int) callback) {
    _onWrongStrokeCallbacks.add(callback);
  }

  void addOnCorrectStrokeCallback(void Function(int) callback) {
    _onCorrectStrokeCallbacks.add(callback);
  }

  void checkStroke(List<Offset> stroke) {
    final strokeLength = getLength(stroke);

    if (isQuizzing &&
        currentStroke < strokeOrder.nStrokes &&
        strokeLength > 0) {
      if (strokeIsCorrect(strokeLength, stroke)) {
        notifyCorrectStrokeCallbacks();
        _summary.correctStrokePaths[currentStroke] = List.from(stroke);
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
