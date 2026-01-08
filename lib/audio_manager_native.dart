// Native (iOS, Android, Desktop) audio implementation using audioplayers
import 'dart:async';
import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'audio_manager.dart';

AudioManager createAudioManager() => NativeAudioManager();

class NativeAudioManager implements AudioManager {
  // Keep a dedicated low-latency player for the move tick sound to minimize
  // iOS latency/jank.
  late final AudioPlayer _tickPlayer;

  // General-purpose SFX player (new game, etc.)
  late final AudioPlayer _sfxPlayer;

  late final AudioPlayer _winPlayer;

  static const String _tickSoundAsset = 'sounds/tile_tick.wav';
  static const double _iosTickPlaybackRate = 1.2;

  @override
  Future<void> initialize() async {
    // Assign fields synchronously first so dispose() is safe even if
    // initialization is still in-flight (common in widget tests).
    _tickPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();
    _winPlayer = AudioPlayer();

    await _tickPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _tickPlayer.setReleaseMode(ReleaseMode.stop);
    await _tickPlayer.setVolume(1.0);

    // Preload tick sound to reduce first-play and per-play latency.
    await _tickPlayer.setSource(AssetSource(_tickSoundAsset));
    await _tickPlayer.seek(Duration.zero);

    if (Platform.isIOS) {
      // Make the move tick a bit shorter/snappier on iOS.
      // Not all platforms support playback rate, so ignore failures.
      try {
        await _tickPlayer.setPlaybackRate(_iosTickPlaybackRate);
      } catch (_) {
        // no-op
      }
    }

    await _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    await _sfxPlayer.setVolume(1.0);

    await _winPlayer.setReleaseMode(ReleaseMode.stop);
    await _winPlayer.setVolume(1.0);
    
    debugPrint('Native audio initialized successfully');
  }

  @override
  void playSound(String assetPath) {
    if (assetPath == _tickSoundAsset) {
      // Fast path: avoid stop+play overhead; just rewind and resume.
      unawaited(() async {
        try {
          await _tickPlayer.seek(Duration.zero);
          await _tickPlayer.resume();
        } catch (e) {
          debugPrint('Tick audio error: $e');
        }
      }());
      return;
    }

    // Fallback for other one-shot SFX.
    unawaited(() async {
      try {
        await _sfxPlayer.stop();
        await _sfxPlayer.play(AssetSource(assetPath));
      } catch (e) {
        debugPrint('Audio error: $e');
      }
    }());
  }

  @override
  void playWinSound(String assetPath) {
    unawaited(() async {
      try {
        await _winPlayer.stop();
        await _winPlayer.play(AssetSource(assetPath));
      } catch (e) {
        debugPrint('Win audio error: $e');
      }
    }());
  }

  @override
  void dispose() {
    _tickPlayer.dispose();
    _sfxPlayer.dispose();
    _winPlayer.dispose();
  }
}
