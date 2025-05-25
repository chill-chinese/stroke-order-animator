import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:stroke_order_animator/stroke_order_animator.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: 1.2),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _httpClient = http.Client();
  final _textController = TextEditingController();

  StrokeOrderAnimationController? _completedController;
  late Future<StrokeOrderAnimationController> _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = _loadStrokeOrder('永');
    _animationController.then((a) => _completedController = a);
  }

  @override
  void dispose() {
    _httpClient.close();
    _completedController?.dispose();
    super.dispose();
  }

  Future<StrokeOrderAnimationController> _loadStrokeOrder(
    String character,
  ) {
    return downloadStrokeOrder(character, _httpClient).then((value) {
      final controller = StrokeOrderAnimationController(
        StrokeOrder(value),
        this,
        onQuizCompleteCallback: (summary) {
          Fluttertoast.showToast(
            msg: 'Quiz finished. ${summary.nTotalMistakes} mistakes',
          );

          setState(() {});
        },
      );

      return controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 500,
          child: Column(
            children: [
              const SizedBox(height: 50),
              _buildCharacterInputField(),
              const SizedBox(height: 50),
              _buildStrokeOrderAnimationAndControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterInputField() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                constraints: BoxConstraints(maxWidth: 320),
                border: OutlineInputBorder(),
                hintText: 'Enter a character',
              ),
              onChanged: _onTextFieldChanged,
            ),
            const Tooltip(
              message: copyRightDisclaimer,
              child: Padding(
                padding: EdgeInsets.only(left: 10),
                child: Icon(Icons.help_outline),
              ),
            ),
          ],
        ),
        SelectableText(
          "Examples: ${["永", "你", "㼌", "丸", "亟", "罵"].join(', ')}",
        ),
      ],
    );
  }

  void _onTextFieldChanged(String value) {
    if (value.characters.isEmpty) {
      return;
    }

    if (value.characters.length > 1) {
      _textController.text = value.characters.last;
      // Move cursor to end
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }

    setState(() {
      _animationController = _loadStrokeOrder(_textController.text);
      _animationController.then((a) => _completedController = a);
    });
  }

  FutureBuilder<StrokeOrderAnimationController>
      _buildStrokeOrderAnimationAndControls() {
    return FutureBuilder(
      future: _animationController,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasData) {
          return Expanded(
            child: Column(
              children: [
                _buildStrokeOrderAnimation(snapshot.data!),
                _buildAnimationControls(snapshot.data!),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStrokeOrderAnimation(StrokeOrderAnimationController controller) {
    return StrokeOrderAnimator(
      controller,
      size: const Size(300, 300),
      key: UniqueKey(),
    );
  }

  Widget _buildAnimationControls(StrokeOrderAnimationController controller) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) => Flexible(
        child: GridView(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: 3,
            crossAxisCount: 2,
            mainAxisSpacing: 10,
          ),
          primary: false,
          children: <Widget>[
            MaterialButton(
              onPressed: controller.isQuizzing
                  ? null
                  : (controller.isAnimating
                      ? controller.stopAnimation
                      : controller.startAnimation),
              child: controller.isAnimating
                  ? const Text('Stop animation')
                  : const Text('Start animation'),
            ),
            MaterialButton(
              onPressed: controller.isQuizzing
                  ? controller.stopQuiz
                  : controller.startQuiz,
              child: controller.isQuizzing
                  ? const Text('Stop quiz')
                  : const Text('Start quiz'),
            ),
            MaterialButton(
              onPressed: controller.isQuizzing ? null : controller.nextStroke,
              child: const Text('Next stroke'),
            ),
            MaterialButton(
              onPressed:
                  controller.isQuizzing ? null : controller.previousStroke,
              child: const Text('Previous stroke'),
            ),
            MaterialButton(
              onPressed:
                  controller.isQuizzing ? null : controller.showFullCharacter,
              child: const Text('Show full character'),
            ),
            MaterialButton(
              onPressed: controller.reset,
              child: const Text('Reset'),
            ),
            MaterialButton(
              onPressed: () {
                controller.setShowOutline(!controller.showOutline);
              },
              child: controller.showOutline
                  ? const Text('Hide outline')
                  : const Text('Show outline'),
            ),
            MaterialButton(
              onPressed: () {
                controller.setShowBackground(!controller.showBackground);
              },
              child: controller.showBackground
                  ? const Text('Hide background')
                  : const Text('Show background'),
            ),
            MaterialButton(
              onPressed: () {
                controller.setShowMedian(!controller.showMedian);
              },
              child: controller.showMedian
                  ? const Text('Hide medians')
                  : const Text('Show medians'),
            ),
            MaterialButton(
              onPressed: () {
                controller.setHighlightRadical(!controller.highlightRadical);
              },
              child: controller.highlightRadical
                  ? const Text('Unhighlight radical')
                  : const Text('Highlight radical'),
            ),
            MaterialButton(
              onPressed: () {
                controller.setShowUserStroke(!controller.showUserStroke);
              },
              child: controller.showUserStroke
                  ? const Text('Hide user strokes')
                  : const Text('Show user strokes'),
            ),
          ],
        ),
      ),
    );
  }
}

const copyRightDisclaimer =
    'This package implements stroke order animations and quizzes of '
    'Chinese characters based on the '
    'Make me a Hanzi project '
    '(https://github.com/skishore/makemeahanzi). '
    'The stroke order data is available under the '
    'ARPHIC public license '
    '(https://www.freedesktop.org/wiki/Arphic_Public_License/).';
