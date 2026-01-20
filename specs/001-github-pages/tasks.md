---

description: "Task list for GitHub Pages deployment feature"
---

# Tasks: GitHub Pages Deployment

**Input**: Design documents from `/specs/001-github-pages/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: User explicitly requested tests to "bring out any issues with existing code". All test tasks included below are MANDATORY for this feature.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter project**: `lib/`, `test/`, `.github/workflows/` at repository root
- **Web assets**: `web/` directory
- **Build output**: `build/web/` (generated, deployed to gh-pages branch)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and repository configuration

- [ ] T001 Verify Flutter SDK version ≥3.10.0 and Dart ^3.10.0 are installed
- [ ] T002 Verify repository is clean with no uncommitted changes on 001-github-pages branch
- [x] T003 [P] Create `.github/workflows/` directory structure for CI/CD workflows

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core configuration that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 Configure GitHub repository settings: enable GitHub Pages, set source to gh-pages branch
- [ ] T005 Configure GitHub Actions permissions: enable "Read and write permissions" for workflows
- [x] T006 [P] Update pubspec.yaml to include web platform if not already present
- [x] T007 [P] Verify existing dependencies (audioplayers, confetti, cupertino_icons) are web-compatible

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Deploy Game to GitHub Pages (Priority: P1) 🎯 MVP

**Goal**: Automated CI/CD pipeline that deploys game to https://gregpuzzles1.github.io/15puzzle/

**Independent Test**: Push code to main branch → workflow runs → game accessible and playable at live URL

### Tests for User Story 1 (MANDATORY)

> **NOTE: Write these tests FIRST, ensure they PASS locally before deployment**

- [x] T008 [P] [US1] Create `test/web_compatibility_test.dart` with basic game load test
- [x] T009 [P] [US1] Add widget test: verify game UI renders without errors on web
- [x] T010 [P] [US1] Add widget test: verify all 15 tiles are present in initial state
- [ ] T011 [US1] Run `flutter test` locally to validate tests pass before deployment

### Implementation for User Story 1

- [x] T012 [US1] Create `.github/workflows/deploy.yml` workflow file with Flutter setup steps
- [x] T013 [US1] Add checkout step (actions/checkout@v4) to workflow
- [x] T014 [US1] Add Flutter setup step (subosito/flutter-action@v2) with stable Flutter (pinned to 3.38.2)
- [x] T015 [US1] Add dependency installation step: `flutter pub get`
- [x] T016 [US1] Add test execution step: `flutter test` (runs widget tests)
- [x] T017 [US1] Add web build step: `flutter build web --release --base-href "/15puzzle/"`
- [ ] T018 [US1] Add deployment step with retry wrapper (max 3 attempts) or document manual rerun procedure
- [x] T019 [US1] Configure deployment to push `build/web/` contents to `gh-pages` branch (peaceiris/actions-gh-pages)
- [x] T020 [US1] Add workflow trigger: on push to main branch only
- [ ] T021 [US1] Commit workflow file and push to 001-github-pages branch
- [ ] T022 [US1] Test workflow locally with `act` tool (optional) or push to test branch
- [ ] T023 [US1] Merge 001-github-pages to main and monitor GitHub Actions workflow
- [ ] T024 [US1] Verify deployment success: navigate to https://gregpuzzles1.github.io/15puzzle/
- [ ] T025 [US1] Validate all acceptance scenarios: game loads, is playable, deployment <5 minutes

**Checkpoint**: At this point, User Story 1 should be fully functional - game is live and accessible via web browser

---

## Phase 4: User Story 2 - Responsive Layout (Priority: P2)

**Goal**: Game adapts to desktop (≥1024px), tablet (768-1023px), and mobile (<768px) viewports

**Independent Test**: Open deployed site on different viewport sizes and verify appropriate scaling without scrolling

### Tests for User Story 2 (MANDATORY)

> **NOTE: Write responsive tests BEFORE implementing layout changes**

- [x] T026 [P] [US2] Add widget test: verify layout adapts to iPhone SE viewport (375×667)
- [x] T027 [P] [US2] Add widget test: verify layout adapts to iPad viewport (768×1024)
- [x] T028 [P] [US2] Add widget test: verify layout adapts to desktop viewport (1920×1080)
- [x] T029 [P] [US2] Add widget test: verify no overflow errors on all viewport sizes
- [x] T030 [P] [US2] Add widget test: verify tile size ≥44×44px on mobile viewport
- [ ] T031 [US2] Run `flutter test` to validate responsive tests locally

### Implementation for User Story 2

- [x] T032 [US2] Implement responsive board sizing in `lib/main.dart` (no fixed board constant)
- [x] T033 [US2] Provide `getBoardSize(BuildContext)` helper
- [x] T034 [US2] Implement getBoardSize() with MediaQuery to calculate optimal board size
- [x] T035 [US2] Add breakpoint logic and enforce minimum board size for touch targets
- [x] T036 [US2] Use getBoardSize(context) for board rendering
- [ ] T037 [US2] Test responsive behavior locally: `flutter run -d chrome` and resize window
- [ ] T038 [US2] Verify tile sizes: mobile (340/4=85px), tablet (480/4=120px), desktop (520/4=130px) all ≥44px
- [ ] T039 [US2] Run `flutter test` to verify responsive tests now pass (TDD: green phase)
- [ ] T040 [US2] Test manual resize behavior: drag browser window and verify smooth layout updates
- [ ] T041 [US2] Commit responsive layout changes with message: "feat: add responsive layout for mobile/tablet/desktop"
- [ ] T042 [US2] Push to 001-github-pages branch and merge to main for deployment
- [ ] T043 [US2] Manual test on deployed site: Chrome DevTools device emulation (iPhone, iPad, Desktop)
- [ ] T044 [US2] Validate all acceptance scenarios: appropriate scaling on all devices, no horizontal scrolling

**Checkpoint**: At this point, User Story 2 should be fully functional - game is playable on mobile, tablet, and desktop

---

## Phase 5: User Story 3 - Loading Screen (Priority: P3)

**Goal**: Minimal animated spinner appears immediately (<500ms) during Flutter initialization

**Independent Test**: Open deployed site with Slow 3G throttling and verify spinner appears before game loads

### Tests for User Story 3 (MANDATORY)

> **NOTE: Write loading screen tests BEFORE implementing**

- [ ] T045 [P] [US3] (Optional) Add test to verify `#loading` div exists in `web/index.html`
- [ ] T046 [P] [US3] (Optional) Add test to verify spinner CSS exists (positioning + animation)
- [ ] T047 [P] [US3] (Optional) Add test to verify `@keyframes spin` is present
- [ ] T048 [US3] Manual test: verify spinner visible on Slow 3G (Chrome DevTools Network tab)

### Implementation for User Story 3

- [x] T049 [US3] Update `web/index.html` to include a loading spinner
- [x] T050 [US3] Add loading spinner div with id="loading" immediately after <body> tag
- [x] T051 [US3] Add inline CSS: fixed overlay + centered spinner
- [x] T052 [US3] Add nested div with class="spinner" for animated element
- [x] T053 [US3] Add spinner CSS (50×50, border, top color accent)
- [x] T054 [US3] Add `@keyframes spin` animation
- [x] T055 [US3] Add `<noscript>` fallback message
- [x] T056 [US3] Add browser compatibility check via feature detection
- [x] T057 [US3] Show "Unsupported Browser" message if checks fail
- [x] T058 [US3] Implement spinner removal via conditional import helpers (`lib/web_utils.dart` + `lib/web_utils_stub.dart`)
- [x] T059 [US3] Remove spinner after first frame in `_PuzzleGameState.initState()` using `WidgetsBinding.instance.addPostFrameCallback`
- [x] T060 [US3] Remove `#loading` element in web implementation (`removeLoadingSpinner()`)
- [ ] T061 [US3] Test locally: `flutter run -d chrome` and verify spinner appears briefly then disappears
- [ ] T062 [US3] Test with throttling: Chrome DevTools → Network → Slow 3G → hard refresh (Ctrl+Shift+R)
- [ ] T063 [US3] Verify spinner appears within 500ms and transitions smoothly when game loads
- [ ] T064 [US3] Test JavaScript disabled: disable JS in browser settings → verify noscript message shows
- [ ] T065 [US3] Test old browser simulation: modify browser detection logic to force error → verify unsupported message
- [ ] T066 [US3] Commit loading screen changes with message: "feat: add minimal loading spinner and browser fallbacks"
- [ ] T067 [US3] Push to 001-github-pages branch and merge to main for deployment
- [ ] T068 [US3] Manual test on deployed site: throttle to Slow 3G and verify spinner behavior
- [ ] T069 [US3] Validate all acceptance scenarios: spinner appears <500ms, shows progress, smooth transition

**Checkpoint**: At this point, User Story 3 should be fully functional - loading UX is polished and professional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, documentation, and edge case handling

- [ ] T070 [P] Run `flutter analyze` to verify no linting errors or warnings
- [ ] T071 [P] Run full test suite: `flutter test` and verify all tests pass (responsive + loading + compatibility)
- [ ] T072 [P] Update README.md with deployed site URL: https://gregpuzzles1.github.io/15puzzle/
- [ ] T086 [P] Verify HTTPS enforcement: navigate to http://gregpuzzles1.github.io/15puzzle/ and confirm auto-redirect to https://
- [ ] T073 [P] Add "Play Online" badge/link to README.md
- [ ] T074 Manual cross-browser testing: Chrome, Firefox, Safari/Edge on desktop (full game playthrough each)
- [ ] T075 Manual mobile testing: Chrome DevTools → iPhone SE, Pixel 5, iPad (verify touch targets ≥44px)
- [ ] T076 Manual performance testing: Slow 3G throttling → verify <5s interactive, spinner visible
- [ ] T077 Manual audio testing: verify New Game chime + Win fanfare (tile-move sound intentionally disabled)
- [ ] T078 Manual confetti testing: verify win animation smooth (60fps), acceptable on low-end devices
- [ ] T079 Edge case validation: extremely small viewport (<320px) → verify game handles gracefully
- [ ] T080 Edge case validation: refresh mid-game → verify game resets correctly
- [ ] T081 Edge case validation: network error during load → verify error handling (if implemented)
- [ ] T082 Verify all 7 success criteria from spec.md (SC-001 through SC-007)
- [ ] T083 Document any known limitations in README.md (audio autoplay policies, confetti performance)
- [ ] T084 Create GitHub release/tag with version number and deployment notes
- [ ] T085 Update copilot-instructions.md if any new patterns/conventions emerged during implementation

---

## Addendum: Web Meta/SEO/Analytics Files

- [x] T087 Add SEO title/description/keywords/viewport in `web/index.html`
- [x] T088 Add Google tag (gtag.js) in `web/index.html`
- [x] T089 Add `web/sitemap.xml` for `https://gregpuzzles1.github.io/15puzzle/`
- [x] T090 Add `web/robots.txt` pointing to sitemap

---

## Dependencies & Execution Order

### User Story Completion Order (with dependencies)

```
Setup (Phase 1) → Foundational (Phase 2)
                        ↓
                     US1 (P1) [MVP] ← MUST COMPLETE FIRST
                        ↓
        ┌───────────────┴───────────────┐
        ↓                               ↓
     US2 (P2)                        US3 (P3)
   [Responsive]                   [Loading Screen]
        ↓                               ↓
        └───────────────┬───────────────┘
                        ↓
              Polish (Phase 6)
```

**Key Dependencies**:
- **US1 MUST be complete** before US2 or US3 (need live deployment to test responsive/loading)
- US2 and US3 are **independent** and can be implemented in parallel (different files)
- Polish phase depends on **all user stories complete**

### Parallel Execution Opportunities

**Within US1** (can work simultaneously):
- T008, T009, T010 (test files) + T012-T020 (workflow file) - different files

**Within US2** (can work simultaneously):
- T026-T030 (test files) + T032-T036 (main.dart) - if careful with merge conflicts

**Within US3** (can work simultaneously):
- T045-T047 (HTML tests) + T049-T057 (web/index.html) + T058-T060 (lib/main.dart)

**Polish Phase** (highly parallel):
- T070, T071, T072, T073 can all run in parallel (different files/commands)

---

## Implementation Strategy

### MVP First (User Story 1 Only)

**Time**: ~45-60 minutes  
**Tasks**: T001-T025 (Setup + Foundational + US1)  
**Deliverable**: Game accessible at https://gregpuzzles1.github.io/15puzzle/ with basic functionality

**Value**: Establishes deployment pipeline. Users can play the game online even without responsive design or loading screen.

### Incremental Delivery (Add US2)

**Time**: +30-45 minutes  
**Tasks**: T026-T044 (US2)  
**Deliverable**: Game now works on mobile and tablet devices

**Value**: Expands accessibility to mobile users (significant audience for casual games).

### Full Feature (Add US3 + Polish)

**Time**: +45-60 minutes  
**Tasks**: T045-T085 (US3 + Polish)  
**Deliverable**: Professional loading experience + comprehensive testing

**Value**: Polished UX, all edge cases handled, fully tested across browsers and devices.

---

## Task Count Summary

- **Setup**: 3 tasks
- **Foundational**: 4 tasks (blocking)
- **US1 (Deploy)**: 18 tasks (4 tests + 14 implementation)
- **US2 (Responsive)**: 19 tasks (6 tests + 13 implementation)
- **US3 (Loading)**: 25 tasks (4 tests + 21 implementation)
- **Polish**: 17 tasks (cross-cutting)

**Total**: 86 tasks

**Critical Path**: Setup → Foundational → US1 → US2/US3 → Polish  
**Estimated Time**: 2.5-3.5 hours for full implementation (per quickstart guide)

---

## Test Coverage

### Automated Tests (flutter_test)

- Game load and UI rendering (T008-T010)
- Responsive layout at 3 viewport sizes (T026-T030)
- Loading screen HTML structure (T045-T047)

**Total**: 10 automated widget tests

### Manual Tests (browser-based)

- Cross-browser compatibility: Chrome, Firefox, Safari/Edge (T074)
- Mobile device emulation: iPhone SE, Pixel 5, iPad (T075)
- Performance testing: Slow 3G throttling (T076)
- Audio/confetti testing: game mechanics (T077-T078)
- Edge case validation: small viewports, refresh, errors (T079-T081)

**Total**: 11+ manual test scenarios

### Test Execution Points

1. **T011**: After US1 tests written (should pass locally)
2. **T031**: After US2 tests written (should fail - TDD red)
3. **T039**: After US2 implementation (should pass - TDD green)
4. **T048**: Manual loading screen checklist
5. **T071**: Full suite before final deployment
6. **T074-T081**: Comprehensive manual testing post-deployment

---

## Format Validation

✅ All tasks follow strict format: `- [ ] [TaskID] [P?] [Story] Description with file path`  
✅ Task IDs are sequential: T001-T086  
✅ [P] markers present for parallelizable tasks (16 tasks marked)  
✅ [Story] labels present for user story tasks (US1, US2, US3)  
✅ File paths specified where applicable  
✅ Setup/Foundational phases have no story labels  
✅ Polish phase has no story labels  
✅ Each user story phase is independently testable  
✅ Tests are MANDATORY (user explicitly requested)

**Specification**: GitHub Pages Deployment  
**MVP Scope**: User Story 1 (T001-T025)  
**Ready for**: Implementation (`/speckit.implement` or manual execution following quickstart.md)
