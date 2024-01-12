import 'dart:ui';

/// Information about a stroke order quiz.
class QuizSummary {
  QuizSummary(this._nStrokes) {
    reset();
  }
  final int _nStrokes;
  int get nStrokes => _nStrokes;

  /// Number of mistakes on a per-stroke basis.
  late List<int> mistakes;

  /// List of paths describing the correct strokes as written by the user (in a
  /// 1024x1024 coordinate system).
  late List<List<Offset>> correctStrokePaths;

  /// Total number of mistakes.
  int get nTotalMistakes =>
      mistakes.fold(0, (previous, current) => previous + current);

  void reset() {
    mistakes = List.generate(nStrokes, (index) => 0);
    correctStrokePaths = List.generate(nStrokes, (index) => []);
  }
}
