# Stroke order animator

This package implements stroke order animations of Chinese characters based on the [Make me a Hanzi](https://github.com/skishore/makemeahanzi) data.
That data is available under the [ARPHIC public license](ARPHICPL.txt).

The package uses a `StrokeOrderAnimationController` that handles the animation state and serves as an interface between your app and the stroke order animation. The stroke order data has to be passed in as a JSON string. In order to control animations, a `TickerProvider` must be passed to the controller, for example using a `TickerProviderStateMixin`. The controller is then passed as an argument to the `StrokeOrderAnimator` that displays the actual stroke order diagram.

All attributes of the stroke order diagram are controlled via the `StrokeOrderAnimationController`.

At the moment, the controller supports the following attributes and controls:

### Attributes
* Animation speed (as duration in seconds)
* Show/hide strokes
* Show/hide outlines
* Show/hide medians
* Highlight radicals
* Stroke color
* Outline color
* Median color
* Radical color

### Controls
* Start/stop animation
* Show next stroke
* Show previous stroke
* Reset animation
* Show full character

Please file an issue if something doesn't work as expected.
Check out the example section for a full working example showing several stroke order diagrams in a swipeable page view.