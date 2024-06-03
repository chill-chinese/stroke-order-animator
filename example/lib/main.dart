import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:stroke_order_animator/stroke_order_animator.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: 1.2),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _httpClient = http.Client();
  final _textController = TextEditingController();

  late Future<StrokeOrderAnimationController> _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = _loadStrokeOrder('永');
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  Future<StrokeOrderAnimationController> _loadStrokeOrder(
    String character,
  ) async {
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
              SizedBox(height: 50),
              _buildCharacterInputField(),
              SizedBox(height: 50),
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
              decoration: InputDecoration(
                constraints: BoxConstraints(maxWidth: 320),
                border: OutlineInputBorder(),
                hintText: 'Enter a character',
              ),
              onChanged: _onTextFieldChanged,
            ),
            Tooltip(
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
    });
  }

  FutureBuilder<StrokeOrderAnimationController>
      _buildStrokeOrderAnimationAndControls() {
    return FutureBuilder(
      future: _animationController,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return CircularProgressIndicator();
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

        return SizedBox.shrink();
      },
    );
  }

  Widget _buildStrokeOrderAnimation(StrokeOrderAnimationController controller) {
    return ChangeNotifierProvider<StrokeOrderAnimationController>.value(
      value: controller,
      child: Consumer<StrokeOrderAnimationController>(
        builder: (context, controller, child) {
          return StrokeOrderAnimator(
            controller,
            size: Size(300, 300),
            key: UniqueKey(),
          );
        },
      ),
    );
  }

  Widget _buildAnimationControls(StrokeOrderAnimationController controller) {
    return ChangeNotifierProvider.value(
      value: controller,
      builder: (context, child) => Consumer<StrokeOrderAnimationController>(
        builder: (context, controller, child) => Flexible(
          child: GridView(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                    ? Text('Stop animation')
                    : Text('Start animation'),
              ),
              MaterialButton(
                onPressed: controller.isQuizzing
                    ? controller.stopQuiz
                    : controller.startQuiz,
                child: controller.isQuizzing
                    ? Text('Stop quiz')
                    : Text('Start quiz'),
              ),
              MaterialButton(
                onPressed: controller.isQuizzing ? null : controller.nextStroke,
                child: Text('Next stroke'),
              ),
              MaterialButton(
                onPressed:
                    controller.isQuizzing ? null : controller.previousStroke,
                child: Text('Previous stroke'),
              ),
              MaterialButton(
                onPressed:
                    controller.isQuizzing ? null : controller.showFullCharacter,
                child: Text('Show full character'),
              ),
              MaterialButton(
                onPressed: controller.reset,
                child: Text('Reset'),
              ),
              MaterialButton(
                onPressed: () {
                  controller.setShowOutline(!controller.showOutline);
                },
                child: controller.showOutline
                    ? Text('Hide outline')
                    : Text('Show Outline'),
              ),
              MaterialButton(
                onPressed: () {
                  controller.setShowMedian(!controller.showMedian);
                },
                child: controller.showMedian
                    ? Text('Hide medians')
                    : Text('Show medians'),
              ),
              MaterialButton(
                onPressed: () {
                  controller.setHighlightRadical(!controller.highlightRadical);
                },
                child: controller.highlightRadical
                    ? Text('Unhighlight radical')
                    : Text('Highlight radical'),
              ),
              MaterialButton(
                onPressed: () {
                  controller.setShowUserStroke(!controller.showUserStroke);
                },
                child: controller.showUserStroke
                    ? Text('Hide user strokes')
                    : Text('Show user strokes'),
              ),
            ],
          ),
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
