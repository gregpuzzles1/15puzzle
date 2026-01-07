# API Contracts

**Feature**: GitHub Pages Deployment  
**Date**: 2026-01-07

## Overview

This feature deploys a **static web application** to GitHub Pages. There are no REST APIs, GraphQL endpoints, or backend services.

## Static Hosting Contract

### Deployment Target

**Provider**: GitHub Pages  
**Protocol**: HTTPS  
**URL**: `https://gregpuzzles1.github.io/15puzzle/`  
**Content Type**: Static HTML/JavaScript/CSS/Assets

**HTTP Headers** (provided by GitHub Pages):
```
Content-Type: text/html; charset=utf-8
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
```

**Note**: GitHub Pages sets CSP automatically. Flutter web requires `'unsafe-eval'` for Dart VM (development) but production builds don't trigger CSP violations.

## GitHub Actions Workflow Contract

### Inputs (Trigger)

**Event**: `push` to `main` branch

**Payload** (provided by GitHub):
```json
{
  "ref": "refs/heads/main",
  "repository": {
    "name": "15puzzle",
    "owner": {
      "login": "gregpuzzles1"
    },
    "html_url": "https://github.com/gregpuzzles1/15puzzle"
  },
  "pusher": {
    "name": "string",
    "email": "string"
  },
  "commits": [
    {
      "id": "string",
      "message": "string",
      "timestamp": "ISO8601",
      "url": "string"
    }
  ]
}
```

### Outputs (Deployment)

**Success** (HTTP 201):
```json
{
  "status": "success",
  "deployment_url": "https://gregpuzzles1.github.io/15puzzle/",
  "commit_sha": "string",
  "deployed_at": "ISO8601"
}
```

**Failure** (HTTP 4xx/5xx):
```json
{
  "status": "failure",
  "error_message": "string",
  "retry_count": 0-3,
  "failed_at": "ISO8601"
}
```

**Retry Behavior**:
- Automatic retry up to 3 times (per clarifications)
- Exponential backoff not required (deployment is fast)
- Final failure surfaces in GitHub Actions UI

## Browser Requirements Contract

### Supported Browsers

The deployed application requires:

**Desktop**:
- Chrome: Last 2 versions (≥v110)
- Firefox: Last 2 versions (≥v110)
- Safari: Last 2 versions (≥v16)
- Edge: Last 2 versions (≥v110)

**Mobile**:
- Chrome Android: Last 2 versions
- Safari iOS: Last 2 versions (≥iOS 15)
- Samsung Internet: Last 2 versions

### Required Browser Features

```javascript
// Contract: Browser MUST support these features
const requiredFeatures = {
  fetch: typeof window.fetch === 'function',
  Promise: typeof window.Promise === 'function',
  Symbol: typeof window.Symbol === 'function',
  ES2017: true  // async/await, object spread, etc.
};

// If any feature missing, show unsupported message
```

### User Agent Detection (Fallback)

```
User-Agent: <browser>/<version> <engine>/<version> <platform>
```

Unsupported browsers (show error):
- Internet Explorer (all versions)
- Edge Legacy (pre-Chromium, <v79)
- Chrome <v70
- Firefox <v65
- Safari <v13

## Asset Loading Contract

### Base Path

All assets MUST be loaded relative to `/15puzzle/`:

```
https://gregpuzzles1.github.io/15puzzle/
├── index.html                    # Entry point
├── flutter.js                    # Flutter web engine loader
├── main.dart.js                  # Compiled Dart code
├── flutter_service_worker.js     # Service worker (optional)
├── manifest.json                 # Web app manifest
├── assets/
│   ├── AssetManifest.json       # Asset registry
│   ├── FontManifest.json        # Font registry
│   └── sounds/
│       ├── tile_tick.wav        # Tile movement sound
│       ├── new_game_chime.wav   # New game sound
│       └── game_win_fanfare.wav # Win sound
└── icons/
    └── Icon-192.png              # Web app icon
```

**Critical**: Build command MUST include `--base-href "/15puzzle/"` or assets will 404.

### Asset MIME Types

GitHub Pages serves correct MIME types automatically:

```
.html -> text/html
.js   -> application/javascript
.json -> application/json
.wav  -> audio/wav
.png  -> image/png
```

No custom MIME type configuration required.

## Loading Screen Contract

### Initial State (index.html)

```html
<!-- Present in DOM before Flutter loads -->
<div id="loading" style="...">
  <div class="spinner"></div>
</div>
```

**Guarantees**:
- Visible within 500ms of navigation (typically <100ms)
- No Flash of Unstyled Content (FOUC)
- Works without JavaScript (CSS only)

### Removal Contract (Flutter)

```dart
// Called after Flutter initialization
SchedulerBinding.instance.addPostFrameCallback((_) {
  html.document.querySelector('#loading')?.remove();
});
```

**Transition**: Instant (no animation, minimal spinner design per clarifications)

## Responsive Layout Contract

### Viewport Breakpoints

The application adapts based on viewport width:

```javascript
// Contract: Game layout MUST adjust at these breakpoints
const breakpoints = {
  mobile:  { min: 0,    max: 767  },  // <768px
  tablet:  { min: 768,  max: 1023 },  // 768-1023px
  desktop: { min: 1024, max: Infinity }  // ≥1024px
};
```

### Board Size Contract

```javascript
// Contract: Board size MUST ensure tiles ≥44×44px
function calculateBoardSize(viewportWidth, viewportHeight) {
  const available = Math.min(viewportWidth, viewportHeight) * 0.85;
  
  if (viewportWidth >= 1024) return Math.min(520, available);  // Desktop
  if (viewportWidth >= 768)  return Math.min(480, available);  // Tablet
  return Math.min(available, 340);                             // Mobile (85×85px tiles)
}

// Tile size = boardSize / 4
// Minimum: 340 / 4 = 85px ✅ (exceeds 44px requirement)
```

### Orientation Change

```javascript
// Contract: Layout MUST update on orientation change
window.addEventListener('resize', () => {
  // Flutter MediaQuery automatically updates
  // Build method re-calculates board size
});
```

No page refresh required (violated FR-005 acceptance scenario 4).

## Performance Contract

### Load Time Targets

```javascript
// Contract: Performance metrics MUST meet spec requirements
const performanceTargets = {
  firstPaint: 1000,       // <1s on 3G (NFR-001)
  interactive: 5000,      // <5s on 3G (NFR-002)
  frameRate: 60,          // 60fps gameplay (NFR-006)
  touchResponse: 16       // <16ms (Constitution II)
};
```

**Measurement**: Use Chrome DevTools Lighthouse, Network tab (Slow 3G throttling)

### Resource Sizes (Estimated)

```
main.dart.js:    ~2-3 MB (gzipped ~500KB)
flutter.js:      ~200 KB
Total assets:    ~300 KB (sounds + icons)
Initial load:    ~1 MB (gzipped + cached)
```

GitHub Pages uses Cloudflare CDN (automatic gzip, caching).

## Testing Contract

### Automated Tests

**File**: `test/web_compatibility_test.dart`

**Assertions**:
```dart
testWidgets('Tile tap works on web', (tester) async {
  // MUST: Tap registers with mouse events
  // MUST: Tile moves correctly
  // MUST: Move counter increments
});

testWidgets('Responsive layout works', (tester) async {
  // MUST: Board fits at 375×667 (iPhone SE)
  // MUST: Board fits at 768×1024 (iPad)
  // MUST: Board fits at 1920×1080 (Desktop)
  // MUST: No overflow warnings
});
```

### Manual Test Cases

**Desktop** (Chrome, Firefox, Safari/Edge):
- ✅ Game playable from shuffle to win
- ✅ Audio works (may prompt for permission)
- ✅ Confetti animation smooth (60fps)
- ✅ Resize window updates layout

**Mobile** (iPhone SE, Pixel):
- ✅ Touch targets ≥44px
- ✅ Portrait + landscape modes
- ✅ Interactive within 5s on Slow 3G

**Edge Cases**:
- ✅ JavaScript disabled: Shows "This game requires JavaScript" message
- ✅ Old browser: Shows "Unsupported browser" message
- ✅ Network error: Loading screen shows retry option

## Summary

This feature has **no traditional API contracts** (REST/GraphQL) because it's a static web deployment.

**Contracts Defined**:
1. ✅ GitHub Pages hosting requirements
2. ✅ GitHub Actions workflow inputs/outputs
3. ✅ Browser compatibility requirements
4. ✅ Asset loading paths (base href)
5. ✅ Loading screen lifecycle
6. ✅ Responsive layout breakpoints
7. ✅ Performance targets
8. ✅ Test assertion contracts

All contracts are **infrastructure and configuration-focused**, not API-focused.
