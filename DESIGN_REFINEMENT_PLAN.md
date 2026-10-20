# Minotaur — Product Design Refinement Plan

## Status

Planning document for the premium-product refinement pass. This plan does not change the Minotaur logo or migrate the native SwiftUI application.

## Product thesis

Minotaur helps someone do one of two things without friction:

1. Find a structured workout that fits their goal, experience, schedule, and equipment.
2. Build a personal workout they can begin using immediately.

Both paths converge on the same core loop:

**Choose a plan → complete today's workout → see progress → share proof or talk with the community → return.**

The social layer supports training. It does not compete with it.

## Product promise

**Structured training without gatekeeping.** Programs earn credibility through completion, progress, and useful member conversation—not creator popularity.

Keep:

- Minotaur logo and name
- “Labyrinth” as the branded name for a program
- “Founder” for a program creator
- “Earn your way out” as the manifesto line
- Three-tab navigation: Home, Explore, Profile

Clarify:

- Use plain fitness language for actions and orientation.
- Reserve mythology for naming, milestones, and emotional moments.
- Prefer “Start workout,” “Today’s workout,” “Program,” “Join,” and “Finish workout” over “operation,” “architecture,” “enlist,” and “finish Labyrinth.”

## Art direction

### Direction name: Precision Future

A clean near-future sports interface inspired by the visual confidence of Mirror’s Edge: bright architectural space, sharp contrast, bold solid color, purposeful photography, and highly legible information. It should feel like premium training equipment—not cyberpunk, gamer UI, military software, or nostalgic Y2K decoration.

### Design idea

**The route through a Labyrinth becomes the organizing visual device.** A strong signal line represents the active path: it marks current workouts, progress, selected states, and completion. It should be functional rather than ornamental.

### Visual principles

- Large fields of light or dark color instead of stacks of bordered panels.
- One dominant image or action per screen.
- Strong hierarchy with fewer visible type styles.
- Solid fills; no decorative gradients, glow, glass, or chrome effects.
- Photography stays in color and uses consistent crops.
- Red identifies the active path and primary action—not every interactive element.
- Blue is reserved for discovery, information, and secondary wayfinding.
- Green is reserved for successful completion.
- Borders appear mainly on inputs and controls, not around every section.
- Square or minimally softened geometry for content; native continuous corners for sheets and system controls.

## Color system

Exact values should be tuned against simulator screenshots and contrast tests.

### Shared semantic colors

- **Signal red:** energetic primary action, active route, workout progress
- **Route blue:** discovery, filters, informational selection
- **Success green:** completed sets, finished workouts, positive confirmation
- **Warning amber:** destructive or attention-required states only

### Light appearance

- Canvas: near-white with a cool cast
- Primary surface: pure white
- Secondary field: cool light gray
- Primary text: near-black
- Secondary text: dark neutral gray
- Primary action: solid signal red

### Dark appearance

- Canvas: deep graphite rather than pure black everywhere
- Primary surface: raised charcoal
- Secondary field: cool dark gray
- Primary text: clean white
- Secondary text: light neutral gray
- Primary action: the same signal red, contrast-adjusted if necessary

### Rules

- Never communicate state with color alone.
- Meet WCAG AA contrast for readable text.
- Photography may receive a flat scrim only when text overlays it.
- The logo retains its existing design and red treatment.

## Typography

Use Apple’s native type system for clarity, performance, and Dynamic Type:

- SF Pro Display for large editorial and program titles
- SF Pro Text for body, labels, and controls
- SF Mono only for timers and aligned workout measurements
- Sentence case for almost all interface copy
- Uppercase is limited to the logo, compact badges, and rare milestone moments
- Tight tracking on display titles; normal tracking for body and controls
- Support Dynamic Type without truncating required actions

Remove the current dependence on tiny tracked uppercase labels and monospaced metadata.

## Information architecture

### Bottom navigation

Retain:

- Home
- Explore
- Profile

Move to a native-feeling tab implementation with clear selected labels, VoiceOver labels, and proper safe-area behavior. Do not add a fourth Create tab.

### Home: answer the first decision immediately

The first screen should begin with two unequal but clearly available paths:

1. **Find a plan** — primary entry into guided discovery
2. **Build my workout** — direct entry into the simplified builder

Below those actions:

1. Today’s workout
2. Your programs
3. Proof from the community
4. Recommended programs

If no workout is scheduled, the Today area provides “Choose today’s workout” and “Make today a rest day.”

### Explore

Explore should help users decide rather than merely browse cards.

Primary filters:

- Goal: build muscle, get stronger, learn calisthenics, improve general fitness
- Experience: beginner, intermediate, advanced
- Location/equipment: home, gym, bodyweight
- Schedule: days per week
- Length: ongoing or fixed duration
- Category: lifting or calisthenics

Results should explain why they match. Member count and recency remain the MVP sort logic; avoid implying a sophisticated recommendation algorithm.

### Profile

Organize around identity and ownership:

- Profile summary
- Progress
- Programs created
- Programs joined
- Saved/completed workout history
- Creator tools when relevant

Creation remains available here, but Home also provides a direct shortcut.

## Screen-by-screen refinement

### 1. App shell and onboarding

- Add a short first-run orientation focused on goal, experience, equipment, and preferred training days.
- Explain “Labyrinth” once in plain language: “A Labyrinth is a structured workout program.”
- Use answers to preconfigure Explore filters and the empty Home state.
- Keep account/backend interactions mocked during this local-first pass.
- Support light/dark system appearance and an optional in-app appearance override.

### 2. Home

- Replace the current archive-like header and card stack with a strong, calm daily dashboard.
- Preserve the logo at the top without competing menu ornament.
- Present Find and Build as immediate actions with distinct descriptions.
- Make Today’s workout the largest functional surface after those paths.
- Show 2–3 exercises, estimated duration, equipment, and a clear Start workout button.
- Add Edit schedule and See all today actions using plain language.
- Keep community transformations lower on the screen as proof, not the main purpose.
- Reduce horizontal carousels where vertical scanning is clearer.

### 3. Guided “Find a plan” flow

- Use a short native sheet or pushed flow rather than exposing every filter at once.
- Ask goal first, then equipment/location, experience, and schedule.
- Show matched results with a concise match explanation.
- Allow users to edit any answer without restarting.
- Include explicit empty and no-match recovery states.

### 4. Explore

- Keep direct search for users who already know what they want.
- Replace generic category chips with useful fitness filters.
- Use fewer, larger program cards with consistent photography.
- Clearly distinguish official, verified creator, free, paid, joined, and private states.
- Keep “Most Hyped Transformations” as a supporting discovery module; consider the more ownable title “Proof” during copy review.

### 5. Labyrinth detail

Locked view:

- Dominant color cover image
- Program name, creator, verification state
- Goal, experience, equipment, schedule, duration
- Plain description
- 2–3 sample workout blocks
- Limited transformation/progress teaser
- Sticky Join or Unlock action with transparent price/access wording

Unlocked view:

- Three areas matching the manifesto: Program, Community, Progress
- Program shows current day first and the full plan second
- Community contains General, Q&A, and private founder thread
- Progress contains a member photo feed and a clear upload action
- Share remains available without distracting from Start workout

### 6. Personal workout and Labyrinth builder

Offer two creation modes at entry:

- **Quick workout:** title, exercises, sets/reps or duration, rest, save, start
- **Publish a Labyrinth:** adds cover, description, schedule, visibility, access/price, guidance media, and community settings

Shared editor rules:

- Exercise blocks are the central object.
- Add and edit blocks inline when practical.
- Day structure is visible without opening multiple similar sheets.
- Sets, reps/duration, and rest are always visible.
- Advanced fields are progressively disclosed.
- Reordering uses explicit handles and accessible alternatives.
- Drafts autosave locally.
- Destructive actions are reversible or confirmed.
- Keyboard never covers the primary action.

### 7. Active workout

- Make the current exercise the dominant element.
- Show set progress, target, rest, and guidance without requiring interpretation.
- Use large tap targets that are comfortable with one hand during training.
- Separate total workout timer from rest timer visually and semantically.
- Allow correcting an accidentally completed set.
- Keep previous/next exercise navigation visible.
- Add pause, end early, and resume states with clear consequences.
- Change the primary completion language to Finish workout.
- Completion summary includes time, completed sets, volume when meaningful, and an optional note.
- From completion: Done, Share, Post to community, and Add progress photo.

### 8. Community and progress

- Keep community locked until joining, as currently intended.
- Separate General and Q&A instead of mixing tags in one undifferentiated feed.
- Keep founder messaging visibly private and asynchronous.
- Make posting feel secondary to training completion, not like a generic social app composer.
- Transformation discovery must lead to the associated Labyrinth.
- Show likes, comments, and shares, but rank MVP content honestly using available local counts.
- Require clear consent before progress photos appear in public discovery.

### 9. Profile

- Remove dashboard-like founder statistics from the first visual priority for non-creators.
- Lead with training progress and active programs.
- Reveal creator statistics and Create Labyrinth tools contextually.
- Separate created, joined, and completed programs.
- Give appearance, privacy, and account settings an obvious home.

### 10. Sharing

- Retain the existing branded share preview.
- Update it to the new visual system.
- Clearly distinguish general program shares from completed-workout achievements.
- Private program links remain limited invitations.
- Production rich previews, hosted routes, and Universal Links remain documented follow-ups.

## Core reusable components

Build or revise these before screen-level polishing:

- Semantic color and spacing tokens for light/dark appearances
- Typography roles with Dynamic Type support
- Primary, secondary, quiet, and destructive buttons
- Native-feeling navigation and tab shell
- Program cover card
- Compact program row
- Exercise block
- Set tracker
- Rest timer
- Goal/filter control
- Creator/official badge
- Empty, loading, error, and locked states
- Photo/media treatment with caption
- Completion summary
- Share preview
- Form field and validation message

Avoid a universal “Panel” component that makes unrelated content look identical.

## Motion and feedback

The interface should feel fluid, interactive, and exciting. Motion communicates state and spatial continuity rather than decorating the app.

- Signature behavior: the active route line advances as sets and workouts are completed.
- Cards expand into their destination where SwiftUI navigation permits, so content feels continuous rather than replaced.
- Workout blocks insert, reorder, collapse, and expand in place with short native springs.
- Filters update results immediately and preserve the user’s visual context.
- Bottom sheets track the user’s gesture and settle naturally at useful detents.
- Primary controls have tactile press states and restrained haptic feedback.
- Use numeric transitions for timers and set counts.
- Rest completion receives haptic and visual confirmation.
- Workout completion transforms the active workout into its result summary with one confident full-screen transition, without confetti.
- Navigation gestures remain standard; animation never traps the user or delays an action.
- No essential control depends on a hidden gesture.
- Respect Reduce Motion and Reduce Transparency.

### Motion character

- Fast and precise for controls: approximately 120–200 ms.
- Smooth and spatial for screen/content transitions: approximately 240–420 ms.
- Springs should settle decisively without playful bouncing.
- Only transform and opacity animate during frequent interactions; avoid expensive layout effects during timers and scrolling.
- Reduce Motion replaces travel and scale with short crossfades while preserving every state change.

## Photography and imagery

- Replace unrelated or inconsistent placeholder imagery, including non-fitness images.
- Establish one image direction: bright architectural training spaces, strong natural color, clean athletic movement, diverse experience levels and body types.
- Avoid imagery that implies celebrity endorsement.
- Avoid exclusively shirtless, extreme, or intimidating bodies.
- Balance aspirational performance with approachable everyday training.
- Use generated images only as art-direction placeholders; production requires owned or properly licensed media.

## Accessibility and usability requirements

- Minimum 44×44 pt interactive targets
- VoiceOver labels and logical focus order
- Dynamic Type through accessibility sizes
- No essential information communicated only by color
- AA text contrast in both appearances
- Visible focus/selection states
- Reachable primary actions with keyboard displayed
- Long program and exercise names tested
- Missing-image, empty-feed, and no-result states tested
- Plain-language explanation for branded terms
- Confirm before discarding meaningful workout or builder progress

## Copy changes

Recommended replacements:

| Current | Proposed |
|---|---|
| Enter Labyrinth | Start workout / View program |
| Enlist | Join program |
| Architecture | Program |
| Current operation | Today’s workout |
| Yesterday’s operation | Previous workout |
| Finish Labyrinth | Finish workout |
| Archive entry | Program preview |
| Founded Labyrinths | Programs created |
| Silent corridor | No posts yet |

Keep “Labyrinth,” “Founder,” “Earn your way out,” and milestone language where they add identity without reducing comprehension.

## Implementation sequence

### Phase 1 — Foundation

- Freeze baseline screenshots and behavior checklist.
- Implement semantic light/dark tokens, typography roles, spacing, and controls.
- Replace global panel/border styling incrementally.
- Move tab and navigation behavior toward native SwiftUI conventions.

### Phase 2 — First-run and primary paths

- Add onboarding/preferences model.
- Rebuild Home around Find a plan and Build my workout.
- Add guided discovery entry and Quick workout entry.

### Phase 3 — Discovery and program decision

- Refine Explore filters and result cards.
- Rebuild locked/unlocked Labyrinth detail.
- Add the distinct Program, Community, and Progress areas.

### Phase 4 — Creation

- Separate Quick workout from Publish a Labyrinth.
- Simplify the block editor and day structure.
- Add local draft autosave and recovery.

### Phase 5 — Workout execution

- Rebuild active workout hierarchy and set controls.
- Refine rest behavior, interruption states, and completion summary.
- Integrate progress capture and sharing.

### Phase 6 — Social and profile

- Separate General, Q&A, founder thread, and Progress.
- Refine transformation discovery and consent.
- Reorganize Profile for trainees and creators.

### Phase 7 — Polish and validation

- Audit both appearances on supported iPhone sizes.
- Test Dynamic Type, VoiceOver, Reduce Motion, and contrast.
- Exercise loading, empty, error, long-content, and interrupted-workout states.
- Run unit/UI tests and complete screenshot review rounds.

## Visual review checkpoints

After each implementation phase:

1. Capture every changed screen in light and dark appearances.
2. Review hierarchy, comprehension, consistency, crop quality, contrast, and reachable actions.
3. Fix the three most visible issues before moving on.
4. Verify the primary user task manually.
5. Run the relevant automated tests.

Because the selected design-taste skill targets browser pages rather than native application screens, its browser lint/inspection scripts are not applicable here. Its hierarchy, typography, color, imagery, and screenshot-critique principles are applied manually to the SwiftUI simulator captures instead.

## Definition of “ready to ship visually”

- A first-time user can identify Find a plan and Build my workout immediately.
- “Labyrinth” is understandable without prior product knowledge.
- Home communicates today’s next action in under five seconds.
- All major screens feel related without relying on repeated bordered cards.
- Light and dark appearances are equally intentional.
- Workout controls remain clear while tired, moving, or using one hand.
- Social content supports trust and motivation without overtaking training.
- Placeholder content and irrelevant imagery are clearly identified for replacement.
- No clipped required actions at large text sizes.
- Every primary flow has complete, empty, loading, error, and recovery states.
