import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:stroke_order_animator/getStrokeOrder.dart';
import 'package:stroke_order_animator/strokeOrderAnimationController.dart';
import 'package:stroke_order_animator/strokeOrderAnimator.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _client = Client();
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  static const characters = ["永", "你", "㼌", "丸", "亟", "罵"];

  List<StrokeOrderAnimationController?> _strokeOrderAnimationControllers =
      List.filled(characters.length, null);

  @override
  void initState() {
    super.initState();
    _loadStrokeOrders();
  }

  void _loadStrokeOrders() async {
    for (var i = 0; i < characters.length; i++) {
      getStrokeOrder(characters[i], _client).then((value) {
        final animationController = StrokeOrderAnimationController(
          value,
          this,
          onQuizCompleteCallback: (summary) {
            Fluttertoast.showToast(
                msg: [
              "Quiz finished. ",
              summary.nTotalMistakes.toString(),
              " mistakes"
            ].join());

            setState(() {});
          },
        );
        _strokeOrderAnimationControllers[i] = animationController;

        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _client.close();
    _pageController.dispose();
    for (var controller in _strokeOrderAnimationControllers) {
      controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Character Animator")),
      body: _buildContent(),
    );
  }

  Center _buildContent() {
    final _activeController = _strokeOrderAnimationControllers[_selectedIndex];
    return Center(
      child: SizedBox(
        width: 500,
        child: Column(
          children: [
            _buildPreviousAndNextButton(_activeController),
            _buildStrokeOrderAnimation(_activeController),
            _buildAnimationControls(_activeController),
          ].nonNulls.toList(),
        ),
      ),
    );
  }

  Row _buildPreviousAndNextButton(StrokeOrderAnimationController? controller) {
    final previousAndNextButton = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MaterialButton(
          onPressed: () {
            if (controller == null || !controller.isQuizzing) {
              _pageController.previousPage(
                duration: Duration(milliseconds: 500),
                curve: Curves.ease,
              );
            }
          },
          child: Text("Previous character"),
        ),
        Spacer(),
        MaterialButton(
          onPressed: () {
            if (controller == null || !controller.isQuizzing) {
              _pageController.nextPage(
                duration: Duration(milliseconds: 500),
                curve: Curves.ease,
              );
            }
          },
          child: Text("Next character"),
        ),
      ],
    );
    return previousAndNextButton;
  }

  Expanded _buildStrokeOrderAnimation(
    StrokeOrderAnimationController? activeController,
  ) {
    return Expanded(
      child: PageView(
        physics: activeController?.isQuizzing ?? false
            ? NeverScrollableScrollPhysics()
            : ScrollPhysics(),
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        children: List.generate(
          _strokeOrderAnimationControllers.length,
          (index) =>
              ChangeNotifierProvider<StrokeOrderAnimationController?>.value(
            value: _strokeOrderAnimationControllers[index],
            child: Consumer<StrokeOrderAnimationController?>(
              builder: (context, controller, child) {
                return FittedBox(
                  child: controller == null
                      ? Text(
                          "Loading stroke order data for '" +
                              characters[index] +
                              "'",
                        )
                      : StrokeOrderAnimator(controller, key: UniqueKey()),
                );
              },
            ),
          ),
        ),
        onPageChanged: (index) => {
          setState(
            () {
              _strokeOrderAnimationControllers[_selectedIndex]?.stopAnimation();
              _selectedIndex = index;
            },
          ),
        },
      ),
    );
  }

  Flexible? _buildAnimationControls(
    StrokeOrderAnimationController? controller,
  ) {
    if (controller == null) {
      return null;
    }

    return Flexible(
      child: GridView(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: 3,
          crossAxisCount: 2,
          mainAxisSpacing: 10,
        ),
        primary: false,
        children: <Widget>[
          MaterialButton(
            onPressed: !controller.isQuizzing
                ? () {
                    if (!controller.isAnimating) {
                      controller.startAnimation();
                    } else {
                      controller.stopAnimation();
                    }
                    setState(() {});
                  }
                : null,
            child: controller.isAnimating
                ? Text("Stop animation")
                : Text("Start animation"),
          ),
          MaterialButton(
            onPressed: () {
              if (!controller.isQuizzing) {
                controller.startQuiz();
              } else {
                controller.stopQuiz();
              }

              setState(() {});
            },
            child:
                controller.isQuizzing ? Text("Stop quiz") : Text("Start quiz"),
          ),
          MaterialButton(
            onPressed: !controller.isQuizzing
                ? () {
                    controller.nextStroke();
                  }
                : null,
            child: Text("Next stroke"),
          ),
          MaterialButton(
            onPressed: !controller.isQuizzing
                ? () {
                    controller.previousStroke();
                  }
                : null,
            child: Text("Previous stroke"),
          ),
          MaterialButton(
            onPressed: !controller.isQuizzing
                ? () {
                    controller.showFullCharacter();
                  }
                : null,
            child: Text("Show full character"),
          ),
          MaterialButton(
            onPressed: () {
              controller.reset();
            },
            child: Text("Reset"),
          ),
          MaterialButton(
            onPressed: () {
              controller.setShowOutline(!controller.showOutline);
            },
            child: controller.showOutline
                ? Text("Hide outline")
                : Text("Show Outline"),
          ),
          MaterialButton(
            onPressed: () {
              controller.setShowMedian(!controller.showMedian);
            },
            child: controller.showMedian
                ? Text("Hide medians")
                : Text("Show medians"),
          ),
          MaterialButton(
            onPressed: () {
              controller.setHighlightRadical(!controller.highlightRadical);
            },
            child: controller.highlightRadical
                ? Text("Unhighlight radical")
                : Text("Highlight radical"),
          ),
          MaterialButton(
            onPressed: () {
              controller.setShowUserStroke(!controller.showUserStroke);
            },
            child: controller.showUserStroke
                ? Text("Hide user strokes")
                : Text("Show user strokes"),
          ),
        ],
      ),
    );
  }
}
