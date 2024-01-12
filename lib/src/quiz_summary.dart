import 'dart:ui';

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
