/// Native (iOS, Android, Desktop) audio implementation using audioplayers
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'audio_manager.dart';

AudioManager _createWebAudioManager() => throw UnsupportedError(
    'Web audio manager not available on native platforms');
AudioManager _createNativeAudioManager() => NativeAudioManager();

class NativeAudioManager implements AudioManager {
  late final AudioPlayer _player;
  late final AudioPlayer _winPlayer;
  bool _isPlayingSound = false;

  @override
  Future<void> initialize() async {
    _player = AudioPlayer();
    _player.setPlayerMode(PlayerMode.lowLatency);
    _player.setReleaseMode(ReleaseMode.stop);
    _player.setVolume(1.0);

    _winPlayer = AudioPlayer();
    _winPlayer.setReleaseMode(ReleaseMode.stop);
    _winPlayer.setVolume(1.0);
    
    debugPrint('Native audio initialized successfully');
  }

  @override
  void playSound(String assetPath) {
    if (_isPlayingSound) return;
    
    _isPlayingSound = true;
    _player.stop().then((_) {
      return _player.play(AssetSource(assetPath));
    }).then((_) {
      Future.delayed(const Duration(milliseconds: 50), () {
        _isPlayingSound = false;
      });
    }).catchError((e) {
      _isPlayingSound = false;
      debugPrint('Audio error: $e');
    });
  }

  @override
  void playWinSound(String assetPath) {
    _winPlayer.stop().then((_) {
      return _winPlayer.play(AssetSource(assetPath));
    }).catchError((e) {
      debugPrint('Win audio error: $e');
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _winPlayer.dispose();
  }
}
