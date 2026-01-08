<!--
SYNC IMPACT REPORT
==================
Version Change: [UNVERSIONED] → 1.0.0
Change Type: Initial ratification
Rationale: First formal constitution for completed game app project

Principles Defined:
  ✅ I. Cross-Platform Consistency - Ensures game works identically on all 6 platforms
  ✅ II. Performance First - Maintains 60fps gameplay and responsive UI
  ✅ III. User Experience - Prioritizes smooth interactions and feedback
  ✅ IV. Code Maintainability - Keeps codebase simple and readable

Template Consistency:
  ✅ plan-template.md - Constitution Check section aligns with principles
  ✅ spec-template.md - User scenarios support UX and testability requirements
  ✅ tasks-template.md - Task organization supports independent feature delivery

Follow-up Actions: None required - all templates compatible
Suggested Commit: docs: establish constitution v1.0.0 (initial ratification for game app)
-->

# 15 Puzzle Game Constitution

## Core Principles

### I. Cross-Platform Consistency

All game features MUST work identically across all supported platforms (Windows, macOS, Linux, Android, iOS, Web). Platform-specific code MUST be isolated and have equivalent behavior. Testing MUST verify functionality on at least 3 platforms before release.

**Rationale**: Users expect the same puzzle-solving experience regardless of device. Divergent behavior creates confusion and support burden.

### II. Performance First

Game MUST maintain 60fps during all interactions including tile sliding, animations, and confetti effects. Touch/click response time MUST be <16ms. Memory usage MUST remain stable (no leaks) during extended play sessions.

**Rationale**: Puzzle games require immediate visual feedback. Any lag breaks the tactile satisfaction of sliding tiles and diminishes user experience.

### III. User Experience

Every user action MUST provide immediate visual feedback. Audio feedback is optional and best-effort (especially on web, where autoplay/user-gesture policies can block playback). Game state MUST be clear at all times (current moves, solvability, win condition). Error states MUST be impossible through UI design rather than validation messages.

**Rationale**: The 15 puzzle is a casual game—frustration from unclear states or missing feedback drives users away immediately.

### IV. Code Maintainability

Source code MUST remain readable and self-documenting. Complex logic MUST include inline explanation. Dependencies MUST be minimal and well-justified. New features MUST not compromise existing code clarity.

**Rationale**: Game development involves frequent iteration. Technical debt accumulates rapidly if maintainability isn't enforced from day one.

## Technical Standards

### Flutter & Dart Requirements

- **SDK Versions**: Flutter ≥3.10.0, Dart ≥3.10.0
- **Linting**: flutter_lints ^6.0.0 with all recommended rules enabled
- **State Management**: StatefulWidget patterns for game state; avoid over-engineering with external state libraries
- **Testing**: Widget tests for UI components; unit tests for game logic

### Asset Management

- **Audio Files**: All sounds SHOULD be optimized for low latency and small size (target <100KB where practical)
- **File Organization**: Assets MUST be organized in `assets/` with clear subdirectory structure
- **Format Standards**: Prefer WAV for broad support; MP3 is permitted where it improves compatibility/performance. Avoid relying on per-action SFX on web if it harms responsiveness.

### Dependency Policy

- **New Dependencies**: MUST be justified by significant functionality that cannot be reasonably implemented in-house
- **Existing Dependencies**: audioplayers (audio), confetti (celebration), cupertino_icons (iOS styling)
- **Audit Frequency**: Quarterly review of dependency updates and security advisories

## Development Workflow

### Change Implementation

1. **Feature Clarity**: All changes MUST have clear user-facing value or technical necessity
2. **Testing Protocol**: Manual test on ≥2 platforms before considering complete
3. **Performance Validation**: Profile any changes affecting animations or touch handling
4. **Code Review**: Self-review required; external review for architectural changes

### Quality Gates

- ✅ No linting errors or warnings
- ✅ Game solvable from all shuffled states
- ✅ All interactions provide feedback (visual or audio)
- ✅ 60fps maintained on mid-range hardware
- ✅ Memory stable after 100+ game cycles

## Governance

This constitution defines non-negotiable principles for the 15 Puzzle Game project. All code changes, feature additions, and refactorings MUST comply with these principles.

### Amendment Process

1. **Proposal**: Document proposed change with rationale
2. **Impact Analysis**: Assess effect on existing code and templates
3. **Version Bump**: Apply semantic versioning (see below)
4. **Update Artifacts**: Sync all .specify/ templates and documentation
5. **Ratification**: Update LAST_AMENDED_DATE

### Versioning Policy

- **MAJOR**: Remove or fundamentally redefine a core principle
- **MINOR**: Add new principle or expand governance section
- **PATCH**: Clarify wording, fix typos, refine existing guidance

### Compliance

All development work MUST verify alignment with this constitution. Templates in `.specify/templates/` inherit these requirements. Complexity that violates principles MUST be justified in writing before implementation.

**Version**: 1.0.0 | **Ratified**: 2026-01-07 | **Last Amended**: 2026-01-07
