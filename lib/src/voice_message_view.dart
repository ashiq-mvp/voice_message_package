import 'package:flutter/material.dart';
import 'package:voice_message_package/src/helpers/utils.dart';
import 'package:voice_message_package/src/shapes/custom_track_shape.dart';
import 'package:voice_message_package/src/voice_controller.dart';
import 'package:voice_message_package/src/widgets/noises.dart';
import 'package:voice_message_package/src/widgets/play_pause_button.dart';

/// A widget that displays a voice message view with play/pause functionality.
///
/// The [VoiceMessageView] widget is used to display a voice message with customizable appearance and behavior.
/// It provides a play/pause button, a progress slider, and a counter for the remaining time.
/// The appearance of the widget can be customized using various properties such as background color, slider color, and text styles.
///
class VoiceMessageView extends StatelessWidget {
  const VoiceMessageView({
    super.key,
    this.innerPadding = 12,
    this.cornerRadius = 20,
    required this.controller,
    // this.playerWidth = 170,
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
    final ThemeData theme = Theme.of(context);
    final color = circlesColor;
    final newTHeme = theme.copyWith(
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
        /// update ui when change play status
        valueListenable: controller.updater,
        builder: (context, value, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// play pause button
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

              ///
              const SizedBox(width: 10),

              /// slider & noises
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _noises(newTHeme),
                    const SizedBox(height: 4),
                    Text(controller.remindingTime, style: counterTextStyle),
                  ],
                ),
              ),

              ///
              const SizedBox(width: 12),

              /// speed button
              _changeSpeedButton(color),

              ///
              const SizedBox(width: 10),
            ],
          );
        },
      ),
    );
  }

  SizedBox _noises(ThemeData newTHeme) => SizedBox(
        height: 30,
        width: controller.noiseWidth,
        child: Stack(
          alignment: Alignment.center,
          children: [
            /// noises
            Noises(
              rList: controller.randoms!,
              activeSliderColor: activeSliderColor,
            ),

            /// slider
            AnimatedBuilder(
              animation: CurvedAnimation(
                parent: controller.animController,
                curve: Curves.ease,
              ),
              builder: (BuildContext context, Widget? child) {
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
            Opacity(
              opacity: 0,
              child: Container(
                width: controller.noiseWidth,
                color: Colors.transparent.withValues(alpha: 1),
                child: Theme(
                  data: newTHeme,
                  child: Slider(
                    value: controller.currentMillSeconds,
                    max: controller.maxMillSeconds,
                    onChangeStart: controller.onChangeSliderStart,
                    onChanged: controller.onChanging,
                    onChangeEnd: (value) {
                      controller.onSeek(
                        Duration(milliseconds: value.toInt()),
                      );
                      controller.play();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Transform _changeSpeedButton(Color color) => Transform.translate(
        offset: const Offset(0, -7),
        child: GestureDetector(
          onTap: () {
            controller.changeSpeed();
          },
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
