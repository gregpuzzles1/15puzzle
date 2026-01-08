# Research: GitHub Pages Deployment

**Feature**: GitHub Pages Deployment  
**Date**: 2026-01-07  
**Status**: Complete

## Research Questions

This phase resolves all technical unknowns from the Technical Context section and investigates best practices for Flutter web deployment, responsive design, and testing strategies.

---

## 1. Flutter Web Build & GitHub Actions Integration

### Decision: Use flutter/gh-pages-action with Flutter 3.10+

**Rationale**:
- Official Flutter web support is stable since Flutter 2.0 (we're on 3.10+)
- `flutter build web --release` generates optimized static files in `build/web/`
- GitHub Actions has official Flutter action: `subosito/flutter-action`
- For GitHub Pages deployment: `peaceiris/actions-gh-pages` is the most popular action (16k+ stars)
- Base href configuration is critical: `flutter build web --base-href "/15puzzle/"`

**Alternatives Considered**:
1. **Manual deployment** (rejected): Requires manual `flutter build web` + `git push` to gh-pages branch. Violates automation requirement (FR-004).
2. **Netlify/Vercel** (rejected): User specified GitHub Pages explicitly. These platforms would require external accounts and different workflows.
3. **Custom shell scripts** (rejected): peaceiris/actions-gh-pages is battle-tested, handles edge cases (force push, CNAME, etc.), and is widely adopted.

**Implementation Notes**:
- Workflow triggers on push to `main` branch only (per clarifications)
- Uses Flutter stable channel (matches current project)
- Build command: `flutter build web --release --base-href "/15puzzle/"`
- Deploy to `gh-pages` branch using peaceiris/actions-gh-pages@v3
- Retry strategy: GitHub Actions has built-in retry (uses `uses: nick-invision/retry@v2` wrapper)

---

## 2. Responsive Layout Patterns for Flutter Web

### Decision: LayoutBuilder + MediaQuery with breakpoint-based grid sizing

**Rationale**:
- Flutter's `LayoutBuilder` provides actual available space (handles browser chrome, mobile keyboards)
- `MediaQuery.of(context).size` gives viewport dimensions
- Breakpoints align with spec: ≥1024px (desktop), 768-1023px (tablet), <768px (mobile)
- Current game uses fixed `boardSize = 520px` which won't fit on mobile (e.g., iPhone SE = 375px width)

**Pattern**:
```dart
double getOptimalBoardSize(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  final height = MediaQuery.of(context).size.height;
  final available = min(width, height) * 0.85; // 85% of viewport
  
  if (width >= 1024) return min(520, available); // Desktop: keep current or smaller
  if (width >= 768) return min(480, available);  // Tablet: slightly smaller
  return min(available, 340);                     // Mobile: constrained by screen
}
```

**Alternatives Considered**:
1. **Fixed sizes with scrolling** (rejected): Spec requires "no horizontal scrolling" (SC-003). Poor UX on mobile.
2. **Separate layouts per platform** (rejected): Violates Cross-Platform Consistency principle. Adds complexity.
3. **AspectRatio widget only** (rejected): Doesn't account for header/controls height. Could clip game on short viewports.

**Touch Target Compliance**:
- Tiles scale with board size
- Minimum tile size = (boardSize / 4) ≥ 44px
- For 340px mobile board: 340/4 = 85px tiles ✅ (exceeds 44px requirement)

---

## 3. Loading Screen Implementation

### Decision: Modify web/index.html with CSS-animated spinner, hide via Flutter

**Rationale**:
- Flutter web bootstrap has a delay while loading the engine (~2-5 seconds on 3G)
- index.html is the first file loaded—can show spinner immediately
- CSS animations work without JavaScript (handles slow script loading gracefully)
- Flutter app removes spinner when ready using `document.querySelector('#loading')?.remove()`

**Implementation**:
```html
<!-- Add to web/index.html in <body>, before flutter.js script -->
<div id="loading" style="position: fixed; inset: 0; display: flex; 
     align-items: center; justify-content: center; background: #fff;">
  <div class="spinner"></div>
</div>
<style>
.spinner {
  width: 50px; height: 50px; border: 4px solid #e0e0e0;
  border-top-color: #2196F3; border-radius: 50%;
  animation: spin 1s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
</style>
```

Then in `main.dart` `initState()`:
```dart
// Remove loading screen once Flutter is ready
SchedulerBinding.instance.addPostFrameCallback((_) {
  html.document.querySelector('#loading')?.remove();
});
```

**Alternatives Considered**:
1. **Flutter CircularProgressIndicator** (rejected): Only appears after Flutter engine loads, defeating purpose.
2. **Progress bar with percentage** (rejected): Can't accurately measure Flutter engine load time. User chose minimal spinner (clarification).
3. **Skeleton UI** (rejected): Over-engineered for a simple game. Minimal spinner preferred.

**Performance Target Validation**:
- CSS spinner appears <100ms (typically <50ms, well under 500ms requirement FR-008)
- Transition is instant (CSS `display: none` when removed)
- No flash of unstyled content (FOUC) since spinner is styled inline

---

## 4. Web Platform Testing Strategy

### Decision: Multi-tiered testing with automated widget tests + manual browser testing

**User Requirement**: "would like to do tests to bring out any issues with existing code"

**Rationale**:
- Existing game has ~400 LOC with audio, confetti, touch handling—web may expose issues
- Flutter's `flutter_test` supports web platform (can run widget tests with `flutter test`)
- Manual testing essential for audio autoplay, touch vs mouse events, canvas rendering
- Constitution requires testing on ≥2 platforms; web testing qualifies

**Testing Tiers**:

**Tier 1: Automated Widget Tests** (NEW - add to test/)
```dart
// test/web_compatibility_test.dart
testWidgets('Tile tap works on web with mouse events', (tester) async {
  await tester.pumpWidget(MyApp());
  // Simulate mouse click on tile (web uses mouse, not touch)
  await tester.tap(find.byKey(Key('tile_1')));
  await tester.pump();
  // Verify tile moved
});

testWidgets('Responsive layout adapts to mobile viewport', (tester) async {
  tester.binding.window.physicalSizeTestValue = Size(375, 667); // iPhone SE
  await tester.pumpWidget(MyApp());
  // Verify board fits without overflow
});
```

**Tier 2: Manual Browser Testing** (checklist-based)
- **Desktop** (≥1024px): Chrome, Firefox, Safari/Edge
  - Full game playthrough (shuffle → win)
  - Audio playback (may prompt user for permission)
  - Confetti animation performance
  - Responsive resize (drag window smaller/larger)
- **Tablet** (768-1023px): Chrome DevTools emulation (iPad)
  - Touch targets ≥44px
  - Portrait + landscape modes
- **Mobile** (<768px): Chrome DevTools emulation (iPhone SE, Pixel)
  - Touch targets ≥44px
  - Portrait + landscape modes
  - Slow 3G throttling (verify <5s interactive)

**Tier 3: Edge Case Validation**
- JavaScript disabled: noscript message appears ✅
- Old browser (IE11): unsupported browser message (or graceful fail)
- Network interruption during load: retry logic + error handling
- Page refresh mid-game: game resets (acceptable per assumptions)

**Alternatives Considered**:
1. **E2E tests with Selenium** (rejected): Overkill for single-page game. Setup complexity violates maintainability principle.
2. **Integration tests only** (rejected): Won't catch web-specific issues (audio autoplay, touch vs mouse).
3. **No automated tests** (rejected): User explicitly wants tests. Constitution mandates testing.

**Known Web Platform Differences to Test**:
- **Audio**: Browsers block autoplay until user interaction. May require tap-to-enable on first visit.
- **Touch Events**: Web uses mouse events; touch simulation may behave differently than native mobile.
- **Canvas Rendering**: Flutter web uses HTML renderer (default) or CanvasKit. Confetti performance may vary.
- **Keyboard**: Desktop users may expect arrow keys (not in current game, acceptable degradation).

---

## 8. Audio on Web/iOS: Findings & Decision

### What we learned

- **Autoplay policies are strict on desktop browsers**: Chrome/Edge/Chromium can block sound unless playback begins directly inside a user gesture callback (and can be sensitive to timing).
- **Safari/iOS latency can be noticeable**: rapid, repeated “tick” SFX can feel delayed on iOS/Safari.
- **Hosting/MIME quirks can matter**: static hosting (including GitHub Pages) may serve media with non-ideal content-types in some cases; browsers vary in how tolerant they are.

### Decision

- **Tile-move/tick audio is disabled on all platforms** to avoid inconsistent behavior across browsers/devices.
- **New Game and Win sounds are best-effort**, and must not block gameplay; failures degrade silently.

---

## 5. GitHub Actions Retry Strategy

### Decision: Use nick-invision/retry@v2 to wrap deployment step (3 attempts)

**Rationale**:
- User chose automatic retry (up to 3 times) in clarifications
- Deployment can fail due to transient issues (GitHub API rate limits, network timeouts)
- `nick-invision/retry@v2` is popular GitHub Action retry wrapper (1k+ stars)
- Wraps only the deployment step, not the build (build failures should fail fast)

**Implementation**:
```yaml
- name: Deploy to GitHub Pages
  uses: nick-invision/retry@v2
  with:
    timeout_minutes: 5
    max_attempts: 3
    command: |
      # Run peaceiris/actions-gh-pages here
```

**Alternatives Considered**:
1. **GitHub Actions native retry** (rejected): Not supported natively; requires custom retry logic or third-party action.
2. **Retry on all steps** (rejected): Build failures should fail immediately. Only deployment needs retry.
3. **Exponential backoff** (rejected): Deployment is fast (<1 min). Simple retry sufficient.

---

## 6. Browser Compatibility & Fallbacks

### Decision: Support modern browsers (last 2 years), show unsupported message for old browsers

**Rationale**:
- Assumptions section states "Users have modern browsers (Chrome, Firefox, Safari, Edge from last 2 years)"
- IE11 reached end-of-life June 2022 (no longer supported by Microsoft)
- Flutter web requires modern JavaScript features (ES2017+)
- Showing "unsupported browser" message is better UX than broken game

**Implementation** (add to web/index.html):
```html
<noscript>
  <p>This game requires JavaScript to run. Please enable JavaScript in your browser.</p>
</noscript>

<script>
// Detect old browsers (IE11, old Edge)
var isOldBrowser = !window.fetch || !window.Promise || !window.Symbol;
if (isOldBrowser) {
  document.body.innerHTML = '<div style="text-align:center; padding:50px;">' +
    '<h2>Unsupported Browser</h2>' +
    '<p>Please use a modern browser (Chrome, Firefox, Safari, Edge).</p>' +
    '</div>';
}
</script>
```

**Alternatives Considered**:
1. **Polyfills for IE11** (rejected): Adds bundle size, maintenance burden. IE11 is obsolete.
2. **No browser detection** (rejected): Users see broken game with no explanation (poor UX).
3. **Transpile to ES5** (rejected): Flutter web doesn't support ES5 output. Would require Babel + webpack, massive complexity.

---

## 7. Base Path Configuration for Subdirectory Deployment

### Decision: Use --base-href "/15puzzle/" in build command

**Rationale**:
- GitHub Pages for project repos deploys to `username.github.io/repo-name/`
- User specified URL: https://gregpuzzles1.github.io/15puzzle/
- Without base href, assets load from root and fail (404 on /assets/*, /main.dart.js)
- Flutter web's `--base-href` flag updates all asset paths in generated HTML

**Critical**:
- Build command MUST include: `flutter build web --release --base-href "/15puzzle/"`
- Leading and trailing slashes required: `/15puzzle/` (not `15puzzle` or `/15puzzle`)
- Affects: index.html `<base href>` tag, asset paths, routing

**Alternatives Considered**:
1. **Custom domain** (rejected): User explicitly wants GitHub Pages default domain. Custom domain is out of scope.
2. **Deploy to root** (rejected): Would require repo named `gregpuzzles1.github.io` (user repo). Current repo is project repo.
3. **Manual path rewriting** (rejected): Error-prone, hard to maintain. `--base-href` is built-in and reliable.

---

## 8. Deployment Notifications & Monitoring

### Decision: GitHub Actions tab only (no external services)

**Rationale**:
- User chose "GitHub default (Actions tab only)" in clarifications
- Simple project doesn't need email/Slack/Discord notifications
- GitHub Actions UI shows status, logs, and failures clearly
- Commit status checks appear on PR/commit pages automatically

**Out of Scope** (per clarifications):
- Email notifications
- Slack/Discord webhooks
- External monitoring services (Sentry, Datadog, etc.)

---

## Summary of Decisions

| Area | Decision | Key Rationale |
|------|----------|---------------|
| **CI/CD** | GitHub Actions + peaceiris/actions-gh-pages | Most popular, battle-tested, simple config |
| **Responsive Layout** | LayoutBuilder + MediaQuery breakpoints | Works across all devices, no scrolling required |
| **Loading Screen** | CSS spinner in index.html + Flutter removal | Appears immediately (<100ms), minimal design |
| **Testing** | Widget tests + manual browser testing | Catches web-specific issues, constitution-compliant |
| **Retry Policy** | nick-invision/retry@v2 (3 attempts) | Handles transient failures, user preference |
| **Browser Support** | Modern browsers (last 2 years) | Matches assumptions, shows fallback message |
| **Base Path** | --base-href "/15puzzle/" | Required for subdirectory deployment |
| **Notifications** | GitHub Actions tab only | User preference, simple approach |

**No NEEDS CLARIFICATION markers remain.** All technical unknowns resolved. Ready for Phase 1 (design artifacts).
