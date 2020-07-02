# Stroke order animator

[![Pub](https://img.shields.io/pub/v/stroke_order_animator.svg)](https://pub.dev/packages/stroke_order_animator)

This package implements stroke order animations and quizzes of Chinese characters based on the [Make me a Hanzi](https://github.com/skishore/makemeahanzi) data.
That data is available under the [ARPHIC public license](ARPHICPL.txt).

The package uses a `StrokeOrderAnimationController` that handles the animation state and serves as an interface between your app and the stroke order animation. The stroke order data has to be passed in as a JSON string. In order to control animations, a `TickerProvider` must be passed to the controller, for example using a `TickerProviderStateMixin`. The controller is then passed as an argument to the `StrokeOrderAnimator` that displays the actual stroke order diagram.

When using the animations in a PageView or ListView, it is recommended to use a unique key for every `StrokeOrderAnimator` and cancel the animation when the selected page changes in order to avoid broken animation behaviour.

All attributes and actions of the stroke order diagram are controlled via the `StrokeOrderAnimationController` and can be changed anytime using the respective setter methods.

## Attributes

* Animation speed of stroke animations and hints in quiz mode (3 is pretty fast)
* Whether to show/hide strokes
* Whether to show/hide outlines
* Whether to show/hide medians
* Whether to highlight radicals
* Stroke color
* Outline color
* Median color
* Radical color
* Brush color in quiz mode
* Brush thickness in quiz mode
* Number of wrong strokes before showing a hint in quiz mode
* Hint color in quiz mode

## Controls

* Start/stop animation
* Start/stop quiz
* Show next/previous stroke
* Show full character
* Reset animation/quiz

## Callbacks

To better integrate the quizzes, three callbacks can be either passed to the `StrokeOrderAnimationController` during instantiation or afterwards using the `add...Callback` method:
* onWrongStrokeCallback
* onCorrectStrokeCallback
* onQuizCompleteCallback

The `onQuizCompleteCallback` receives a `Quizsummary` containing the number of mistakes on a per-stroke basis. There other two callbacks receive the index of the stroke that was written (in-)correctly. All indices are zero-based.

## Example

To run an example showing several stroke order diagrams in a swipeable page view run the following:

```
git clone https://github.com/Mr-Pepe/stroke-order-animator
cd stroke-order-animator/example/
flutter run
```

## Issues and feature requests

Please file an issue on the project page if something doesn't work as expected or if you have a feature request.

## Contribute

Feel free to open a pull request. Just make sure to write extensive tests.