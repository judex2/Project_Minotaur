import Foundation

/// Public identity is separate from a paid program or community membership.
nonisolated struct CreatorProfile: Identifiable, Hashable {
    var id: String
    var name: String
    var handle: String
    var portrait: PhotoRef?
    var specialty: String
    var bio: String
    var isDemo: Bool

    func matches(_ query: String) -> Bool {
        query.isEmpty || "\(name) \(handle) \(specialty) \(bio)".localizedCaseInsensitiveContains(query)
    }

    // Illustrative identities from the local catalog; no real-athlete credentials implied.
    static let demoDetails: [String: (String, String)] = [
        "@nightwing": ("Strength & muscle", "Focused lifting, purposeful sessions, and room to ask questions along the way. Explore Dane’s approach and train alongside the Nightwing community."),
        "@minotaurlabs": ("Progressive strength", "Structured lifting programs built around clear progression and a steady training rhythm."),
        "@gaia": ("Calisthenics & bodyweight", "A space to explore bodyweight training, build skills, and share the small milestones along the way."),
        "@zeus": ("Running & conditioning", "Sprint sessions, conditioning, and recovery in one training path. Find your pace with a community that moves with you."),
        "@garagelifter": ("Garage gym strength", "Straightforward lifting with a rack, a bar, and a repeatable plan."),
        "@minotaur": ("Fitness foundations", "Simple movements and approachable sessions for people finding their feet in fitness."),
        "@alexrivers": ("Strength & foundations", "Explore training programs and build a rhythm that works for you.")
    ]
}

nonisolated extension Labyrinth {
    var accessSummary: String {
        price == nil ? "Free program · community included" : "\(priceLabel) program · community included"
    }
    func matchesDiscovery(_ query: String) -> Bool {
        query.isEmpty || "\(name) \(tagline) \(category) \(goal ?? "") \(ownerName) \(ownerHandle)".localizedCaseInsensitiveContains(query)
    }
}
