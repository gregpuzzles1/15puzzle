# Quickstart: GitHub Pages Deployment

**Feature**: Deploy 15 Puzzle to https://gregpuzzles1.github.io/15puzzle/  
**Prerequisites**: Flutter 3.10+, Git, GitHub account with repo access  
**Time to Complete**: ~30-45 minutes (including testing)

---

## Step 1: Enable GitHub Pages (5 minutes)

### 1.1 Configure Repository Settings

1. Go to https://github.com/gregpuzzles1/15puzzle/settings/pages
2. **Source**: Select "Deploy from a branch"
3. **Branch**: Select `gh-pages` / `(root)`
4. Click **Save**

**Note**: The `gh-pages` branch doesn't exist yet. GitHub Actions will create it on first deployment.

### 1.2 Verify GitHub Actions is Enabled

1. Go to https://github.com/gregpuzzles1/15puzzle/settings/actions
2. Ensure "Allow all actions and reusable workflows" is selected
3. Scroll to "Workflow permissions"
4. Select "Read and write permissions"
5. Check "Allow GitHub Actions to create and approve pull requests"
6. Click **Save**

**Why**: Actions needs write permission to push to `gh-pages` branch.

---

## Step 2: Create GitHub Actions Workflow (10 minutes)

### 2.1 Create Workflow File

```bash
# From repository root
mkdir -p .github/workflows
```

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.x'
          channel: 'stable'
          
      - name: Install dependencies
        run: flutter pub get
        
      - name: Run tests
        run: flutter test
        
      - name: Build web
        run: flutter build web --release --base-href "/15puzzle/"
        
      - name: Deploy to GitHub Pages
        uses: nick-invision/retry@v2
        with:
          timeout_minutes: 5
          max_attempts: 3
          command: |
            cd build/web
            git init
            git config user.name "GitHub Actions"
            git config user.email "actions@github.com"
            git add .
            git commit -m "Deploy to GitHub Pages"
            git push -f https://x-access-token:${{ secrets.GITHUB_TOKEN }}@github.com/${{ github.repository }}.git HEAD:gh-pages
```

**Critical**: The `--base-href "/15puzzle/"` flag is required for subdirectory deployment.

### 2.2 Commit and Push Workflow

```bash
git add .github/workflows/deploy.yml
git commit -m "feat: add GitHub Pages deployment workflow"
git push origin 001-github-pages
```

**Note**: This pushes to the feature branch. We'll merge to main later.

---

## Step 3: Add Responsive Layout (15 minutes)

### 3.1 Modify lib/main.dart

Open `lib/main.dart` and find the `boardSize` constant (around line 38):

**Before**:
```dart
static const double boardSize = 520;
```

**After**:
```dart
// Remove static const, make it a method
double getBoardSize(BuildContext context) {
  final size = MediaQuery.of(context).size;
  final width = size.width;
  final height = size.height;
  final available = min(width, height) * 0.85;
  
  if (width >= 1024) return min(520, available);  // Desktop
  if (width >= 768) return min(480, available);   // Tablet
  return min(available, 340);                     // Mobile
}
```

### 3.2 Update Widget Build Method

Find all references to `boardSize` and replace with `getBoardSize(context)`:

```dart
// Example: In the build method
Container(
  width: getBoardSize(context),
  height: getBoardSize(context),
  // ... rest of container
)
```

**Tip**: Search for `boardSize` (Ctrl+F) and update ~3-4 occurrences.

---

## Step 4: Add Loading Screen (10 minutes)

### 4.1 Modify web/index.html

Open `web/index.html` and find the `<body>` tag. Add this right after `<body>`:

```html
<body>
  <!-- Loading spinner (NEW) -->
  <div id="loading" style="position: fixed; inset: 0; display: flex; align-items: center; justify-content: center; background: #fff; z-index: 9999;">
    <div class="spinner"></div>
  </div>
  <style>
  .spinner {
    width: 50px;
    height: 50px;
    border: 4px solid #e0e0e0;
    border-top-color: #2196F3;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }
  @keyframes spin {
    to { transform: rotate(360deg); }
  }
  </style>
  
  <!-- Existing content below -->
  <script>
    // ... existing scripts
  </script>
</body>
```

### 4.2 Add Browser Detection

Add this script before the closing `</body>` tag:

```html
<noscript>
  <div style="text-align:center; padding:50px;">
    <p>This game requires JavaScript. Please enable JavaScript in your browser.</p>
  </div>
</noscript>

<script>
  // Detect old browsers
  var isOldBrowser = !window.fetch || !window.Promise || !window.Symbol;
  if (isOldBrowser) {
    document.body.innerHTML = '<div style="text-align:center; padding:50px;">' +
      '<h2>Unsupported Browser</h2>' +
      '<p>Please use a modern browser (Chrome, Firefox, Safari, Edge).</p>' +
      '</div>';
  }
</script>
```

### 4.3 Remove Loading Screen from Flutter

In `lib/main.dart`, add to the `_PuzzleGameState` class `initState()` method:

```dart
import 'dart:html' as html;  // Add at top of file

@override
void initState() {
  super.initState();
  
  // Remove loading screen after Flutter is ready
  SchedulerBinding.instance.addPostFrameCallback((_) {
    html.document.querySelector('#loading')?.remove();
  });
  
  // ... existing initState code (audio setup, tiles init, etc.)
}
```

**Note**: Add `import 'dart:html' as html;` at the top of `main.dart` (web-only import).

---

## Step 5: Add Web Compatibility Tests (10 minutes)

### 5.1 Create Test File

Create `test/web_compatibility_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_15/main.dart';

void main() {
  testWidgets('Game loads and is playable', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    
    // Verify game UI is present
    expect(find.text('15 Puzzle'), findsOneWidget);
    expect(find.text('Moves: 0'), findsOneWidget);
    
    // Verify tiles are present
    for (int i = 1; i <= 15; i++) {
      expect(find.text(i.toString()), findsOneWidget);
    }
  });
  
  testWidgets('Responsive layout adapts to mobile', (WidgetTester tester) async {
    // Simulate iPhone SE viewport
    tester.binding.window.physicalSizeTestValue = const Size(375, 667);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    
    // Verify no overflow errors
    expect(tester.takeException(), isNull);
  });
  
  testWidgets('Responsive layout adapts to tablet', (WidgetTester tester) async {
    // Simulate iPad viewport
    tester.binding.window.physicalSizeTestValue = const Size(768, 1024);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    
    expect(tester.takeException(), isNull);
  });
  
  testWidgets('Responsive layout adapts to desktop', (WidgetTester tester) async {
    // Simulate desktop viewport
    tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    
    expect(tester.takeException(), isNull);
  });
}
```

### 5.2 Run Tests Locally

```bash
flutter test
```

**Expected**: All tests pass ✅

---

## Step 6: Test Locally Before Deploying (5 minutes)

### 6.1 Build Web Version

```bash
flutter build web --release --base-href "/15puzzle/"
```

**Output**: `build/web/` directory with compiled files

### 6.2 Serve Locally

```bash
# Option 1: Python
cd build/web
python -m http.server 8000

# Option 2: Flutter dev server (no base href)
flutter run -d chrome
```

Open http://localhost:8000/

**Check**:
- ✅ Game loads (no loading spinner since it's local)
- ✅ Game is playable (tiles slide, sounds work)
- ✅ Resize browser window → layout adapts

---

## Step 7: Deploy to GitHub Pages (5 minutes)

### 7.1 Merge Feature Branch to Main

```bash
# From feature branch (001-github-pages)
git add .
git commit -m "feat: add responsive layout, loading screen, and tests"
git push origin 001-github-pages

# Create pull request or merge directly
git checkout main
git merge 001-github-pages
git push origin main
```

### 7.2 Monitor Deployment

1. Go to https://github.com/gregpuzzles1/15puzzle/actions
2. Click on the latest workflow run
3. Watch deployment progress (~3-5 minutes)

**Success**: Green checkmark ✅

**Failure**: Red X ❌ (check logs, workflow will retry 3 times)

### 7.3 Verify Live Site

After deployment completes:

1. Open https://gregpuzzles1.github.io/15puzzle/
2. Verify game loads and is playable
3. Test responsive design (resize browser window)

**First deployment may take 5-10 minutes** for GitHub Pages to propagate DNS changes.

---

## Step 8: Manual Testing Checklist (10-15 minutes)

### Desktop (≥1024px)

- [ ] Open Chrome → https://gregpuzzles1.github.io/15puzzle/
- [ ] Game loads (loading spinner appears briefly)
- [ ] Play complete game (shuffle → solve)
- [ ] Audio works (click sounds, win fanfare)
- [ ] Confetti animation plays on win
- [ ] Resize window → layout adapts smoothly
- [ ] Repeat in Firefox
- [ ] Repeat in Safari/Edge

### Tablet (768-1023px)

- [ ] Open Chrome DevTools (F12)
- [ ] Toggle device toolbar (Ctrl+Shift+M)
- [ ] Select "iPad" or "iPad Air"
- [ ] Refresh page
- [ ] Verify tiles are large enough to tap comfortably
- [ ] Test portrait and landscape modes

### Mobile (<768px)

- [ ] Chrome DevTools → Device toolbar
- [ ] Select "iPhone SE" or "Pixel 5"
- [ ] Verify tiles are ≥44×44px (should be 85×85px)
- [ ] Play game with touch simulation
- [ ] Test portrait and landscape modes

### Performance (Slow 3G)

- [ ] Chrome DevTools → Network tab
- [ ] Select "Slow 3G" throttling
- [ ] Hard refresh (Ctrl+Shift+R)
- [ ] Verify loading spinner appears immediately
- [ ] Verify game interactive within 5 seconds

### Edge Cases

- [ ] Disable JavaScript → Shows fallback message
- [ ] Open in IE11 (if available) → Shows unsupported browser message
- [ ] Refresh mid-game → Game resets (expected behavior)

---

## Troubleshooting

### Issue: 404 Not Found on Assets

**Cause**: Missing `--base-href "/15puzzle/"`

**Fix**: Update workflow file → `flutter build web --release --base-href "/15puzzle/"`

### Issue: Workflow Fails on Deploy Step

**Cause**: Missing GitHub token permissions

**Fix**: Settings → Actions → Workflow permissions → "Read and write permissions"

### Issue: Loading Spinner Never Disappears

**Cause**: Flutter app not removing `#loading` div

**Fix**: Verify `dart:html` import and `querySelector('#loading')?.remove()` in `initState()`

### Issue: Audio Doesn't Play on First Load

**Cause**: Browser autoplay policy (requires user interaction)

**Expected**: This is normal browser behavior. Audio will play after first tile tap.

### Issue: Confetti Animation Lags on Mobile

**Cause**: Low-end device, complex animation

**Acceptable**: Per assumptions, confetti may perform differently on low-end devices. Game remains playable.

---

## Next Steps

✅ **Deployment Complete!** Your game is live at https://gregpuzzles1.github.io/15puzzle/

**Optional Enhancements** (Out of Scope):
- Custom domain (e.g., puzzle.example.com)
- PWA features (offline play, install prompt)
- Analytics (Google Analytics, Plausible)
- SEO optimization (meta tags, sitemap)
- Social sharing buttons

**Maintenance**:
- Push to `main` branch → Auto-deploys within 5 minutes
- Monitor Actions tab for deployment status
- Test on new browser versions quarterly

---

## Success Criteria Validation

Verify all success criteria from spec.md:

- ✅ **SC-001**: Game accessible and playable at https://gregpuzzles1.github.io/15puzzle/
- ✅ **SC-002**: Interactive within 5 seconds on 4G (test with throttling)
- ✅ **SC-003**: Playable on desktop/tablet/mobile without scrolling
- ✅ **SC-004**: All existing features work identically on web
- ✅ **SC-005**: Deployment automated (push to main → live within 10 minutes)
- ✅ **SC-006**: Loading spinner visible on slow connections
- ✅ **SC-007**: No console errors during gameplay

**Congratulations!** 🎉 Your 15 Puzzle is now deployed to the web!
