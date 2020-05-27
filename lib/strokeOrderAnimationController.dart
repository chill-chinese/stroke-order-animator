import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class StrokeOrderAnimationController extends ChangeNotifier {
  final String strokeOrder;
  final TickerProvider _tickerProvider;

  AnimationController animationController;
  bool isAnimating = false;

  StrokeOrderAnimationController(this.strokeOrder, this._tickerProvider) {
    animationController = AnimationController(
      vsync: _tickerProvider,
      duration: Duration(seconds: 3),
    );
  }

  @override
  dispose() {
    animationController.dispose();
    super.dispose();
  }

  void startAnimation() {
    this.isAnimating = true;
    animationController.forward();
    notifyListeners();
  }

  void stopAnimation() {
    this.isAnimating = false;
    animationController.stop();
    animationController.reset();
    notifyListeners();
  }
}
