import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class PlayDuration {
  /// Returns the duration of an audio file from either a URL or a local file.
  /// Pass [isFile] as `true` if it's a local file path.
  static Future<Duration?> getAudioDuration(String source,
      {bool isFile = false}) async {
    final player = AudioPlayer();

    try {
      if (isFile) {
        final file = File(source);
        if (!await file.exists()) {
          throw Exception('File does not exist');
        }
        await player.setFilePath(source);
      } else {
        await player.setUrl(source);
      }

      final duration = player.duration;
      return duration;
    } catch (e) {
      debugPrint('Error getting audio duration: $e');
      return null;
    } finally {
      await player.dispose();
    }
  }
}
