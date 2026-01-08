// Native (iOS, Android, Desktop) audio implementation using audioplayers
import 'dart:async';
import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'audio_manager.dart';

AudioManager createAudioManager() => NativeAudioManager();

class NativeAudioManager implements AudioManager {
  // Keep dedicated low-latency players for the move tick sound.
  // On iOS, using a small pool helps avoid latency when moves happen rapidly.
  late final List<AudioPlayer> _tickPlayers;
  int _tickPlayerIndex = 0;

  // General-purpose SFX player (new game, etc.)
  late final AudioPlayer _sfxPlayer;

  late final AudioPlayer _winPlayer;

  static const String _tickSoundAsset = 'sounds/tile_slide_tick.mp3';
  static const double _iosTickPlaybackRate = 1.2;

  @override
  Future<void> initialize() async {
    // Assign fields synchronously first so dispose() is safe even if
    // initialization is still in-flight (common in widget tests).
    _tickPlayers = List<AudioPlayer>.generate(
      Platform.isIOS ? 4 : 1,
      (_) => AudioPlayer(),
    );
    _sfxPlayer = AudioPlayer();
    _winPlayer = AudioPlayer();

    final tickMode = (Platform.isIOS || Platform.isAndroid)
        ? PlayerMode.lowLatency
        : PlayerMode.mediaPlayer;

    for (final player in _tickPlayers) {
      await player.setPlayerMode(tickMode);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(1.0);

      // Preload tick sound to reduce first-play and per-play latency.
      await player.setSource(AssetSource(_tickSoundAsset));
      await player.seek(Duration.zero);

      if (Platform.isIOS) {
        // Make the move tick a bit shorter/snappier on iOS.
        // Not all platforms support playback rate, so ignore failures.
        try {
          await player.setPlaybackRate(_iosTickPlaybackRate);
        } catch (_) {
          // no-op
        }
      }
    }

    final sfxMode = (Platform.isIOS || Platform.isAndroid)
      ? PlayerMode.lowLatency
      : PlayerMode.mediaPlayer;
    await _sfxPlayer.setPlayerMode(sfxMode);
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    await _sfxPlayer.setVolume(1.0);

    await _winPlayer.setReleaseMode(ReleaseMode.stop);
    await _winPlayer.setVolume(1.0);
    
    debugPrint('Native audio initialized successfully');
  }

  @override
  void playSound(String assetPath) {
    if (assetPath == _tickSoundAsset) {
      // User request: no tile slide sound on iOS.
      if (Platform.isIOS) return;

      // Fast path: avoid stop+play overhead; just rewind and resume.
      unawaited(() async {
        try {
          final player = _tickPlayers[_tickPlayerIndex];
          _tickPlayerIndex = (_tickPlayerIndex + 1) % _tickPlayers.length;

          // On desktop backends, seek+resume can be flaky for MP3 sources.
          // Use stop+play for reliability.
          if (!(Platform.isAndroid || Platform.isIOS)) {
            await player.stop();
            await player.play(AssetSource(_tickSoundAsset));
            return;
          }

          await player.seek(Duration.zero);
          await player.resume();
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
    for (final player in _tickPlayers) {
      player.dispose();
    }
    _sfxPlayer.dispose();
    _winPlayer.dispose();
  }
}
