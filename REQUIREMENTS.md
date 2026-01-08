# 15 Puzzle - Requirements

## Flutter SDK
- **Minimum Flutter SDK**: 3.10.0
- **Dart SDK**: ^3.10.0

## Dependencies

### Production Dependencies
- **flutter**: SDK
- **audioplayers**: ^6.0.0 - Audio playback for sound effects
- **confetti**: ^0.7.0 - Confetti animation for win celebration
- **cupertino_icons**: ^1.0.8 - iOS style icons

### Development Dependencies
- **flutter_test**: SDK - Testing framework
- **flutter_lints**: ^6.0.0 - Recommended lints for Flutter

## Platform Support
This project supports:
- ✅ Windows
- ✅ Android
- ✅ iOS
- ✅ Web (Chrome, Edge)
- ✅ macOS
- ✅ Linux

## Assets
- Sound files in `assets/sounds/`:
   - `tile_tick.wav` - Tile movement sound (present; currently not played)
   - `tile_slide_tick.mp3` - Alternate tile movement sound (present; currently not played)
  - `new_game_chime.wav` - New game start sound
  - `game_win_fanfare.wav` - Win celebration sound

## System Requirements

### For Development
- Flutter SDK installed and configured
- Git for version control
- Platform-specific toolchains:
  - **Windows**: Visual Studio 2022 or Visual Studio Build Tools
  - **Android**: Android Studio and Android SDK
  - **iOS/macOS**: Xcode (macOS only)
  - **Linux**: Required Linux development packages

### For Running
- Supported operating system (Windows 10+, macOS 10.14+, Linux, Android 5.0+, iOS 12+)
- Audio output capability

## Installation

1. Ensure Flutter SDK is installed:
   ```bash
   flutter --version
   ```

2. Clone the repository:
   ```bash
   git clone https://github.com/gregpuzzles1/15puzzle.git
   cd 15puzzle
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the application:
   ```bash
   flutter run
   ```

## Build Requirements

### Debug Build
No additional requirements beyond Flutter SDK.

### Release Build
Platform-specific signing certificates and keys may be required:
- **Android**: Keystore for APK signing
- **iOS**: Apple Developer certificate and provisioning profile
- **Windows**: Code signing certificate (optional)

## Notes
- Audio features require device audio output capability
- Web audio is subject to browser autoplay/user-gesture policies; some browsers may block sound unless initiated directly from a user action.
- To avoid cross-browser latency and policy issues, tile-move/tick sound is currently disabled on all platforms; New Game and Win sounds remain best-effort.
- Confetti animation uses Flutter's rendering engine (no additional GPU requirements)
