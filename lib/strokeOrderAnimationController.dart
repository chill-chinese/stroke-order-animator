import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:stroke_order_animator/strokeOrderAnimator.dart';
import 'package:svg_path_parser/svg_path_parser.dart';

class StrokeOrderAnimationController extends ChangeNotifier {
  String _strokeOrder;
  final TickerProvider _tickerProvider;
  List<int> _radicalStrokes;
  List<int> get radicalStrokes => _radicalStrokes;

  int _nStrokes;
  int get nStrokes => _nStrokes;
  int _currentStroke = 0;
  int get currentStroke => _currentStroke;
  List<Path> _strokes;
  List<Path> get strokes => _strokes;
  List<List<List<int>>> medians;

  AnimationController _animationController;
  AnimationController get animationController => _animationController;
  bool _isAnimating = false;
  bool get isAnimating => _isAnimating;
  bool _isQuizzing = false;
  bool get isQuizzing => _isQuizzing;

  bool _showStroke;
  bool _showOutline;
  bool _showMedian;
  bool _highlightRadical;

  bool get showStroke => _showStroke;
  bool get showOutline => _showOutline;
  bool get showMedian => _showMedian;
  bool get highlightRadical => _highlightRadical;

  Color _strokeColor;
  Color _outlineColor;
  Color _medianColor;
  Color _radicalColor;

  Color get strokeColor => _strokeColor;
  Color get outlineColor => _outlineColor;
  Color get medianColor => _medianColor;
  Color get radicalColor => _radicalColor;

  StrokeOrderAnimationController(
    this._strokeOrder,
    this._tickerProvider, {
    int animationSpeed = 1,
    bool showStroke: true,
    bool showOutline: true,
    bool showMedian: false,
    bool highlightRadical: false,
    Color strokeColor: Colors.blue,
    Color outlineColor: Colors.black,
    Color medianColor: Colors.black,
    Color radicalColor: Colors.red,
  }) {
    _animationController = AnimationController(
      vsync: _tickerProvider,
      duration: Duration(seconds: animationSpeed),
    );

    _animationController.addStatusListener(_strokeCompleted);

    setStrokeOrder(_strokeOrder);
    _showOutline = showOutline;

    setShowStroke(showStroke);
    setShowOutline(showOutline);
    setShowMedian(showMedian);
    setHighlightRadical(highlightRadical);
    setStrokeColor(strokeColor);
    setOutlineColor(outlineColor);
    setMedianColor(medianColor);
    setRadicalColor(radicalColor);
  }

  @override
  dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void startAnimation() {
    if (!_isAnimating && !_isQuizzing) {
      if (_currentStroke == _nStrokes) {
        _currentStroke = 0;
      }
      _isAnimating = true;
      _animationController.forward();
      notifyListeners();
    }
  }

  void stopAnimation() {
    if (_isAnimating) {
      _currentStroke += 1;
      _isAnimating = false;
      _animationController.reset();
      notifyListeners();
    }
  }

  void startQuiz() {
    if (!_isQuizzing) {
      _isAnimating = false;
      _currentStroke = 0;
      _animationController.reset();
      _isQuizzing = true;
      notifyListeners();
    }
  }

  void stopQuiz() {
    if (_isQuizzing) {
      _isAnimating = false;
      _animationController.reset();
      _isQuizzing = false;
      notifyListeners();
    }
  }

  void nextStroke() {
    if (!_isQuizzing) {
      if (_currentStroke == _nStrokes) {
        _currentStroke = 1;
      } else if (_isAnimating) {
        _currentStroke += 1;
        _animationController.reset();

        if (_currentStroke < _nStrokes) {
          _animationController.forward();
        } else {
          _isAnimating = false;
        }
      } else {
        if (_currentStroke < _nStrokes) {
          _currentStroke += 1;
        }
      }

      notifyListeners();
    }
  }

  void previousStroke() {
    if (!_isQuizzing) {
      if (_currentStroke != 0) {
        _currentStroke -= 1;
      }

      if (_isAnimating) {
        _animationController.reset();
        _animationController.forward();
      }

      notifyListeners();
    }
  }

  void reset() {
    _currentStroke = 0;
    _isAnimating = false;
    _animationController.reset();
    notifyListeners();
  }

  void showFullCharacter() {
    if (!_isQuizzing) {
      _currentStroke = _nStrokes;
      _isAnimating = false;
      _animationController.reset();
      notifyListeners();
    }
  }

  void _strokeCompleted(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _currentStroke += 1;
      _animationController.reset();
      if (_currentStroke < _nStrokes) {
        _animationController.forward();
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

  void setStrokeOrder(String strokeOrder) {
    final parsedJson = json.decode(_strokeOrder.replaceAll("'", '"'));

    // Transformation according to the makemeahanzi documentation
    _strokes = List.generate(
        parsedJson['strokes'].length,
        (index) => parseSvgPath(parsedJson['strokes'][index]).transform(
            Matrix4(1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 0, 900, 0, 1)
                .storage));

    medians = List.generate(parsedJson['medians'].length, (iStroke) {
      return List.generate(parsedJson['medians'][iStroke].length, (iPoint) {
        return List<int>.generate(
            parsedJson['medians'][iStroke][iPoint].length,
            (iCoordinate) => iCoordinate == 0
                ? parsedJson['medians'][iStroke][iPoint][iCoordinate]
                : parsedJson['medians'][iStroke][iPoint][iCoordinate] * -1 +
                    900);
      });
    });

    if (parsedJson['radStrokes'] != null) {
      _radicalStrokes = List<int>.generate(parsedJson['radStrokes'].length,
          (index) => parsedJson['radStrokes'][index]);
    } else {
      _radicalStrokes = [];
    }
    _nStrokes = _strokes.length;
  }

  void checkStroke(List<Offset> rawPoints) {
    bool strokeIsCorrect = false;

    if (currentStroke < nStrokes) {
      List<Offset> points = [];
      for (var point in rawPoints) {
        if (point != null) {
          points.add(point);
        }
      }

      final currentMedian = medians[currentStroke];

      final medianPath = Path();
      if (currentMedian.length > 1) {
        medianPath.moveTo(
            currentMedian[0][0].toDouble(), currentMedian[0][1].toDouble());
        for (var point in currentMedian) {
          medianPath.lineTo(point[0].toDouble(), point[1].toDouble());
        }
      }

      final strokePath = Path();
      if (points.length > 1) {
        strokePath.moveTo(points[0].dx, points[0].dy);
        for (var point in points) {
          strokePath.lineTo(point.dx, point.dy);
        }
      }

      final medianLength = medianPath.computeMetrics().first.length;
      final strokeLength = strokePath.computeMetrics().first.length;

      // Check whether the drawn stroke is correct
      double startEndMargin = 150;
      List<double> lengthRange = [0.5, 1.5];

      // Be more lenient on short strokes
      if (medianLength < 150) {
        lengthRange = [0.2, 3];
        startEndMargin = 200;
      }

      if ( // Check length of stroke
          strokeLength > lengthRange[0] * medianLength &&
              strokeLength < lengthRange[1] * medianLength &&
              // Check start and end position of stroke
              points.first.dx > currentMedian.first[0] - startEndMargin &&
              points.first.dx < currentMedian.first[0] + startEndMargin &&
              points.first.dy > currentMedian.first[1] - startEndMargin &&
              points.first.dy < currentMedian.first[1] + startEndMargin &&
              points.last.dx > currentMedian.last[0] - startEndMargin &&
              points.last.dx < currentMedian.last[0] + startEndMargin &&
              points.last.dy > currentMedian.last[1] - startEndMargin &&
              points.last.dy < currentMedian.last[1] + startEndMargin &&
              // Check that the stroke has the right direction
              ((distance2D(
                          [points.first.dx, points.first.dy],
                          currentMedian.first
                              .map((e) => e.toDouble())
                              .toList()) <
                      distance2D(
                          [points.last.dx, points.last.dy],
                          currentMedian.first
                              .map((e) => e.toDouble())
                              .toList())) ||
                  (distance2D([
                        points.last.dx,
                        points.last.dy
                      ], currentMedian.last.map((e) => e.toDouble()).toList()) <
                      distance2D(
                          [points.first.dx, points.first.dy],
                          currentMedian.last
                              .map((e) => e.toDouble())
                              .toList())))) {
        strokeIsCorrect = true;
      }

      if (_isQuizzing && currentStroke < nStrokes) {
        if (strokeIsCorrect) {
          _currentStroke += 1;

          notifyListeners();
        }
      }
    }
  }
}
