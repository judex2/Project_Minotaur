# Minotaur — daily flow refinement

October 19, 2026. Local-first SwiftUI implementation; original logo and three main tabs retained. Work is uncommitted on main.

## Direction

The Labyrinth becomes a literal training path: completed checkpoints, the next day, and a repeat indicator for ongoing plans. The path communicates the user's position rather than inventing a fitness score. Keep the established chalk (#F4F6F8), white (#FFFFFF), graphite (#14171C), signal red (#D92632), and route blue (#235CD7), with their existing dark-mode counterparts. Native SF typography supports readable, accessible controls. The visual emphasis belongs to today's workout; discovery and creation become secondary for users with a library.

## Implemented

- Adaptive Home hierarchy: today's session first for existing libraries; Find and Build first for an empty library.
- Shared training-path component on Home, program details, and fresh session summaries. Ongoing cycles explicitly repeat; fixed paths show completion.
- Rest countdown, add-time, and skip controls stay above the bottom workout actions. Large-text layouts stack the rest controls.
- Dedicated session completion and history-detail views, with accurate partial-session wording and optional sharing. No image is required to finish or share a workout.
- New sessions preserve their exercise definitions and completed-set counts independently of subsequent program edits. Older history remains readable as totals.
- Complete training-library screen with search and All / My workouts / Joined / Created filters, accessible from Home and Profile. Full history is accessible from Profile.
- Shared exercise-block cards in both builders. Reps / Time / Distance selection, a consistent target formatter, and explicit unit guidance replace the ambiguous combined field.
- Member-only post/reply pages with persisted local replies, accessible reply and share actions, and actionable community empty states.
- Post sharing opens a Labyrinth invitation, not the gated post or private member media. Share counts increase only after the system share flow reports completion.

## Compatibility and limits

New saved fields are optional for backward compatibility. Old workout files, history, and posts do not require a destructive reset. No service SDK, authentication, backend, payment, or live URL hosting was added.

Replies and engagement remain on this device; seeded engagement counts are labeled as demo engagement in conversations rather than represented as real locally available replies. Production community permissions must be enforced on the eventual server. Existing placeholder link behavior remains explicit.

Timed targets describe the exercise prescription; this pass does not add an automatic timed-exercise countdown. The existing elapsed-session and rest timers continue to work. Photo assets were preserved rather than replacing member imagery with generated results.

## Verification

- Simulator build succeeded on iPhone 17 Pro / iOS 26.3.1.
- All 18 checks passed: ten model/persistence tests and eight UI journeys. Coverage includes replies and membership gating, library filtering, personal and full-program creation, partial sessions, reopening history, target units, onboarding, light/dark appearance, and largest accessibility text.
- Following screenshot review, all ten model tests and three relevant UI journeys were rerun successfully. The final largest-text workout adjustment was then checked with another passing targeted UI run.
- Actual captures are in `design/flow-screens`. Visual review corrected Home's large-text heading arrangement, duplicate personal-workout titles, dark-mode checkpoint contrast, and large-text timer/action layout. A final full-width background adjustment prevents scrolling content showing through beside the persistent rest panel.
- `git diff --check` passed. No commits or pushes were made.

Physical-device, full VoiceOver, and production multi-user behavior remain outside this local preview pass. The screenshot set spans the successful regression and polish runs, rather than generated mockups.
