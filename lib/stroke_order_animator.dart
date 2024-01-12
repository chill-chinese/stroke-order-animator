/// This package implements stroke order animations and quizzes of Chinese
/// characters based on the
/// [Make me a Hanzi](https://github.com/skishore/makemeahanzi) data.
///
/// Integrating this package into your app is easy. Follow these steps:
///
/// 1. Download stroke order data via [downloadStrokeOrder]
/// 2. Pass the retrieved data to [StrokeOrder]
/// 3. Pass the [StrokeOrder] to a [StrokeOrderAnimationController]
/// 4. Pass the [StrokeOrderAnimationController] to a [StrokeOrderAnimator]
///
/// The first step can be skipped for offline usage. In this case, the stroke
/// order data must be passed to the [StrokeOrder] constructor directly as JSON.
/// All stroke order data can be downloaded from
/// [here](https://raw.githubusercontent.com/skishore/makemeahanzi/master/graphics.txt).
/// Data for single characters can be downloaded through the
/// [Hanzi Writer Data](https://github.com/chanind/hanzi-writer-data) project,
/// e.g., via https://cdn.jsdelivr.net/npm/hanzi-writer-data@latest/我.json.
///
/// The [StrokeOrderAnimationController] handles the animation state and serves
/// as an interface between your app and the stroke order animation.
/// All attributes and actions of the stroke order diagram are controlled via
/// the [StrokeOrderAnimationController] and can be changed anytime using the
/// respective setter methods.
/// The [StrokeOrderAnimator] displays the actual stroke order diagram.
library;

export 'src/download_stroke_order.dart' show downloadStrokeOrder;
export 'src/quiz_summary.dart' show QuizSummary;
export 'src/stroke_order.dart' show StrokeOrder;
export 'src/stroke_order_animation_controller.dart'
    show StrokeOrderAnimationController;
export 'src/stroke_order_animator.dart' show StrokeOrderAnimator;
