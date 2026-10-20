# Creator discovery implementation

## Direction
People provide an additional entrance into a training path. Preserve Home / Explore / Profile, the photo-led program cards, existing workout flow, and the adaptive Minotaur mark. Use the established Avenir headings, architectural surfaces, opposing cut corners, and restrained red actions. Portraits and real program covers carry identity; no additional glass treatment is needed.

The requested design-taste-frontend skill is website-scoped. Apply its subject-based idea, clear hierarchy, honest imagery and screenshot critique to the native UI; website quotas and browser inspection do not apply.

## Plan
1. Add a creator directory derived from public, non-personal programs. Search names, handles, specialties and programs. Keep private workouts out of all discovery surfaces.
2. Add Plans / Creators / Communities inside Explore. Keep the existing plan preference and filter flow. Put portraits and creator bylines beneath program artwork, with separate accessible profile links.
3. Add creator profiles with bio, specialties, program catalog, free following, and public community entrances. Persist follows locally, independently of membership, and expose followed creators from Profile.
4. Show a community summary before joining: creator, sample member count, program price and included community, available discussion channels and optional direct messaging. Never preview private member text/photos. Open the Community section directly from community discovery.
5. Use existing free and paid-program membership behavior. Paid programs explicitly include community; paid checkout remains the existing local preview. Separate paid-community subscriptions, real verification, external creator links/import, push notifications and network chat require future production implementation.
6. Verify follow persistence/privacy, creator search/profile navigation, free/paid community gates, plus native light/dark and larger-text layouts. Retain the Today workout icon; cover photos continue in Explore, library rows, detail and share previews.

## Demo honesty
Existing sample accounts and member counts are demonstration content. Label the curated sample directory accordingly. Do not imply an Olympic/NBA endorsement or assign unsubstantiated credentials. Program `official` is not identity verification.

## Implemented and reviewed

Explore now has Plans, Creators and Communities with shared name/handle/goal search. Public program bylines and community previews lead to creator profiles. Public identities are derived from published programs; creator follows persist independently of membership. Profile links to Following and the user's public creator profile. Community entrances open the correct Labyrinth section and preserve the existing join/post gates.

The Today card retains its workout/recovery icon. Program artwork continues in discovery, library rows, Labyrinth details and share previews.

Validation: 11 model tests passed, including follow persistence, private/personal discovery exclusion, independent membership and legacy snapshots. Three UI journeys passed: existing join/post/reply; creator name search/profile/follow/Following/community entry; and dark mode, paid-preview cancellation, and accessibility XXXL. Review captures are in `creator-screens/`. A screenshot review caught overlapping native follow-label transitions; the final follow control disables those transitions and uses intrinsic vertical sizing. Later captures verify the settled state without overlap. `git diff --check` passed.

Results: `/private/tmp/minotaur-creators-review.xcresult` contains the model and existing community checks (the initial creator automation expected an obsolete Cancel label). `/private/tmp/minotaur-creators-final.xcresult` verifies the corrected search/follow journey. `/private/tmp/minotaur-creators-settled.xcresult` verifies the final dark/paid/accessibility flow. The earlier test runner also had a startup failure; subsequent focused runs used one simulator and passed.

Production work is tracked in `../PRODUCTION_NOTES.md`: authenticated creator profiles/verification, creator onboarding/import and external links, real billing with independent community subscriptions, server-enforced access and live messaging. This implementation remains local, with free communities and paid-program communities using the existing no-charge paid-preview flow.
