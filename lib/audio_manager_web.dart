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

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Preload and unlock audio on first user interaction
      // Safari requires this to happen synchronously in a user gesture
      final audio = html.AudioElement();
      audio.src = 'data:audio/wav;base64,UklGRigAAABXQVZFZm10IBIAAAABAAEARKwAAIhYAQACABAAAABkYXRhAgAAAAEA';
      audio.volume = 0.0;
      await audio.play();
      audio.pause();
      
      _initialized = true;
      debugPrint('Web audio initialized successfully');
    } catch (e) {
      debugPrint('Web audio initialization: $e');
      _initialized = true; // Continue anyway
    }
  }

  html.AudioElement _getOrCreateAudio(String assetPath) {
    if (_audioCache.containsKey(assetPath)) {
      return _audioCache[assetPath]!;
    }
    
    final audio = html.AudioElement();
    audio.src = 'assets/$assetPath';
    audio.preload = 'auto';
    
    // Load the audio file
    audio.load();
    
    _audioCache[assetPath] = audio;
    return audio;
  }

  @override
  void playSound(String assetPath) {
    // Auto-initialize on first play for Safari/iOS
    if (!_initialized) {
      initialize();
    }
    
    try {
      // Stop current sound if playing
      _currentSound?.pause();
      _currentSound?.currentTime = 0;
      
      // Get or create audio element
      final audio = _getOrCreateAudio(assetPath);
      audio.currentTime = 0;
      audio.volume = 1.0;
      
      // Play synchronously (critical for Safari)
      audio.play()?.catchError((e) {
        debugPrint('Audio play error: $e');
      });
      
      _currentSound = audio;
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  @override
  void playWinSound(String assetPath) {
    // Auto-initialize on first play for Safari/iOS
    if (!_initialized) {
      initialize();
    }
    
    try {
      final audio = _getOrCreateAudio(assetPath);
      audio.currentTime = 0;
      audio.volume = 1.0;
      
      audio.play()?.catchError((e) {
        debugPrint('Win audio play error: $e');
      });
    } catch (e) {
      debugPrint('Win audio error: $e');
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
