# Minotaur — architectural signal

Visual refinement, October 19, 2026. The existing navigation, creation, workout, and community flows remain the baseline.

## Reference study

- [Mirror's Edge Catalyst gallery](https://interfaceingame.com/games/mirrors-edge-catalyst/): inspected progression, missions, player-division, and map-selection artwork. The useful characteristics are pale architectural fields, selectively cut corners, spacious geometric headings, precise routes, and red marking the current action. The original's tiny, low-contrast game text is unsuitable for a phone and is not carried over.
- [Paperpillar's Pilates app](https://dribbble.com/shots/27534607-Mobile-App-Pilates): inspected the complete presentation. Depth comes from photography and limited translucent controls, rather than making every container glass. Minotaur keeps its neutral/red palette and uses material only for photo badges and the temporary rest panel, in addition to the existing native navigation.

## Design decisions

- Palette: porcelain #F2F4F6, white #FFFFFF, graphite #17212B, steel #53606E, signal red #D92632, plus existing semantic status colors. Dark mode uses the corresponding charcoal surfaces.
- Type: Avenir Next for larger headings and numeric emphasis, native SF for instructions, controls, forms, and long text. All custom sizes scale with Dynamic Type.
- Geometry: one restrained cut-corner silhouette for the primary workout card, action buttons, covers, and workout blocks; softer fields and system controls stay familiar.
- Composition: retain today's workout as Home's focal point, with a small red edge marking its importance. Light architectural facets sit behind the content. They are static and non-interactive.
- Route: the actual training checkpoints become angular waypoints; only the current waypoint is red. No invented scores, game menus, new tabs, or added steps.
- Glass: a small photo badge and the active rest panel. Reduce Transparency and Increase Contrast use an opaque surface. Workout prescriptions, captions, and editor fields stay solid.

The distinguishing device is the program's own route and current waypoint. This is a focused refinement of the working app, not a recreation of either reference or a use of game artwork.

## Verification

- Simulator build succeeded. Six existing UI journeys passed with no failures: discovery and settings, light/dark and large text, full-program creation/editing, personal workout completion/history, timed targets and large-text rest, and library/rest controls.
- Inspected actual captures of Home in both themes, Explore, builder blocks, normal rest controls, and largest-text rest. Captures are saved in `design/catalyst-screens`.
- Calculated contrast: body on the light canvas 14.78:1; secondary text on the darker pale facet 5.45:1; white on signal red 4.91:1; red text on the pale facet 4.85:1. The material surfaces have opaque fallbacks for Reduce Transparency and Increase Contrast; the fallback conditions were inspected in source.
- No changes to models, persistence, navigation destinations, workout sequencing, or membership behavior in this visual pass. No new dependencies or imported reference artwork. Changes remain uncommitted on main.

## Today glass refinement

At the user's request, the large Today card now uses native Liquid Glass on iOS 26 with its existing cut corners, red route marker and opaque controls. Older iOS versions use regular frosted material. A faint reflection translates slowly over a 14-second easing cycle; text and controls do not move. Reduce Motion disables the drift; Reduce Transparency and increased contrast use a solid surface. The animation pauses when the scene becomes inactive and resets when the panel disappears.

The simulator build and two existing UI journeys passed (dark appearance/large text, and discovery). Actual Home captures in light, dark and accessibility XXXL were inspected and saved in `today-glass-screens/`. Accessibility-setting fallbacks were checked in source; the iOS 18 material fallback was compiled, not run on an older simulator. Result: `/private/tmp/minotaur-today-glass.xcresult`.

The subsequent edge refinement adds a fine outer reflection, a softer inner rim, and a clipped highlight around the cut corners. Its light direction follows the existing slow drift, while opaque accessibility modes omit the effect. Both existing UI journeys passed again and light/dark screenshots were visually inspected; the review captures above now show the reflective edges. Result: `/private/tmp/minotaur-glass-edges.xcresult`.

### Current glass behavior: scroll-responsive rim

This supersedes the timed sheen described above. At the user's request the interior animation and custom continuous gray outline were removed. Localized white reflections and a soft, narrow refraction band suggest lens thickness along the existing angular edge. Home's native scroll geometry directly controls the light position, so scrolling back reverses the reflections and the lighting stops changing when scrolling stops. No timer, repeating animation, tilt sensing, or rounded geometry is used. Reduce Motion fixes the light position; reduced transparency/increased contrast retain the solid fallback.

A focused simulator journey captured initial, scrolled and return positions in light/dark, and successfully started the workout after each scroll sequence. Captures were inspected in `scroll-glass-screens/`; the dark return frame gives a full-card view. Build and UI check passed, and `git diff --check` passed. Result: `/private/tmp/minotaur-scroll-glass.xcresult`.
