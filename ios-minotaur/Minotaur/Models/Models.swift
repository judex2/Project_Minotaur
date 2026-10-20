import Foundation
import UIKit

nonisolated enum ProgramFormat: String, Codable, Hashable, CaseIterable {
    case fixed
    case ongoing

    var label: String {
        switch self {
        case .fixed: return "Fixed program"
        case .ongoing: return "Ongoing cycle"
        }
    }
}

nonisolated enum MediaKind: String, Codable, Hashable {
    case image
    case video
}

/// A creator-uploaded guidance file stored in Documents/MinotaurMedia.
nonisolated struct MediaAttachment: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var kind: MediaKind
    var relativePath: String
    var caption: String?

    var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(relativePath)
    }

    var uiImage: UIImage? {
        guard kind == .image else { return nil }
        return UIImage(contentsOfFile: fileURL.path)
    }
}

/// A photo that either lives in the asset catalog or was captured by the user.
nonisolated enum PhotoRef: Codable, Hashable {
    case asset(String)
    case data(Data)
    case file(String)

    var uiImage: UIImage? {
        switch self {
        case .asset(let name): return UIImage(named: name)
        case .data(let data): return UIImage(data: data)
        case .file(let relativePath):
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(relativePath)
            return UIImage(contentsOfFile: url.path)
        }
    }
}

nonisolated enum ExerciseMeasure: String, Codable, CaseIterable {
    case reps = "Reps", time = "Time", distance = "Distance"
    var prompt: String {
        switch self { case .reps: return "8–10"; case .time: return "30 sec"; case .distance: return "2 miles" }
    }
}

nonisolated struct ExerciseBlock: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var target: String
    var sets: Int
    var reps: String
    var restSeconds: Int
    var note: String?
    var transitionRestSeconds: Int? = nil
    var media: [MediaAttachment]? = nil
    var measure: ExerciseMeasure? = nil

    // Optional storage keeps workouts created before measurement types compatible.
    var measurement: ExerciseMeasure {
        if let measure { return measure }
        let value = reps.lowercased()
        if value.contains("mile") || value.contains("km") || value.contains("meter") || value.range(of: #"\d\s*m$"#, options: .regularExpression) != nil { return .distance }
        if value.contains("sec") || value.contains("min") || value.contains(":") || value.range(of: #"\d\s*s$"#, options: .regularExpression) != nil { return .time }
        return .reps
    }
    var targetLabel: String {
        let value = reps.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.rangeOfCharacter(from: .letters) != nil || value.contains(":") { return value }
        switch measurement {
        case .reps: return "\(value) reps"
        case .time: return "\(value) sec"
        case .distance: return "\(value) m"
        }
    }
    var summary: String { "\(sets) sets · \(targetLabel) · \(restSeconds)s rest" }
}

nonisolated struct ProgramDay: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var number: Int
    var weekday: String
    var title: String
    var notes: String
    var estimatedMinutes: Int
    var blocks: [ExerciseBlock]
    var media: [MediaAttachment]? = nil
    var recovery: Bool? = nil

    var header: String { "\(weekday) — \(title)" }
    var exerciseSummary: String { "\(blocks.count) \(blocks.count == 1 ? "exercise" : "exercises")" }
    var isRest: Bool { recovery ?? blocks.isEmpty }
}

nonisolated struct Labyrinth: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var ownerName: String
    var ownerHandle: String
    var ownerAvatar: PhotoRef?
    var tagline: String
    var cover: PhotoRef?
    var weeks: Int
    var daysPerWeek: Int
    var level: String
    var category: String
    var price: Double?
    var memberCount: Int
    var official: Bool
    var isPublic: Bool
    var dmEnabled: Bool
    var days: [ProgramDay]
    var format: ProgramFormat? = nil
    var goal: String? = nil
    var equipment: String? = nil
    var isPersonal: Bool? = nil

    var priceLabel: String { price.map { String(format: "$%.2f", $0) } ?? "FREE" }
    var totalDays: Int { days.count }
    var programFormat: ProgramFormat { format ?? .fixed }
    var durationLabel: String {
        programFormat == .ongoing ? "Ongoing · \(days.count)-day cycle" : "\(weeks) weeks"
    }
}

nonisolated struct Membership: Codable, Hashable {
    var labyrinthID: UUID
    var joinedAt: Date
    var currentDay: Int
    var completedDays: Set<Int>
    var baseline: PhotoRef?
    var lastVolume: Int?
    var lastDuration: Int?

    var daysIn: Int {
        max(1, Calendar.current.dateComponents([.day], from: joinedAt, to: Date()).day ?? 0)
    }
}

nonisolated enum PostTag: String, Codable, Hashable, CaseIterable {
    case update
    case question
    case progress

    var label: String {
        switch self {
        case .update: return "Update"
        case .question: return "Question"
        case .progress: return "Progress"
        }
    }
}

nonisolated struct ProgressPair: Codable, Hashable {
    var baseline: PhotoRef
    var current: PhotoRef
    var daysIn: Int
}

nonisolated struct Post: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var labyrinthID: UUID
    var authorName: String
    var authorAvatar: PhotoRef?
    var isFounder: Bool
    var createdAt: Date
    var text: String
    var tag: PostTag
    var photo: PhotoRef?
    var pair: ProgressPair?
    var likes: Int
    var likedByMe: Bool
    var commentCount: Int
    var shares: Int? = nil
    var pinned: Bool
    var discoveryConsent: Bool? = nil
}

nonisolated struct TrainingPreferences: Codable, Equatable {
    var goal = "Build muscle"
    var experience = "Beginner"
    var equipment = "Any"
    var daysPerWeek = 3
}

nonisolated struct ScheduleSlot: Codable {
    var labyrinthID: UUID?
    var dayNumber: Int?
}

nonisolated struct WorkoutRecord: Codable, Identifiable {
    var id = UUID()
    var labyrinthID: UUID
    var programName: String
    var workoutName: String
    var finishedAt = Date()
    var seconds: Int
    var completedSets: Int
    var totalSets: Int
    var daySnapshot: ProgramDay? = nil
    var exerciseSets: [String: Int]? = nil
    var isComplete: Bool { completedSets >= totalSets }
    var durationLabel: String { seconds < 60 ? "\(seconds)s" : "\(seconds / 60)m \(seconds % 60)s" }
}

nonisolated struct PostReply: Codable, Identifiable {
    var id = UUID()
    var postID: UUID
    var authorName: String
    var text: String
    var createdAt = Date()
}

nonisolated struct DirectMessage: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var labyrinthID: UUID
    var text: String
    var fromMe: Bool
    var sentAt: Date
}

nonisolated struct UserProfile: Codable, Hashable {
    var name: String
    var handle: String
    var tagline: String
    var avatar: PhotoRef?
    var verified: Bool
}

nonisolated extension Date {
    /// Compact relative stamp, e.g. "2H AGO".
    var shortAgo: String {
        let seconds = Int(Date().timeIntervalSince(self))
        if seconds < 60 { return "NOW" }
        if seconds < 3_600 { return "\(seconds / 60)M AGO" }
        if seconds < 86_400 { return "\(seconds / 3_600)H AGO" }
        return "\(seconds / 86_400)D AGO"
    }
}
