/// Web-specific audio implementation using HTML5 Audio API
/// This provides better Safari/iOS compatibility than audioplayers
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'audio_manager.dart';

AudioManager createAudioManager() => WebAudioManager();

class WebAudioManager implements AudioManager {
  final Map<String, html.AudioElement> _audioCache = {};
  html.AudioElement? _currentSound;
  bool _initialized = false;
  
  // Preload these sounds during initialization
  static const _soundsToPreload = [
    'sounds/tile_tick.wav',
    'sounds/new_game_chime.wav',
    'sounds/game_win_fanfare.wav',
  ];

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    
    debugPrint('Web audio manager ready');
    
    // Preload all sound files
    for (final sound in _soundsToPreload) {
      _getOrCreateAudio(sound);
    }
  }

  html.AudioElement _getOrCreateAudio(String assetPath) {
    if (_audioCache.containsKey(assetPath)) {
      return _audioCache[assetPath]!;
    }
    
    final audio = html.AudioElement();
    audio.src = 'assets/$assetPath';
    audio.preload = 'auto';
    
    // Add error handling
    audio.onError.listen((event) {
      debugPrint('Failed to load audio: assets/$assetPath');
    });
    
    audio.onCanPlayThrough.listen((event) {
      debugPrint('Audio loaded successfully: assets/$assetPath');
    });
    
    // Load the audio file
    audio.load();
    
    _audioCache[assetPath] = audio;
    return audio;
  }

  @override
  void playSound(String assetPath) {
    try {
      // Get or create audio element
      final audio = _getOrCreateAudio(assetPath);
      
      // Stop and reset
      audio.pause();
      audio.currentTime = 0;
      audio.volume = 1.0;
      
      debugPrint('🔊 Web: Attempting to play: assets/$assetPath');
      
      // Play synchronously (critical for Safari)
      final playPromise = audio.play();
      if (playPromise != null) {
        playPromise.then((_) {
          debugPrint('✅ Web: Playing audio');
        }).catchError((e) {
          debugPrint('❌ Web audio error: $e');
        });
      }
      
      _currentSound = audio;
    } catch (e) {
      debugPrint('❌ Web exception: $e');
    }
  }

  @override
  void playWinSound(String assetPath) {
    try {
      final audio = _getOrCreateAudio(assetPath);
      audio.pause();
      audio.currentTime = 0;
      audio.volume = 1.0;
      
      debugPrint('🎉 Web: Playing win sound');
      audio.play()?.catchError((e) {
        debugPrint('❌ Win audio error: $e');
      });
    } catch (e) {
      debugPrint('❌ Win exception: $e');
    }
  }

  @override
  void dispose() {
    _currentSound?.pause();
    for (final audio in _audioCache.values) {
      audio.pause();
      audio.src = '';
    }
    _audioCache.clear();
  }
}
