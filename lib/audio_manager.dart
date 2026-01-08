/// Abstract audio manager interface
import 'audio_manager_stub.dart'
    if (dart.library.html) 'audio_manager_web.dart'
    if (dart.library.io) 'audio_manager_native.dart';

abstract class AudioManager {
  Future<void> initialize();
  void playSound(String assetPath);
  void playWinSound(String assetPath);
  void dispose();
  
  factory AudioManager() => createAudioManager();
}
