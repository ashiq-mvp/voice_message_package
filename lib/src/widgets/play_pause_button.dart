import 'package:flutter/material.dart';
import 'package:voice_message_package/src/widgets/loading_widget.dart';
import 'package:voice_message_package/voice_message_package.dart';

/// A widget representing a play/pause button.
///
/// This button can be used to control the playback of a media player.
class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({
    super.key,
    required this.color,
    required this.size,
    this.buttonDecoration,
    required this.playIcon,
    required this.pauseIcon,
    required this.controller,
    required this.refreshIcon,
    required this.loadingColor,
    required this.stopDownloadingIcon,
  });

  final Color color;
  final double size;
  final Widget playIcon;
  final Widget pauseIcon;
  final Color loadingColor;
  final Widget refreshIcon;
  final Widget stopDownloadingIcon;
  final VoiceController controller;
  final Decoration? buttonDecoration;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: controller.isDownloadError

            /// faild loading audio
            ? controller.play
            : controller.isPlaying

                /// playing or pause
                ? controller.pausePlaying
                : controller.play,
        child: Container(
            height: size,
            width: size,
            decoration: buttonDecoration ??
                BoxDecoration(color: color, shape: BoxShape.circle),
            child: controller.isDownloading
                ? LoadingWidget(
                    progress: controller.downloadProgress,
                    loadingColor: loadingColor,
                    onClose: () {
                      controller.cancelDownload();
                    },
                    stopDownloadingIcon: stopDownloadingIcon,
                  )
                :

                /// faild to load audio
                controller.isDownloadError

                    /// show refresh icon
                    ? refreshIcon
                    : controller.isPlaying
                        ? pauseIcon
                        : playIcon),
      );
}
