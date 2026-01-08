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

  static const String _tickSoundAsset = 'sounds/tile_slide_tick.mp3';
  static const int _tickPoolSize = 6;
  static const double _tickPlaybackRate = 1.2;
  final List<html.AudioElement> _tickPool = <html.AudioElement>[];
  int _tickPoolIndex = 0;

  bool get _isSafari {
    final ua = html.window.navigator.userAgent;

    final isAppleWebKit = ua.contains('AppleWebKit');
    final isSafari = ua.contains('Safari');
    final isChrome = ua.contains('Chrome') || ua.contains('CriOS');
    final isFirefox = ua.contains('Firefox') || ua.contains('FxiOS');
    final isEdge = ua.contains('Edg') || ua.contains('EdgiOS');

    return isAppleWebKit && isSafari && !(isChrome || isFirefox || isEdge);
  }
  
  // Preload these sounds during initialization
  static const _soundsToPreload = [
    'sounds/tile_slide_tick.mp3',
    'sounds/new_game_chime.wav',
    'sounds/game_win_fanfare.wav',
  ];

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    
    debugPrint('Web audio manager ready');

    // Pre-create a small pool for the tick sound (reduces Safari latency).
    for (int i = 0; i < _tickPoolSize; i++) {
      _tickPool.add(_createAudio(_tickSoundAsset, playbackRate: _tickPlaybackRate));
    }

    // Preload all other sounds using the shared cache.
    for (final sound in _soundsToPreload) {
      if (sound == _tickSoundAsset) continue;
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
      if (assetPath == _tickSoundAsset && _tickPool.isNotEmpty) {
        // User request: no tile slide sound on Safari.
        if (_isSafari) return;

        final audio = _tickPool[_tickPoolIndex];
        _tickPoolIndex = (_tickPoolIndex + 1) % _tickPool.length;
        audio.volume = 1.0;
        audio.playbackRate = _tickPlaybackRate;
        try {
          audio.currentTime = 0;
        } catch (_) {
          // Ignore if not seekable yet; still try to play.
        }
        unawaited(audio.play());
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

    for (final audio in _tickPool) {
      audio.pause();
      audio.src = '';
    }
    _tickPool.clear();

    for (final audio in _audioCache.values) {
      audio.pause();
      audio.src = '';
    }
    _audioCache.clear();
  }
}
