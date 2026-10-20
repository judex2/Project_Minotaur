import Foundation
import Observation

/// Persisted slice of the app.
nonisolated struct StateSnapshot: Codable {
    var memberships: [Membership]
    var posts: [Post]
    var messages: [DirectMessage]
    var ownedLabyrinths: [Labyrinth]
    var dmSettings: [String: Bool]
    var preferences: TrainingPreferences? = nil
    var schedule: [String: ScheduleSlot]? = nil
    var history: [WorkoutRecord]? = nil
    var replies: [PostReply]? = nil
    var followedCreators: Set<String>? = nil
    var activityEvents: [ActivityNotification]? = nil
    var readActivityIDs: Set<String>? = nil
}

/// Single source of truth for the whole MVP.
@Observable
final class AppState {
    private(set) var user: UserProfile = SampleData.user
    var labyrinths: [Labyrinth] = SampleData.labyrinths
    var memberships: [Membership] = []
    var posts: [Post] = SampleData.seedPosts()
    var messages: [DirectMessage] = SampleData.seedMessages()
    var preferences = TrainingPreferences()
    var schedule: [String: ScheduleSlot] = [:]
    var history: [WorkoutRecord] = []
    var replies: [PostReply] = []
    private(set) var followedCreators: Set<String> = []
    private(set) var activityEvents: [ActivityNotification] = []
    private(set) var readActivityIDs: Set<String> = []

    /// In-app activity only. Membership and ownership are checked again at presentation time.
    var notifications: [ActivityNotification] {
        var events = activityEvents.filter { event in
            labyrinths.contains { program in
                program.id == event.labyrinthID && (event.kind == .memberJoined ? isOwner(of: program) : (isOwner(of: program) || isMember(of: program)))
            }
        }
        for post in posts where post.isFounder && post.authorName != user.name {
            guard let program = labyrinths.first(where: { $0.id == post.labyrinthID }),
                  let membership = membership(for: program), post.createdAt >= membership.joinedAt else { continue }
            events.append(ActivityNotification(id: "post-\(post.id)", kind: .creatorPost,
                labyrinthID: program.id, postID: post.id, title: "\(program.ownerName) posted in \(program.name)",
                createdAt: post.createdAt, isDemo: SampleData.labyrinths.contains { $0.id == program.id }))
        }
        for reply in replies where reply.authorName != user.name {
            guard let post = posts.first(where: { $0.id == reply.postID && $0.authorName == user.name }),
                  let program = labyrinths.first(where: { $0.id == post.labyrinthID }),
                  isMember(of: program) || isOwner(of: program) else { continue }
            events.append(ActivityNotification(id: "reply-\(reply.id)", kind: .reply,
                labyrinthID: program.id, postID: post.id, title: "\(reply.authorName) replied to your post", createdAt: reply.createdAt))
        }
        return events.sorted { $0.createdAt > $1.createdAt }
    }

    var unreadNotificationCount: Int { notifications.filter { !readActivityIDs.contains($0.id) }.count }

    func markNotificationRead(_ notification: ActivityNotification) {
        readActivityIDs.insert(notification.id); save()
    }

    func markAllNotificationsRead() {
        readActivityIDs.formUnion(notifications.map(\.id)); save()
    }

    /// Future membership event ingestion; the local demo uses the same deduplication path.
    func recordMemberJoined(_ name: String, in program: Labyrinth, eventID: String, isDemo: Bool = false) {
        guard isOwner(of: program), program.isPersonal != true,
              !activityEvents.contains(where: { $0.id == eventID }) else { return }
        activityEvents.append(ActivityNotification(id: eventID, kind: .memberJoined, labyrinthID: program.id,
            title: "\(name) joined \(program.name)", createdAt: Date(), isDemo: isDemo))
        save()
    }

    var publicPrograms: [Labyrinth] {
        labyrinths.filter { $0.isPublic && $0.isPersonal != true }
    }

    var creators: [CreatorProfile] {
        Dictionary(grouping: publicPrograms, by: { $0.ownerHandle.lowercased() }).values.compactMap { programs in
            guard let first = programs.first else { return nil }
            let detail = CreatorProfile.demoDetails[first.ownerHandle.lowercased()]
            return CreatorProfile(id: first.ownerHandle.lowercased(), name: first.ownerName,
                handle: first.ownerHandle, portrait: first.ownerAvatar,
                specialty: detail?.0 ?? Array(Set(programs.map(\.category))).sorted().joined(separator: " · "),
                bio: detail?.1 ?? "Explore \(first.ownerName)’s training plans and find a community that fits your rhythm.",
                isDemo: detail != nil)
        }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func programs(by handle: String) -> [Labyrinth] {
        publicPrograms.filter { $0.ownerHandle.lowercased() == handle.lowercased() }
    }

    func creator(for program: Labyrinth) -> CreatorProfile? {
        creators.first { $0.id == program.ownerHandle.lowercased() }
    }

    func toggleFollow(_ creator: CreatorProfile) {
        guard creator.id != user.handle.lowercased(), creators.contains(where: { $0.id == creator.id }) else { return }
        if followedCreators.contains(creator.id) { followedCreators.remove(creator.id) }
        else { followedCreators.insert(creator.id) }
        save()
    }

    /// Set when a member joins and still owes a baseline capture.
    var baselinePrompt: Labyrinth?

    private let storeURL: URL

    init(storeURL: URL? = nil) {
        let testName = ProcessInfo.processInfo.environment["MINOTAUR_TEST_STATE"]
        self.storeURL = storeURL ?? testName.map { FileManager.default.temporaryDirectory.appendingPathComponent($0 + ".json") } ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("minotaur-state.json")
        seedIfNeeded()
        load()
        if !activityEvents.contains(where: { $0.id == "demo-member-joined" }),
           let program = owned.first(where: { $0.id == SampleData.thread.id }) {
            recordMemberJoined("Maya", in: program, eventID: "demo-member-joined", isDemo: true)
        }
    }

    // MARK: - Derived

    var joined: [Labyrinth] {
        memberships
            .sorted { $0.joinedAt > $1.joinedAt }
            .compactMap { membership in labyrinths.first { $0.id == membership.labyrinthID } }
    }

    var owned: [Labyrinth] {
        labyrinths.filter { $0.ownerHandle == user.handle }
    }

    var activeLabyrinth: Labyrinth? { joined.first }

    var library: [Labyrinth] {
        labyrinths.filter { isMember(of: $0) || isOwner(of: $0) }
    }

    var todaySlot: ScheduleSlot? { schedule[String(Calendar.current.component(.weekday, from: Date()))] }

    var scheduledProgram: Labyrinth? {
        if let slot = todaySlot {
            return library.first { $0.id == slot.labyrinthID }
        }
        return activeLabyrinth ?? library.first
    }

    var scheduledDay: ProgramDay? {
        guard let program = scheduledProgram else { return nil }
        if let number = todaySlot?.dayNumber { return program.days.first { $0.number == number } }
        return today(in: program)
    }

    func setSchedule(_ slots: [String: ScheduleSlot]) { schedule = slots; save() }
    func setPreferences(_ value: TrainingPreferences) { preferences = value; save() }

    func saveWorkout(_ record: WorkoutRecord, day: ProgramDay, program: Labyrinth) {
        guard !history.contains(where: { $0.id == record.id }) else { return }
        if !isMember(of: program), isOwner(of: program) {
            memberships.append(Membership(labyrinthID: program.id, joinedAt: Date(), currentDay: 1, completedDays: []))
        }
        history.insert(record, at: 0)
        if record.completedSets >= record.totalSets {
            completeDay(day, in: program, duration: max(1, record.seconds / 60), volume: 0)
        }
        save()
    }

    /// Public transformation posts ranked by meaningful local engagement.
    var hypedTransformations: [Post] {
        posts
            .filter { post in
                post.pair != nil && post.discoveryConsent == true && labyrinths.contains {
                    $0.id == post.labyrinthID && $0.isPublic
                }
            }
            .sorted { lhs, rhs in
                let lhsScore = lhs.likes + (lhs.commentCount * 3) + ((lhs.shares ?? 0) * 4)
                let rhsScore = rhs.likes + (rhs.commentCount * 3) + ((rhs.shares ?? 0) * 4)
                if lhsScore != rhsScore { return lhsScore > rhsScore }
                return lhs.createdAt > rhs.createdAt
            }
    }

    func isOwner(of labyrinth: Labyrinth) -> Bool { labyrinth.ownerHandle == user.handle }

    func isMember(of labyrinth: Labyrinth) -> Bool {
        memberships.contains { $0.labyrinthID == labyrinth.id }
    }

    func membership(for labyrinth: Labyrinth) -> Membership? {
        memberships.first { $0.labyrinthID == labyrinth.id }
    }

    func today(in labyrinth: Labyrinth) -> ProgramDay? {
        guard let membership = membership(for: labyrinth) else { return labyrinth.days.first }
        let index = min(max(0, membership.currentDay - 1), max(0, labyrinth.days.count - 1))
        return labyrinth.days.indices.contains(index) ? labyrinth.days[index] : nil
    }

    func previousDay(in labyrinth: Labyrinth) -> ProgramDay? {
        guard let membership = membership(for: labyrinth), membership.currentDay > 1 else { return nil }
        let index = membership.currentDay - 2
        return labyrinth.days.indices.contains(index) ? labyrinth.days[index] : nil
    }

    func progress(in labyrinth: Labyrinth) -> Double {
        guard let membership = membership(for: labyrinth), labyrinth.totalDays > 0 else { return 0 }
        return Double(membership.completedDays.count) / Double(labyrinth.totalDays)
    }

    func isComplete(_ labyrinth: Labyrinth) -> Bool {
        guard labyrinth.programFormat == .fixed else { return false }
        guard let membership = membership(for: labyrinth) else { return false }
        return membership.completedDays.count >= labyrinth.totalDays && labyrinth.totalDays > 0
    }

    func posts(in labyrinth: Labyrinth) -> [Post] {
        posts
            .filter { $0.labyrinthID == labyrinth.id }
            .sorted { lhs, rhs in
                if lhs.pinned != rhs.pinned { return lhs.pinned }
                return lhs.createdAt > rhs.createdAt
            }
    }

    func thread(for labyrinth: Labyrinth) -> [DirectMessage] {
        messages.filter { $0.labyrinthID == labyrinth.id }.sorted { $0.sentAt < $1.sentAt }
    }

    /// Progress photos this user has published, newest first.
    var progressGallery: [PhotoRef] {
        posts
            .filter { $0.authorName == user.name }
            .sorted { $0.createdAt > $1.createdAt }
            .compactMap { $0.pair?.current ?? $0.photo }
    }

    // MARK: - Mutations

    func join(_ labyrinth: Labyrinth) {
        guard !isMember(of: labyrinth) else { return }
        memberships.append(Membership(labyrinthID: labyrinth.id,
                                      joinedAt: Date(),
                                      currentDay: 1,
                                      completedDays: [],
                                      baseline: nil))
        baselinePrompt = labyrinth
        save()
    }

    func leave(_ labyrinth: Labyrinth) {
        memberships.removeAll { $0.labyrinthID == labyrinth.id }
        save()
    }

    func setBaseline(_ photo: PhotoRef?, for labyrinth: Labyrinth) {
        guard let index = memberships.firstIndex(where: { $0.labyrinthID == labyrinth.id }) else { return }
        memberships[index].baseline = photo
        save()
    }

    func completeDay(_ day: ProgramDay, in labyrinth: Labyrinth, duration: Int, volume: Int) {
        guard let index = memberships.firstIndex(where: { $0.labyrinthID == labyrinth.id }) else { return }
        memberships[index].completedDays.insert(day.number)
        memberships[index].lastDuration = duration
        memberships[index].lastVolume = volume
        if memberships[index].currentDay == day.number {
            if labyrinth.programFormat == .ongoing, day.number >= labyrinth.totalDays {
                memberships[index].currentDay = 1
                memberships[index].completedDays = []
            } else {
                memberships[index].currentDay = min(labyrinth.totalDays, day.number + 1)
            }
        }
        save()
    }

    func addPost(to labyrinth: Labyrinth, text: String, tag: PostTag, photo: PhotoRef?, sharePublicly: Bool) {
        var pair: ProgressPair?
        if tag == .progress, let photo, let baseline = membership(for: labyrinth)?.baseline {
            pair = ProgressPair(baseline: baseline, current: photo, daysIn: membership(for: labyrinth)?.daysIn ?? 1)
        }
        let post = Post(labyrinthID: labyrinth.id,
                        authorName: user.name,
                        authorAvatar: user.avatar,
                        isFounder: isOwner(of: labyrinth),
                        createdAt: Date(),
                        text: text,
                        tag: pair != nil ? .progress : tag,
                        photo: pair == nil ? photo : nil,
                        pair: pair,
                        likes: 0,
                        likedByMe: false,
                        commentCount: 0,
                        pinned: false,
                        discoveryConsent: sharePublicly && labyrinth.isPublic)
        posts.append(post)
        save()
    }

    func toggleLike(_ post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].likedByMe.toggle()
        posts[index].likes += posts[index].likedByMe ? 1 : -1
        save()
    }

    @discardableResult func addReply(_ text: String, to postID: UUID) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = posts.firstIndex(where: { $0.id == postID }),
              let program = labyrinths.first(where: { $0.id == posts[index].labyrinthID }),
              isMember(of: program) || isOwner(of: program) else { return false }
        replies.append(PostReply(postID: postID, authorName: user.name, text: trimmed))
        posts[index].commentCount += 1
        save()
        return true
    }

    func recordShare(of postID: UUID) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index].shares = (posts[index].shares ?? 0) + 1
        save()
    }

    func togglePin(_ post: Post) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        let newValue = !posts[index].pinned
        if newValue {
            for other in posts.indices where posts[other].labyrinthID == post.labyrinthID {
                posts[other].pinned = false
            }
        }
        posts[index].pinned = newValue
        save()
    }

    func send(_ text: String, in labyrinth: Labyrinth) {
        messages.append(DirectMessage(labyrinthID: labyrinth.id, text: text, fromMe: true, sentAt: Date()))
        save()
    }

    func setDM(_ enabled: Bool, for labyrinth: Labyrinth) {
        guard let index = labyrinths.firstIndex(where: { $0.id == labyrinth.id }) else { return }
        labyrinths[index].dmEnabled = enabled
        save()
    }

    func createLabyrinth(name: String, tagline: String, weeks: Int, daysPerWeek: Int, isPublic: Bool, price: Double?) -> Labyrinth {
        let labyrinth = Labyrinth(
            name: name.isEmpty ? "Untitled Labyrinth" : name,
            ownerName: user.name,
            ownerHandle: user.handle,
            ownerAvatar: user.avatar,
            tagline: tagline.isEmpty ? "A new path through the dark." : tagline,
            cover: .asset("basement_gym_squat_rack"),
            weeks: weeks,
            daysPerWeek: daysPerWeek,
            level: "Open",
            category: "Custom",
            price: price,
            memberCount: 0,
            official: false,
            isPublic: isPublic,
            dmEnabled: true,
            days: SampleData.genericDays(daysPerWeek * 2, focus: ["Push", "Pull", "Legs", "Full Body"])
        )
        labyrinths.insert(labyrinth, at: 0)
        save()
        return labyrinth
    }

    func createLabyrinth(_ labyrinth: Labyrinth) {
        labyrinths.insert(labyrinth, at: 0)
        if labyrinth.isPersonal == true {
            memberships.append(Membership(labyrinthID: labyrinth.id, joinedAt: Date(), currentDay: 1, completedDays: []))
        }
        save()
    }

    func updateLabyrinth(_ labyrinth: Labyrinth) {
        guard let index = labyrinths.firstIndex(where: { $0.id == labyrinth.id }) else { return }
        labyrinths[index] = labyrinth
        save()
    }

    // MARK: - Persistence

    private func seedIfNeeded() {
        guard !FileManager.default.fileExists(atPath: storeURL.path) else { return }
        memberships = [Membership(labyrinthID: SampleData.nightwing.id,
                                  joinedAt: Date().addingTimeInterval(-60 * 60 * 24 * 42),
                                  currentDay: 3,
                                  completedDays: [1, 2],
                                  baseline: .asset("man_fitness_before_photo"),
                                  lastVolume: 14_500,
                                  lastDuration: 58)]
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let snapshot = try? JSONDecoder().decode(StateSnapshot.self, from: data) else { return }
        memberships = snapshot.memberships
        preferences = snapshot.preferences ?? TrainingPreferences()
        schedule = snapshot.schedule ?? [:]
        history = snapshot.history ?? []
        replies = snapshot.replies ?? []
        followedCreators = snapshot.followedCreators ?? []
        activityEvents = snapshot.activityEvents ?? []
        readActivityIDs = snapshot.readActivityIDs ?? []
        posts = snapshot.posts
        var addedFeaturedSamples = false
        for sample in SampleData.featuredTransformationPosts {
            if let index = posts.firstIndex(where: { $0.id == sample.id }) {
                posts[index].discoveryConsent = true
                // Sample Labyrinth IDs are rebuilt with the local catalog, so keep the link current.
                if posts[index].labyrinthID != sample.labyrinthID {
                    posts[index].labyrinthID = sample.labyrinthID
                    addedFeaturedSamples = true
                }
            } else {
                posts.append(sample)
                addedFeaturedSamples = true
            }
        }
        messages = snapshot.messages
        for owned in snapshot.ownedLabyrinths {
            if let index = labyrinths.firstIndex(where: { $0.id == owned.id }) { labyrinths[index] = owned }
            else { labyrinths.insert(owned, at: 0) }
        }
        for (key, value) in snapshot.dmSettings {
            guard let id = UUID(uuidString: key),
                  let index = labyrinths.firstIndex(where: { $0.id == id }) else { continue }
            labyrinths[index].dmEnabled = value
        }
        if addedFeaturedSamples { save() }
    }

    private func save() {
        let snapshot = StateSnapshot(
            memberships: memberships,
            posts: posts,
            messages: messages,
            ownedLabyrinths: labyrinths.filter { candidate in
                candidate.ownerHandle == user.handle
            },
            dmSettings: Dictionary(uniqueKeysWithValues: labyrinths.map { ($0.id.uuidString, $0.dmEnabled) }),
            preferences: preferences, schedule: schedule, history: history, replies: replies,
            followedCreators: followedCreators, activityEvents: activityEvents, readActivityIDs: readActivityIDs
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }
}
