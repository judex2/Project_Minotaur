# Minotaur — Precision Future

Native SwiftUI refinement, October 18, 2026. Work remains on `main`, uncommitted. The existing logo and app icon were not changed by this refinement pass.

## What changed

- Shared light/dark palette: chalk, graphite, signal red, and route blue. Native typography, calmer surfaces, readable labels, larger controls, and reduced-motion-aware press/progress feedback.
- Native three-tab navigation. Home leads with **Find a plan** and **Build my workout**.
- First-run preferences; Explore search and filters for goal, experience, equipment, training style, duration, cost, and weekly availability. Ongoing cycles remain self-paced rather than being mistaken for a weekly frequency.
- A single-canvas personal workout builder, private by default, with locally saved drafts and direct exercise editing.
- The full Labyrinth builder retains fixed and ongoing structures, banners, uploaded guidance, captions, custom rests, day reordering, and editing. Exercise blocks open directly; day settings are now separate. Populated-day/exercise removal is confirmed.
- Editing an existing fixed program preserves its full sequence and weekly-frequency metadata rather than silently rebuilding it from its first few sessions.
- A focused active-workout screen: exercise navigation, completed sets, undo, adjustable rest, pause/resume, skip/add rest, and partial-session confirmation. Real workout history replaces fabricated volume totals. Partial sessions do not advance the plan.
- Program / Community / Progress sections. Community includes General and Q&A; progress publishing is explicitly opt-in for public discovery. Personal workouts stay private.
- Profile library, recent workout history, weekly schedule, training preferences, and appearance settings.
- An approachable sample program and a new generated color cover. Generated art is used as editorial cover imagery, not as evidence of a real member’s transformation.

## Visual review

The `screens` folder contains actual simulator captures, not generated UI mockups. `Minotaur-direction.png` is a conceptual art-direction board; the running app uses Apple’s native SF typography and the original logo asset.

The design skills informed the shared visual language and the separation of training, discovery, and community. Expo was not used: the application is SwiftUI.

## Verification

- Simulator build succeeded. All 11 regression tests passed: seven model/persistence tests and four UI journeys, on iPhone 17 Pro / iOS 26.3.1. The final copy/layout cleanup was then compiled successfully.
- A separate first-run orientation UI test also passed after correcting multiline headline sizing: 12 passing checks across the two final runs.
- Journeys cover discovery, settings, light/dark appearance, accessibility-size text, personal creation and completion, membership gating, baseline skipping, full program creation, ongoing-day removal, and reopening an editor.
- Model checks cover save/reload, edited programs, partial-session behavior, duplicate-record protection, ongoing wraparound, privacy consent, scheduling, and preservation of existing fixed sessions.
- Contrast calculations: white on the primary red is 4.91:1; secondary text on the light canvas is 5.94:1; faint text is 4.80:1; adaptive red text is 5.28:1 in light mode and 6.70:1 in dark mode.
- Actual screenshots were inspected and used to correct empty-cover treatment, oversized decorative text, input labels, action widths, and light-mode contrast.

## Deliberate limits

This is a refined local-first build, not a production-service launch. Authentication, Supabase synchronization, purchases, hosted share previews, moderation, and multi-user messaging remain future integrations. Comment/share counts on the seeded community posts are demonstration data; they are not a live engagement service.

The original sample catalog had unstable identifiers. New catalog identifiers are stable; custom programs remain preserved. Legacy orphaned sample memberships are retained in storage, not guessed at or deleted. A production migration/import strategy still needs to be defined.

Camera capture, every uploaded video format, VoiceOver end-to-end, smaller physical iPhones, and all accessibility sizes across every advanced editor still need device-level release QA. The sample training content needs coach/editorial review before launch.
