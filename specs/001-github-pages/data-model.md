# Data Model: GitHub Pages Deployment

**Feature**: GitHub Pages Deployment  
**Date**: 2026-01-07

## Overview

This feature is primarily **infrastructure** focused (CI/CD pipeline, web platform configuration). There are no new domain entities or persistent data structures. The existing game state model in `main.dart` remains unchanged.

## Existing Game State (No Changes Required)

The current `_PuzzleGameState` class maintains game state:

```dart
class _PuzzleGameState {
  List<int> tiles;           // Current puzzle configuration (16 integers)
  int emptyIndex;            // Position of empty space (0-15)
  int moves;                 // Move counter
  bool _isShuffling;         // Shuffle animation flag
  AudioPlayer _player;       // Sound effect player
  AudioPlayer _winPlayer;    // Win sound player
  ConfettiController _confettiController;  // Celebration animation
}
```

**No modifications needed**: Web platform uses the same state model as native platforms.

## Configuration Data

### GitHub Actions Workflow Configuration

**Purpose**: Define CI/CD pipeline for automated deployment

**File**: `.github/workflows/deploy.yml`

**Structure** (YAML):
```yaml
name: string                  # Workflow name
on:                           # Trigger events
  push:
    branches: [string]        # Branch list (only 'main')
jobs:
  deploy:
    runs-on: string           # Runner OS (ubuntu-latest)
    steps:
      - name: string          # Step name
        uses: string          # Action reference (org/repo@version)
        with:                 # Action inputs (key-value pairs)
```

**Key Attributes**:
- `branches`: `['main']` only (per clarifications)
- `flutter-version`: `'3.10.x'` (stable channel)
- `build-args`: `--release --base-href "/15puzzle/"`
- `retry-attempts`: `3` (per clarifications)

### Web Platform Configuration

**Purpose**: Configure Flutter web build for GitHub Pages

**File**: `web/index.html` (modifications)

**New Elements**:
- Loading spinner (inline HTML + CSS)
- Noscript fallback message
- Browser detection script
- Base href (set by build command, not manually)

**No database, API contracts, or state persistence required** for this feature.

## Responsive Layout Parameters

**Purpose**: Calculate optimal board size based on viewport

**Not a persisted entity**, but a runtime calculation:

```dart
class ResponsiveConfig {
  final double viewportWidth;      // MediaQuery.size.width
  final double viewportHeight;     // MediaQuery.size.height
  final DeviceType deviceType;     // desktop | tablet | mobile
  final double boardSize;          // Calculated optimal size
  
  DeviceType _classify() {
    if (viewportWidth >= 1024) return DeviceType.desktop;
    if (viewportWidth >= 768) return DeviceType.tablet;
    return DeviceType.mobile;
  }
  
  double _calculate() {
    final available = min(viewportWidth, viewportHeight) * 0.85;
    switch (deviceType) {
      case DeviceType.desktop: return min(520, available);
      case DeviceType.tablet: return min(480, available);
      case DeviceType.mobile: return min(available, 340);
    }
  }
}
```

**Breakpoints** (from spec):
- Desktop: ≥1024px
- Tablet: 768-1023px
- Mobile: <768px

**Constraints**:
- Minimum tile size: 44×44px (per FR-006)
- Maximum board size: 520px (current desktop size)
- Minimum board size: 340px (for mobile, yields 85×85px tiles)

## Testing Artifacts

**Purpose**: Validate web platform compatibility

**File**: `test/web_compatibility_test.dart`

**Test Cases** (not data entities, but test scenarios):
- Tile tap with mouse events
- Responsive layout at multiple viewport sizes
- Loading screen removal after Flutter init
- Audio playback permissions
- Confetti animation performance

## Summary

**Data Model Complexity**: Minimal  
**New Entities**: 0 (configuration only)  
**Modified Entities**: 0 (existing game state unchanged)  
**State Persistence**: None (game state resets on page refresh, acceptable per assumptions)

This feature is **purely additive**:
- Adds CI/CD infrastructure (GitHub Actions workflow)
- Adds responsive layout logic (runtime calculations)
- Adds loading UX (HTML/CSS modifications)
- Tests validate existing game code works on web platform

No database schema, API contracts, or data migrations required.
