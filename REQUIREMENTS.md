# 15 Puzzle - Requirements

## Functional Requirements (As Implemented)

Status is indicated as **(Done)** / **(Partial)** / **(Not implemented)**.

### Gameplay

- **FR-001**: The system MUST present a 4×4 sliding puzzle with 15 numbered tiles and 1 empty space **(Done)**
- **FR-002**: The system MUST allow moving only tiles adjacent (up/down/left/right) to the empty space **(Done)**
- **FR-003**: The system MUST ignore taps on non-movable tiles **(Done)**
- **FR-004**: The system MUST provide a “New Game” control that starts a fresh shuffled puzzle **(Done)**
- **FR-005**: The system MUST shuffle using valid moves so the puzzle remains solvable **(Done)**
- **FR-006**: The system MUST track and display a move counter that increments on each valid player move **(Done)**
- **FR-007**: The system MUST detect a win condition and present a win dialog **(Done)**
- **FR-008**: The system MUST allow starting a new game from the win dialog (“Play Again”) **(Done)**
- **FR-009**: The system MUST support multiple acceptable solved layouts (variant win conditions) **(Done)**

### Time & Pause

- **FR-010**: The system MUST show an elapsed time display for the current game **(Done)**
- **FR-011**: The timer MUST reset on New Game and begin on the player’s first move (not during shuffle) **(Done)**
- **FR-012**: The system MUST provide a pause/resume control for the timer **(Done)**
- **FR-013**: When paused, the puzzle board MUST be non-interactive and show a “Paused” overlay **(Done)**
- **FR-014**: On win, the timer MUST stop and the final elapsed time MUST be shown in the win dialog **(Done)**

### UI / Layout / Accessibility

- **FR-015**: The layout MUST be responsive across desktop (≥1024px), tablet (768–1023px), and mobile (<768px) viewports **(Done)**
- **FR-016**: On mobile-sized layouts, tile touch targets MUST be at least 44×44 logical pixels **(Done)**
- **FR-017**: The tile text MUST scale to fit within the tile bounds (no clipping) **(Done)**

### Theme

- **FR-018**: The system MUST provide a dark mode setting toggle in the UI **(Done)**
- **FR-019**: The system MUST apply the selected theme (light/dark) across the app **(Done)**

### Audio

- **FR-020**: The system MUST play a best-effort “New Game” sound when starting a new game **(Done)**
- **FR-021**: The system MUST play a best-effort “Win” sound when the puzzle is solved **(Done)**
- **FR-022**: Tile-move/tick sound MUST be disabled across platforms to avoid cross-browser autoplay/latency issues **(Done; intentionally disabled)**

### Win Celebration

- **FR-023**: On win, the system MUST show a confetti animation/celebration effect **(Done)**

### Web Compatibility / GitHub Pages UX

- **FR-024**: The web build MUST support deployment under the base path `/15puzzle/` **(Done)**
- **FR-025**: The site MUST display a minimal loading spinner during Flutter initialization **(Done)**
- **FR-026**: The loading spinner MUST be removed once the Flutter UI is interactive (after first frame) **(Done)**
- **FR-027**: The site MUST display a message when JavaScript is disabled **(Done; via `<noscript>`)**
- **FR-028**: The site MUST detect and notify users on unsupported/very old browsers (feature detection) **(Done)**
- **FR-029**: If Flutter fails to initialize due to network/runtime errors, the site SHOULD show a friendly retryable error state **(Not implemented)**

### Links / Footer

- **FR-030**: The UI MUST provide external links to License and GitHub repo **(Done)**
- **FR-031**: On web, external links MUST open in a new tab/window **(Done)**
- **FR-032**: On non-web platforms, external links MUST fall back gracefully (e.g., copy link to clipboard) **(Done)**

### Keyboard Support (Quality of Life)

- **FR-033**: On desktop/web, the page SHOULD support keyboard scrolling via arrow keys and Page Up/Down **(Done)**

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
