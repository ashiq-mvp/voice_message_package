import 'package:flutter/material.dart';
import 'package:voice_message_package/src/helpers/utils.dart';
import 'package:voice_message_package/src/shapes/custom_track_shape.dart';
import 'package:voice_message_package/src/voice_controller.dart';
import 'package:voice_message_package/src/widgets/noises.dart';
import 'package:voice_message_package/src/widgets/play_pause_button.dart';

/// A widget that displays a voice message with play/pause, slider, noise visualization, and speed control.
class VoiceMessageView extends StatelessWidget {
  const VoiceMessageView({
    super.key,
    this.innerPadding = 12,
    this.cornerRadius = 20,
    required this.controller,
    this.notActiveSliderColor,
    this.circlesColor = Colors.red,
    this.backgroundColor = Colors.white,
    this.activeSliderColor = Colors.red,
    this.playPauseButtonLoadingColor = Colors.white,
    this.size = 38,
    this.refreshIcon = const Icon(
      Icons.refresh,
      color: Colors.white,
    ),
    this.pauseIcon = const Icon(
      Icons.pause_rounded,
      color: Colors.white,
    ),
    this.playIcon = const Icon(
      Icons.play_arrow_rounded,
      color: Colors.white,
    ),
    this.stopDownloadingIcon = const Icon(
      Icons.close,
      color: Colors.white,
    ),
    this.playPauseButtonDecoration,
    this.circlesTextStyle = const TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    ),
    this.counterTextStyle = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ),
  });

  final double size;
  final Widget playIcon;
  final Widget pauseIcon;
  final Color circlesColor;
  final Widget refreshIcon;
  final double cornerRadius;
  final double innerPadding;
  final Color backgroundColor;
  final Color activeSliderColor;
  final Widget stopDownloadingIcon;
  final TextStyle circlesTextStyle;
  final TextStyle counterTextStyle;
  final VoiceController controller;
  final Color? notActiveSliderColor;
  final Color playPauseButtonLoadingColor;
  final Decoration? playPauseButtonDecoration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = circlesColor;
    final sliderTheme = theme.copyWith(
      sliderTheme: SliderThemeData(
        trackShape: CustomTrackShape(),
        thumbShape: SliderComponentShape.noThumb,
        minThumbSeparation: 0,
      ),
      splashColor: Colors.transparent,
    );

    return Container(
      width: 160 + (controller.noiseCount * .72.w()),
      padding: EdgeInsets.all(innerPadding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
      child: ValueListenableBuilder(
        valueListenable: controller.updater,
        builder: (context, _, __) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Play/Pause Button
              PlayPauseButton(
                controller: controller,
                color: color,
                loadingColor: playPauseButtonLoadingColor,
                size: size,
                refreshIcon: refreshIcon,
                pauseIcon: pauseIcon,
                playIcon: playIcon,
                stopDownloadingIcon: stopDownloadingIcon,
                buttonDecoration: playPauseButtonDecoration,
              ),

              const SizedBox(width: 10),

              // Slider and Noise visualization
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _noises(sliderTheme),
                    const SizedBox(height: 4),
                    Text(controller.remindingTime, style: counterTextStyle),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Speed button
              _changeSpeedButton(color),

              const SizedBox(width: 10),
            ],
          );
        },
      ),
    );
  }

  /// Builds the noise bars and the slider overlay.
  SizedBox _noises(ThemeData sliderTheme) => SizedBox(
        height: 30,
        width: controller.noiseWidth,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Noise visualization bars
            Noises(
              rList: controller.randoms!,
              activeSliderColor: activeSliderColor,
            ),

            // Animated sliding "inactive" overlay bar
            AnimatedBuilder(
              animation: CurvedAnimation(
                parent: controller.animController,
                curve: Curves.ease,
              ),
              builder: (context, child) {
                return Positioned(
                  left: controller.animController.value,
                  child: Container(
                    width: controller.noiseWidth,
                    height: 6.w(),
                    color: notActiveSliderColor ??
                        backgroundColor.withValues(alpha: .4),
                  ),
                );
              },
            ),

            // Transparent Slider for user interaction on top of noise bars
            Opacity(
              opacity: 0,
              child: Container(
                width: controller.noiseWidth,
                color: Colors.transparent.withValues(alpha: 1),
                child: Theme(
                  data: sliderTheme,
                  child: Slider(
                    value: controller.currentMillSeconds,
                    max: controller.maxMillSeconds,
                    onChangeStart: controller.onChangeSliderStart,
                    onChanged: controller.onChanging,
                    onChangeEnd: (value) {
                      controller.onSeek(Duration(milliseconds: value.toInt()));
                      controller.play();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  /// Speed change button with current play speed text.
  Transform _changeSpeedButton(Color color) => Transform.translate(
        offset: const Offset(0, -7),
        child: GestureDetector(
          onTap: () => controller.changeSpeed(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              controller.speed.playSpeedStr,
              style: circlesTextStyle,
            ),
          ),
        ),
      );
}

/// Extension for percentage width based on screen width.
/// Usage: 20.w() means 20% of screen width.
extension SizeExtensions on double {
  double w([BuildContext? context]) {
    double screenWidth;

    if (context != null) {
      // Get width from MediaQuery in the context
      screenWidth = MediaQuery.of(context).size.width;
    } else {
      // No context, get the primary FlutterView physical size from PlatformDispatcher
      // and convert physical pixels to logical pixels by dividing by devicePixelRatio
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      screenWidth = view.physicalSize.width / view.devicePixelRatio;
    }

    return (this / 100) * screenWidth;
  }
}

/// Extension to modify color alpha and optionally other properties.
/// Example: color.withValues(alpha: 0.4) sets alpha to 0.4 while keeping other values.
extension ColorExtensions on Color {
  Color withValues({
    double? alpha,
    double? red,
    double? green,
    double? blue,
  }) {
    return Color.fromARGB(
      ((alpha ?? a) * 255).round().clamp(0, 255),
      (red ?? r).round().clamp(0, 255),
      (green ?? g).round().clamp(0, 255),
      (blue ?? b).round().clamp(0, 255),
    );
  }
}
