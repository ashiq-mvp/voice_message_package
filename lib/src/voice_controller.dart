import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:voice_message_package/src/helpers/utils.dart';

/// Enum for play speeds
enum PlaySpeed {
  x1,
  x1_25,
  x1_5,
  x1_75,
  x2,
  x2_25,
}

extension PlaySpeedExtension on PlaySpeed {
  double get getSpeed {
    switch (this) {
      case PlaySpeed.x1:
        return 1.0;
      case PlaySpeed.x1_25:
        return 1.25;
      case PlaySpeed.x1_5:
        return 1.5;
      case PlaySpeed.x1_75:
        return 1.75;
      case PlaySpeed.x2:
        return 2.0;
      case PlaySpeed.x2_25:
        return 2.25;
    }
  }

  String get playSpeedStr {
    switch (this) {
      case PlaySpeed.x1:
        return "1.0x";
      case PlaySpeed.x1_25:
        return "1.25x";
      case PlaySpeed.x1_5:
        return "1.5x";
      case PlaySpeed.x1_75:
        return "1.75x";
      case PlaySpeed.x2:
        return "2.0x";
      case PlaySpeed.x2_25:
        return "2.25x";
    }
  }
}

/// Enum for playback status
enum PlayStatus {
  init,
  playing,
  pause,
  stop,
  downloading,
  downloadError,
}

/// Your VoiceController class
class VoiceController extends MyTicker {
  final bool isFile;
  final int noiseCount;
  final String audioSrc;
  List<double>? randoms;
  final String? cacheKey;
  bool isSeeking = false;
  final VoidCallback onPause;
  late Duration maxDuration;
  final VoidCallback onPlaying;
  final VoidCallback onComplete;
  double? downloadProgress = 0;
  PlaySpeed speed = PlaySpeed.x1;
  final Function(Object)? onError;
  final double noiseWidth =
      50.5; // Assuming .w() is an extension for width, adjust accordingly
  StreamSubscription<Duration>? positionStream;
  StreamSubscription<PlayerState>? playerStateStream;
  PlayStatus playStatus = PlayStatus.init;
  late AnimationController animController;
  Duration currentDuration = Duration.zero;
  final AudioPlayer _player = AudioPlayer();
  ValueNotifier updater = ValueNotifier(null);
  StreamSubscription<FileResponse>? downloadStreamSubscription;

  VoiceController({
    this.onError,
    this.randoms,
    this.cacheKey,
    this.noiseCount = 24,
    required this.isFile,
    required this.onPause,
    required this.audioSrc,
    required this.onPlaying,
    required this.onComplete,
    required this.maxDuration,
  }) {
    if (randoms?.isEmpty ?? true) _setRandoms();
    animController = AnimationController(
      vsync: this,
      upperBound: noiseWidth,
      duration: maxDuration,
    );
    init();
    _listenToRemindingTime();
    _listenToPlayerState();
  }

  Future<void> init() async {
    await setMaxDuration(audioSrc);
    _updateUi();
  }

  /// Starts playing audio with download handling
  Future<void> play() async {
    try {
      playStatus = PlayStatus.downloading;
      _updateUi();
      if (isFile) {
        final path = await _getFileFromCache();
        await startPlaying(path);
        onPlaying();
      } else {
        downloadStreamSubscription = _getFileFromCacheWithProgress().listen(
          (fileResponse) async {
            if (fileResponse is FileInfo) {
              await startPlaying(fileResponse.file.path);
              onPlaying();
            } else if (fileResponse is DownloadProgress) {
              downloadProgress = fileResponse.progress;
              _updateUi();
            }
          },
          onError: (error) {
            playStatus = PlayStatus.downloadError;
            _updateUi();
            if (onError != null) onError!(error);
          },
        );
      }
    } catch (err) {
      playStatus = PlayStatus.downloadError;
      _updateUi();
      if (onError != null) {
        onError!(err);
      } else {
        rethrow;
      }
    }
  }

  void _listenToRemindingTime() {
    positionStream = _player.positionStream.listen((position) {
      if (!isDownloading) currentDuration = position;

      final value = (noiseWidth * currentMillSeconds) / maxMillSeconds;
      animController.value = value;
      _updateUi();

      // Completion handled by playerStateStream already, but in case:
      if (position >= maxDuration) {
        _player.stop();
        currentDuration = Duration.zero;
        playStatus = PlayStatus.init;
        animController.reset();
        _updateUi();
        onComplete();
      }
    });
  }

  void _updateUi() {
    updater.notifyListeners();
  }

  Future<void> stopPlaying() async {
    await _player.pause();
    playStatus = PlayStatus.stop;
    _updateUi();
  }

  Future<void> startPlaying(String path) async {
    // Clear previous source before setting new source to avoid errors
    await _player.stop();
    await _player.setAudioSource(AudioSource.uri(Uri.file(path)),
        initialPosition: currentDuration);
    await _player.setSpeed(speed.getSpeed);
    await _player.play();
    playStatus = PlayStatus.playing;
    _updateUi();
  }

  Future<void> dispose() async {
    await _player.dispose();
    await positionStream?.cancel();
    await playerStateStream?.cancel();
    await downloadStreamSubscription?.cancel();
    animController.dispose();
  }

  void onSeek(Duration duration) {
    isSeeking = false;
    currentDuration = duration;
    _updateUi();
    _player.seek(duration);
  }

  void pausePlaying() {
    _player.pause();
    playStatus = PlayStatus.pause;
    _updateUi();
    onPause();
  }

  Future<String> _getFileFromCache() async {
    if (isFile) return audioSrc;

    final customCacheManager = CacheManager(
      Config(
        cacheKey ?? 'customCacheKey',
        stalePeriod: const Duration(days: 11),
        maxNrOfCacheObjects: 111,
      ),
    );
    final fileInfo = await customCacheManager.getFileFromCache(audioSrc);

    if (fileInfo != null && await fileInfo.file.exists()) {
      return fileInfo.file.path;
    }

    final file =
        await customCacheManager.getSingleFile(audioSrc, key: cacheKey);
    return file.path;
  }

  Stream<FileResponse> _getFileFromCacheWithProgress() {
    if (isFile) {
      throw Exception("This method is not applicable for local files.");
    }
    final customCacheManager = CacheManager(
      Config(
        cacheKey ?? 'customCacheKey',
        stalePeriod: const Duration(days: 11),
        maxNrOfCacheObjects: 111,
      ),
    );
    return customCacheManager.getFileStream(audioSrc,
        key: cacheKey, withProgress: true);
  }

  void cancelDownload() {
    downloadStreamSubscription?.cancel();
    playStatus = PlayStatus.init;
    _updateUi();
  }

  void _listenToPlayerState() {
    playerStateStream = _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        currentDuration = Duration.zero;
        playStatus = PlayStatus.init;
        animController.reset();
        _updateUi();
        onComplete();
      } else if (playerState.playing) {
        playStatus = PlayStatus.playing;
        _updateUi();
      } else if (playerState.processingState == ProcessingState.ready &&
          !playerState.playing) {
        // paused state
        playStatus = PlayStatus.pause;
        _updateUi();
      }
    });
  }

  void changeSpeed() {
    switch (speed) {
      case PlaySpeed.x1:
        speed = PlaySpeed.x1_25;
        break;
      case PlaySpeed.x1_25:
        speed = PlaySpeed.x1_5;
        break;
      case PlaySpeed.x1_5:
        speed = PlaySpeed.x1_75;
        break;
      case PlaySpeed.x1_75:
        speed = PlaySpeed.x2;
        break;
      case PlaySpeed.x2:
        speed = PlaySpeed.x2_25;
        break;
      case PlaySpeed.x2_25:
        speed = PlaySpeed.x1;
        break;
    }
    _player.setSpeed(speed.getSpeed);
    _updateUi();
  }

  void onChangeSliderStart(double value) {
    isSeeking = true;
    pausePlaying();
  }

  void _setRandoms() {
    randoms = List<double>.generate(
        noiseCount, (_) => 5.74 * Random().nextDouble() + 0.26);
  }

  void onChanging(double d) {
    currentDuration = Duration(milliseconds: d.toInt());
    final value = (noiseWidth * d) / maxMillSeconds;
    animController.value = value;
    _updateUi();
  }

  String get remindingTime {
    if (currentDuration == Duration.zero) {
      return maxDuration.formattedTime;
    }
    if (isSeeking || isPause) {
      return currentDuration.formattedTime;
    }
    if (isInit) {
      return maxDuration.formattedTime;
    }
    return currentDuration.formattedTime;
  }

  double get currentMillSeconds {
    final c = currentDuration.inMilliseconds.toDouble();
    return c >= maxMillSeconds ? maxMillSeconds : c;
  }

  bool get isInit => playStatus == PlayStatus.init;
  bool get isStop => playStatus == PlayStatus.stop;
  bool get isPause => playStatus == PlayStatus.pause;
  bool get isPlaying => playStatus == PlayStatus.playing;
  bool get isDownloading => playStatus == PlayStatus.downloading;
  bool get isDownloadError => playStatus == PlayStatus.downloadError;
  double get maxMillSeconds => maxDuration.inMilliseconds.toDouble();

  Future<void> setMaxDuration(String path) async {
    try {
      final duration =
          isFile ? await _player.setFilePath(path) : await _player.setUrl(path);
      if (duration != null) {
        maxDuration = duration;
        animController.duration = maxDuration;
      }
    } catch (err) {
      if (kDebugMode) {
        debugPrint("Can't get max duration from path: $path, error: $err");
      }
      if (onError != null) {
        onError!(err);
      }
    }
  }
}

/// Custom TickerProvider used for AnimationController
class MyTicker extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}
