import 'dart:convert';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:svg_path_parser/svg_path_parser.dart';

class StrokeOrderAnimationController extends ChangeNotifier {
  final String strokeOrder;
  final TickerProvider _tickerProvider;
  int nStrokes;
  int currentStroke = 0;
  List<Path> strokes;
  List<List<List<int>>> medians;

  AnimationController animationController;
  bool isAnimating = false;

  StrokeOrderAnimationController(this.strokeOrder, this._tickerProvider) {
    animationController = AnimationController(
      vsync: _tickerProvider,
      duration: Duration(seconds: 1),
    );

    animationController.addStatusListener(_strokeCompleted);

    final parsedJson = json.decode(strokeOrder.replaceAll("'", '"'));

    // Transformation according to the makemeahanzi documentation
    strokes = List.generate(
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

    nStrokes = strokes.length;
  }

  @override
  dispose() {
    animationController.dispose();
    super.dispose();
  }

  void startAnimation() {
    if (!isAnimating) {
      if (currentStroke == nStrokes) {
        currentStroke = 0;
      }
      this.isAnimating = true;
      animationController.forward();
      notifyListeners();
    }
  }

  void stopAnimation() {
    if (this.isAnimating) {
      currentStroke += 1;
      this.isAnimating = false;
      animationController.reset();
      notifyListeners();
    }
  }

  void nextStroke() {
    if (currentStroke == nStrokes) {
      currentStroke = 1;
    } else if (this.isAnimating) {
      currentStroke += 1;
      animationController.reset();

      if (currentStroke < nStrokes) {
        animationController.forward();
      } else {
        isAnimating = false;
      }
    } else {
      if (currentStroke < nStrokes) {
        currentStroke += 1;
      }
    }

    notifyListeners();
  }

  void previousStroke() {
    if (currentStroke != 0) {
      currentStroke -= 1;
    }

    if (isAnimating) {
      animationController.reset();
      animationController.forward();
    }

    notifyListeners();
  }

  void reset() {
    currentStroke = 0;
    isAnimating = false;
    animationController.reset();
    notifyListeners();
  }

  void showFullCharacter() {
    currentStroke = nStrokes;
    isAnimating = false;
    animationController.reset();
    notifyListeners();
  }

  void _strokeCompleted(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      currentStroke += 1;
      animationController.reset();
      if (currentStroke < nStrokes) {
        animationController.forward();
      } else {
        isAnimating = false;
      }
    }
    notifyListeners();
  }
}
