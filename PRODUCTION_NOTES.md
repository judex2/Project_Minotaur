# Production follow-ups

## Notifications

- Home now has an in-app bell/inbox with persisted read states, All/Unread filtering, mark-all-read, and links to community/post destinations. Creator posts are derived from joined-community posts after the membership date; replies to the current user's posts are derived from local replies. Self-authored events are excluded. Leaving a community hides its updates.
- A labeled sample member-join event demonstrates the creator side; `recordMemberJoined` deduplicates incoming join events for owned Labyrinths. Real external join activity must be delivered by the authenticated backend. Use stable actor IDs rather than display-name comparisons for production self-event filtering.
- Connect incoming membership, creator-post, reply and service updates to a server event stream with stable IDs, recipient authorization and retention rules. Add push delivery, device tokens, permission onboarding, category preferences and routing when production services exist. The current app does not request OS notification permission or deliver push alerts.
- Validation: 12 model checks and the bell/inbox/post/community/read-state UI journey passed (13 total, zero failures). Actual light inbox/empty-state captures were inspected in `design/notification-screens/`. Result: `/private/tmp/minotaur-notifications.xcresult`.

## Creator discovery and communities

- The local directory is derived from public, non-personal Labyrinths. Connect independent creator accounts, editable bios/portraits, specialty metadata and stable account IDs to the authenticated service; migrate follows from normalized handles to those IDs.
- Implement reviewed identity verification and credential evidence. Do not equate a program's `official` flag with verified athlete identity. Existing creator profiles and audience counts are demonstration content, with no real-athlete endorsement.
- Add creator profile links and public program landing pages for external audiences. Creator onboarding/import and external social links need validation and the production sharing service.
- Keep free following independent of paid entitlement. Current pricing covers a program with its community included. Separate paid-community subscriptions and creator-wide memberships require billing products, entitlement rules and explicit renewal information.
- Connect creator/member messaging and discussions to the service; implement creator inbox, moderation and delivery. Existing messaging and posts are local only.

## Share links and rich previews

The current iOS sharing interface intentionally uses placeholder URLs under
`https://share.minotaur.app`. Before release:

- Replace `MinotaurShareLinks` with real hosted routes backed by the production service.
- Serve public Labyrinth, private invitation, and completed-workout landing pages.
- Add Open Graph and social-card metadata so Messages and social apps render rich previews.
- Configure Universal Links and the `apple-app-site-association` file so installed users open Minotaur directly.
- Resolve private invitation links through authenticated, revocable access tokens rather than exposing Labyrinth data in the URL.
- Generate finished-workout share records server-side so recipients see a stable, privacy-safe summary.

## Native refinement release checks

- Connect local identities, memberships, posts, history, schedules, and uploaded files to the eventual authenticated backend. Enforce private-program and community access on the server.
- Preserve explicit discovery consent for progress media. Do not use private/baseline photos in public previews without consent.
- Replace seeded engagement counts with real likes, comment threads, and share events. Private messages are currently a local preview, not delivered to another person.
- Add purchase entitlement verification; the current paid-program flow explicitly offers a no-charge local preview.
- Review and replace demonstration training content with coach-reviewed programs. The new foundations cover is generated editorial artwork, not a real client testimonial.
- Define migration for old prototype sample memberships that referenced random catalog IDs. Do not delete orphaned local records. New catalog IDs are stable.
- Complete physical-iPhone, VoiceOver, media-import/camera, offline error, and large-text QA. The simulator regression suite is not a substitute for release-device testing.
- Define file backup, export, storage failure handling, media cleanup, and schema migration before treating local storage as production durability.
- Decide how creators extend or shorten already-published fixed programs. This pass preserves and edits the full existing sequence; it intentionally does not silently regenerate later weeks.
