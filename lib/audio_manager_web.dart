// ignore_for_file: avoid_web_libraries_in_flutter

// Web-specific audio implementation.
// Safari/iOS has noticeable latency when repeatedly restarting the same
// HTMLAudioElement. To reduce this for the tile-tick sound we keep a small pool
// of preloaded elements and round-robin them.
import 'dart:html' as html;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'audio_manager.dart';

AudioManager createAudioManager() => WebAudioManager();

class WebAudioManager implements AudioManager {
  // HTMLAudioElement cache for non-tick sounds
  final Map<String, html.AudioElement> _audioCache = {};
  html.AudioElement? _currentSound;
  bool _initialized = false;

  static const String _tickSoundAssetWav = 'sounds/tile_tick.wav';
  static const String _tickSoundAssetMp3 = 'sounds/tile_slide_tick.mp3';
  static const int _tickPoolSize = 6;
  static const double _tickPlaybackRate = 1.2;
  final List<html.AudioElement> _tickPoolMp3 = <html.AudioElement>[];
  final List<html.AudioElement> _tickPoolWav = <html.AudioElement>[];
  int _tickPoolIndex = 0;
  bool _forceWavTick = false;

  bool get _isSafari {
    final ua = html.window.navigator.userAgent;

    final isAppleWebKit = ua.contains('AppleWebKit');
    final isSafari = ua.contains('Safari');
    final isChrome = ua.contains('Chrome') || ua.contains('CriOS');
    final isFirefox = ua.contains('Firefox') || ua.contains('FxiOS');
    final isEdge = ua.contains('Edg') || ua.contains('EdgiOS');

    return isAppleWebKit && isSafari && !(isChrome || isFirefox || isEdge);
  }

  bool get _isChromium {
    final ua = html.window.navigator.userAgent;
    final isChrome = ua.contains('Chrome') || ua.contains('CriOS');
    final isEdge = ua.contains('Edg') || ua.contains('EdgiOS');
    return isChrome || isEdge;
  }
  
  // Preload these sounds during initialization
  static const _soundsToPreload = [
    'sounds/tile_tick.wav',
    'sounds/tile_slide_tick.mp3',
    'sounds/new_game_chime.wav',
    'sounds/game_win_fanfare.wav',
  ];

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    
    debugPrint('Web audio manager ready');

    // Pre-create pools for the tick sound.
    // Some Chromium builds appear picky about MP3 (or GitHub Pages mime-type),
    // so we keep a WAV fallback to avoid total silence.
    _forceWavTick = _isChromium;
    for (int i = 0; i < _tickPoolSize; i++) {
      _tickPoolMp3.add(
        _createAudio(_tickSoundAssetMp3, playbackRate: _tickPlaybackRate),
      );
      _tickPoolWav.add(
        _createAudio(_tickSoundAssetWav, playbackRate: _tickPlaybackRate),
      );
    }

    // Preload all other sounds using the shared cache.
    for (final sound in _soundsToPreload) {
      if (sound == _tickSoundAssetMp3 || sound == _tickSoundAssetWav) continue;
      _getOrCreateAudio(sound);
    }
  }

  html.AudioElement _createAudio(String assetPath, {double? playbackRate}) {
    final audio = html.AudioElement();
    audio.src = Uri.base.resolve('assets/assets/$assetPath').toString();
    audio.preload = 'auto';
    audio.volume = 1.0;
    if (playbackRate != null) {
      // Supported by Safari/iOS; safe to set in other browsers too.
      audio.playbackRate = playbackRate;
    }
    audio.load();
    return audio;
  }

  html.AudioElement _getOrCreateAudio(String assetPath) {
    if (_audioCache.containsKey(assetPath)) {
      return _audioCache[assetPath]!;
    }
    
    final audio = html.AudioElement();
    // Flutter web serves bundled assets under `assets/` and preserves the
    // original asset key path. Since our asset keys are `assets/sounds/...`
    // and we pass in `sounds/...`, the correct URL is:
    //   <base-href>/assets/assets/sounds/...
    audio.src = Uri.base.resolve('assets/assets/$assetPath').toString();
    audio.preload = 'auto';
    
    // Add error handling
    audio.onError.listen((event) {
      debugPrint('Failed to load audio: ${audio.src}');
    });
    
    audio.onCanPlayThrough.listen((event) {
      debugPrint('Audio loaded successfully: ${audio.src}');
    });
    
    // Load the audio file
    audio.load();
    
    _audioCache[assetPath] = audio;
    return audio;
  }

  @override
  void playSound(String assetPath) {
    try {
      final isTick =
          assetPath == _tickSoundAssetWav || assetPath == _tickSoundAssetMp3;

      if (isTick && (_tickPoolWav.isNotEmpty || _tickPoolMp3.isNotEmpty)) {
        // User request: no tile slide sound on Safari.
        if (_isSafari) return;

        // Prefer WAV for desktop browsers (especially Chromium).
        final pool = (_forceWavTick || assetPath == _tickSoundAssetWav)
            ? _tickPoolWav
            : _tickPoolMp3;
        if (pool.isEmpty) return;

        final audio = pool[_tickPoolIndex];
        _tickPoolIndex = (_tickPoolIndex + 1) % pool.length;
        audio.volume = 1.0;
        audio.playbackRate = _tickPlaybackRate;
        try {
          audio.currentTime = 0;
        } catch (_) {
          // Ignore if not seekable yet; still try to play.
        }

        audio.play().catchError((e) {
          // If MP3 fails, fall back to WAV.
          if (!_forceWavTick) {
            _forceWavTick = true;
            debugPrint('⚠️ Tick playback failed; switching to WAV: $e');
          }
        });
        return;
      }

      final audio = _getOrCreateAudio(assetPath);
      audio.pause();
      audio.volume = 1.0;
      audio.currentTime = 0;
      unawaited(audio.play());
      _currentSound = audio;
    } catch (e) {
      debugPrint('❌ Web exception: $e');
    }
  }

  @override
  void playWinSound(String assetPath) {
    // Win sound is less latency-sensitive; reuse cached element.
    playSound(assetPath);
  }

  @override
  void dispose() {
    _currentSound?.pause();

    for (final audio in _tickPoolMp3) {
      audio.pause();
      audio.src = '';
    }
    _tickPoolMp3.clear();

    for (final audio in _tickPoolWav) {
      audio.pause();
      audio.src = '';
    }
    _tickPoolWav.clear();

    for (final audio in _audioCache.values) {
      audio.pause();
      audio.src = '';
    }
    _audioCache.clear();
  }
}
