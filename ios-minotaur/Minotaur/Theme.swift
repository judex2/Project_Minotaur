import AVKit
import SwiftUI
import UIKit

/// Architectural neutrals with red reserved for the current action.
enum Ink {
    static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                           green: CGFloat((hex >> 8) & 255) / 255,
                           blue: CGFloat(hex & 255) / 255, alpha: 1)
        })
    }
    static let canvas = adaptive(0xF2F4F6, 0x101216)
    static let surface = adaptive(0xFFFFFF, 0x1C2026)
    static let raised = adaptive(0xE8ECF0, 0x2A3038)
    static let text = adaptive(0x17212B, 0xF4F6F8)
    static let inverse = adaptive(0xFFFFFF, 0x14171C)
    static let hairline = adaptive(0xD4D9E0, 0x373E48)
    static let muted = adaptive(0x53606E, 0xADB7C4)
    static let faint = adaptive(0x626E7B, 0xA0ACBA)
    static let signal = Color(red: 0.85, green: 0.149, blue: 0.196)
    static let signalSoft = adaptive(0xC7202C, 0xFF6970)
    static let signalWash = adaptive(0xFCE8EA, 0x382227)
    static let signalHairline = adaptive(0xE8ADB2, 0x8D444B)
    static let blue = adaptive(0x235CD7, 0x8AADFF)
    static let blueWash = adaptive(0xE4EDFF, 0x202E48)
    static let success = adaptive(0x16744D, 0x6DDBA6)
    static let facet = adaptive(0xE8EDF1, 0x171C22)
    static let glassEdge = adaptive(0xBBC5CE, 0x53606E)
}

/// Shared readable label style, scaled with Dynamic Type.
struct MonoLabel: View {
    let text: String
    var size: CGFloat = 10
    var color: Color = Ink.muted
    var icon: String?

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: size + 1, weight: .semibold))
            }
            Text(text)
                .font(.subheadline.weight(.medium))
        }
        .foregroundStyle(color)
    }
}

/// Semantic headline sizing keeps legacy screens accessible.
struct Display: View {
    let text: String
    var size: CGFloat = 28
    var color: Color = Ink.text
    var weight: Font.Weight = .black

    var body: some View {
        Text(text)
            .font(size >= 26 ? TrainingType.display : size >= 21 ? TrainingType.section : .headline)
            .tracking(-size * 0.025)
            .foregroundStyle(color)
            .lineSpacing(1)
    }
}

/// Solid content surface; glass is reserved for a small number of controls.
struct Panel<Content: View>: View {
    var padding: CGFloat = 16
    var fill: Color = Ink.surface
    var borderColor: Color = Ink.hairline
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(RouteSurface(fill: fill))
    }
}

struct PressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

/// Full-width slab button — the app's primary call to action.
struct SlabButton: View {
    let title: String
    var icon: String?
    var filled: Bool = true
    var accent: Bool = false
    var height: CGFloat = 54
    let action: () -> Void

    private var foreground: Color {
        filled ? (accent ? .white : Ink.inverse) : (accent ? Ink.signalSoft : Ink.text)
    }

    private var background: Color {
        filled ? (accent ? Ink.signal : Ink.text) : Ink.raised
    }

    private var border: Color {
        filled ? (accent ? Ink.signalSoft : .clear) : (accent ? Ink.signalHairline : Ink.hairline)
    }

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 12) {
                Text(title)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.identity)
                    .animation(nil, value: title)
                if let icon {
                    Image(systemName: icon).font(.system(size: 13, weight: .black))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .frame(minHeight: max(48, height))
            .foregroundStyle(foreground)
            .background(background, in: RoutePanelShape(cut: 10))
            .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle())
    }
}

/// Small bordered tag chip (FREE, ELITE, QUESTION, ...).
struct Chip: View {
    let text: String
    var inverted: Bool = false
    var accent: Bool = false

    private var background: Color {
        accent ? Ink.signalWash : Ink.raised
    }

    private var border: Color {
        accent ? Ink.signalSoft : (inverted ? .clear : Ink.hairline)
    }

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(accent ? Ink.signalSoft : Ink.text)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(background)
            .clipShape(Capsule())
    }
}

/// Section header with a title and a trailing hint.
struct SectionHeader: View {
    let title: String
    var trailing: String?
    var rule: Bool = true

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Display(text: title, size: 20)
            Spacer(minLength: 0)
            if let trailing {
                MonoLabel(text: trailing, size: 9, color: Ink.faint)
            }
        }
    }
}

/// Thin animated progress rule.
struct ProgressRule: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let value: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Ink.raised)
                Rectangle()
                    .fill(Ink.signal)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .frame(height: 3)
        .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.85), value: value)
    }
}

/// Image container that respects the Color-anchor + overlay layout rule.
struct MediaBox: View {
    let ref: PhotoRef?
    var height: CGFloat
    var dim: Double = 0

    var body: some View {
        Ink.raised
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .overlay {
                if let image = ref?.uiImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .allowsHitTesting(false)
                } else {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 22, weight: .thin))
                        .foregroundStyle(Ink.faint)
                        .allowsHitTesting(false)
                }
            }
            .overlay { Color.black.opacity(dim).allowsHitTesting(false) }
            .clipped()
    }
}

// MARK: - Local-first sharing

/// Temporary routes used until production web previews and universal links are connected.
enum MinotaurShareLinks {
    static func labyrinth(_ labyrinth: Labyrinth) -> URL {
        let route = labyrinth.isPublic ? "labyrinth" : "invite"
        return URL(string: "https://share.minotaur.app/\(route)/\(labyrinth.id.uuidString.lowercased())")!
    }

    static func workout(labyrinth: Labyrinth, day: ProgramDay) -> URL {
        URL(string: "https://share.minotaur.app/workout/\(labyrinth.id.uuidString.lowercased())/day-\(day.number)")!
    }
}

struct WorkoutShareSummary {
    let day: ProgramDay
    let durationMinutes: Int
    let completedSets: Int
    let totalSets: Int
}

struct ShareLinkPreviewSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    let labyrinth: Labyrinth
    var workout: WorkoutShareSummary?
    var allowsCommunityPost = false
    var onShared: (() -> Void)? = nil

    @State private var showSystemShare = false
    @State private var showCompose = false

    private var link: URL {
        if let workout { return MinotaurShareLinks.workout(labyrinth: labyrinth, day: workout.day) }
        return MinotaurShareLinks.labyrinth(labyrinth)
    }

    private var shareMessage: String {
        if let workout {
            return "I logged \(workout.day.title) in \(labyrinth.name) — \(workout.completedSets)/\(workout.totalSets) sets in \(workout.durationMinutes) min."
        }
        if labyrinth.isPublic {
            return "Take a look at \(labyrinth.name) on Minotaur."
        }
        return "You have been invited to \(labyrinth.name) on Minotaur. Join to see the full program and community."
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    MonoLabel(text: workout == nil ? "Labyrinth link" : (workout!.completedSets == workout!.totalSets ? "Workout complete" : "Session saved"),
                              size: 10, color: Ink.signalSoft)
                    Display(text: workout == nil ? "Share your program" : "Nice work.", size: 26)

                    if labyrinth.cover != nil {
                    MediaBox(ref: labyrinth.cover, height: 210, dim: 0.28)
                        .overlay(alignment: .bottomLeading) {
                            VStack(alignment: .leading, spacing: 7) {
                                MonoLabel(text: workout == nil ? labyrinth.ownerHandle : "Trained in \(labyrinth.name)",
                                          size: 9, color: .white)
                                Display(text: workout?.day.title ?? labyrinth.name, size: 22, color: .white)
                            }
                            .padding(16)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: "figure.strengthtraining.traditional").font(.title).foregroundStyle(Ink.signalSoft)
                            Text(workout?.day.title ?? labyrinth.name).font(.title2.bold())
                            Text(workout == nil ? "A path made by you." : "Your effort. Your progress.").font(.subheadline).foregroundStyle(Ink.muted)
                        }.padding(24).frame(maxWidth: .infinity, alignment: .leading).background(Ink.surface, in: RoundedRectangle(cornerRadius: 20))
                    }

                    if let workout {
                        HStack(spacing: 0) {
                            shareMetric("Duration", "\(workout.durationMinutes)m")
                            shareMetric("Sets", "\(workout.completedSets)/\(workout.totalSets)")
                        }
                        .padding(.vertical, 14)
                        .background(Ink.surface, in: RoundedRectangle(cornerRadius: 20))
                    } else {
                        Panel {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(labyrinth.tagline)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Ink.muted)
                                MonoLabel(text: labyrinth.isPublic ? labyrinth.durationLabel : "Private invite · details locked",
                                          size: 9, color: Ink.faint)
                            }
                        }
                    }

                    Text("Preview link only. Live links and rich previews will be connected before launch.").font(.caption).foregroundStyle(Ink.muted)

                    MonoLabel(text: link.absoluteString, size: 8, color: Ink.faint, icon: "link")
                        .lineLimit(1)

                    SlabButton(title: "Share Link", icon: "square.and.arrow.up", accent: true) {
                        showSystemShare = true
                    }

                    if allowsCommunityPost, workout != nil {
                        SlabButton(title: "Post to Community", icon: "person.3", filled: false) {
                            showCompose = true
                        }
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
            .background(Ink.canvas)
            .navigationTitle("Share preview")
            .navigationBarTitleDisplayMode(.inline)

            .toolbarBackground(Ink.canvas, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.headline)
                        .foregroundStyle(Ink.signalSoft)
                }
            }
        }
        .sheet(isPresented: $showSystemShare) {
            SystemShareSheet(items: [shareMessage, link], onShared: onShared)
        }
        .sheet(isPresented: $showCompose) {
            ComposePostView(labyrinth: labyrinth,
                            prefill: workout.map { "\($0.completedSets == $0.totalSets ? "Workout complete" : "Session saved"): \($0.day.title) — \($0.completedSets)/\($0.totalSets) sets." } ?? "")
                .environment(state)
                .presentationBackground(Ink.canvas)
        }
    }

    private func shareMetric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            MonoLabel(text: label, size: 8, color: Ink.faint)
            Text(value)
                .font(.system(size: 16, weight: .black, design: .monospaced))
                .foregroundStyle(Ink.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
    }
}

private struct SystemShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onShared: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            if completed { Task { @MainActor in onShared?() } }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// Creator-uploaded photos and clips displayed inside workout guidance surfaces.
struct GuidanceMediaGallery: View {
    let media: [MediaAttachment]
    var height: CGFloat = 170

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(media) { attachment in
                    Group {
                        if let image = attachment.uiImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            VideoPlayer(player: AVPlayer(url: attachment.fileURL))
                                .overlay(alignment: .topLeading) {
                                    Chip(text: "Guidance clip", accent: true).padding(8)
                                }
                        }
                    }
                    .frame(width: 270, height: height)
                    .background(Ink.raised)
                    .clipped()
                    .overlay(alignment: .bottomLeading) {
                        if let caption = attachment.caption?.trimmingCharacters(in: .whitespacesAndNewlines),
                           !caption.isEmpty {
                            Text(caption)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(
                                    LinearGradient(colors: [.clear, .black.opacity(0.9)],
                                                   startPoint: .top, endPoint: .bottom)
                                )
                        }
                    }
                    .overlay(Rectangle().strokeBorder(Ink.hairline, lineWidth: 1))
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.7)
    }

    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
