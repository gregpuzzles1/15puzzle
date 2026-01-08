/// Abstract audio manager interface
abstract class AudioManager {
  Future<void> initialize();
  void playSound(String assetPath);
  void playWinSound(String assetPath);
  void dispose();
  
  factory AudioManager() {
    if (identical(0, 0.0)) {
      // This is a web platform check
      return _createWebAudioManager();
    }
    return _createNativeAudioManager();
  }
}

AudioManager _createWebAudioManager() => throw UnsupportedError(
    'Cannot create web audio manager on this platform');

AudioManager _createNativeAudioManager() => throw UnsupportedError(
    'Cannot create native audio manager on this platform');
