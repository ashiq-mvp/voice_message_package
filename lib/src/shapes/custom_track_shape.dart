import 'package:flutter/material.dart';

///
/// A custom track shape for a slider that is rounded rectangular in shape.
/// Extends the [RoundedRectSliderTrackShape] class.
class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override

  /// Returns the preferred rectangle for the voice message view.
  ///
  /// The preferred rectangle is calculated based on the current state and layout
  /// of the voice message view. It represents the area where the view should be
  /// displayed on the screen.
  ///
  /// Returns a [Rect] object representing the preferred rectangle.
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    const double trackHeight = 10;
    final double trackLeft = offset.dx,
        trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
