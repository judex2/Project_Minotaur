import SwiftUI

struct TransformationCard: View {
    let post: Post
    let labyrinth: Labyrinth
    var width: CGFloat? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let pair = post.pair {
                HStack(spacing: 2) {
                    transformationImage(pair.baseline, label: "Baseline")
                    transformationImage(pair.current, label: "Day \(pair.daysIn)")
                }
                .frame(height: 180)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    MonoLabel(text: post.authorName, size: 9, color: Ink.signalSoft)
                    Spacer()
                    HStack(spacing: 12) {
                        engagement("hand.thumbsup.fill", post.likes)
                        engagement("bubble.left.fill", post.commentCount)
                        engagement("arrowshape.turn.up.right.fill", post.shares ?? 0)
                    }
                }
                Text(post.text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Ink.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        MonoLabel(text: "From", size: 8, color: Ink.faint)
                        Text(labyrinth.name)
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(Ink.text)
                            .lineLimit(1)
                    }
                    Spacer()
                    MonoLabel(text: "View Labyrinth", size: 8, color: Ink.signalSoft, icon: "arrow.right")
                }
            }
            .padding(14)
        }
        .frame(width: width)
        .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
        .background(Ink.surface)
        .clipShape(RoutePanelShape(cut: 16))

    }

    private func transformationImage(_ ref: PhotoRef, label: String) -> some View {
        MediaBox(ref: ref, height: 180)
            .overlay(alignment: .bottomLeading) {
                Chip(text: label, accent: label != "Baseline").padding(8)
            }
    }

    private func engagement(_ icon: String, _ count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9, weight: .bold))
            Text("\(count)").font(.system(size: 9, weight: .bold, design: .monospaced))
        }
        .foregroundStyle(Ink.muted)
    }
}

/// Big editorial cover card used in Explore "For You".
struct CoverCard: View {
    let labyrinth: Labyrinth

    var body: some View {
        ZStack(alignment: .topLeading) {
            MediaBox(ref: labyrinth.cover, height: 260, dim: 0.25)
                .overlay(alignment: .bottom) {
                    LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .center, endPoint: .bottom)
                        .frame(height: 160)
                        .allowsHitTesting(false)
                }
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 6) {
                        MonoLabel(text: labyrinth.ownerHandle, size: 9, color: Ink.muted)
                        Display(text: labyrinth.name, size: 24)
                        HStack {
                            MonoLabel(text: labyrinth.priceLabel, size: 10, color: .white)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .black))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(16)
                }
                .overlay(alignment: .topLeading) {
                    Chip(text: labyrinth.category, accent: true).padding(12)
                }
        }
        .overlay(Rectangle().strokeBorder(Ink.hairline, lineWidth: 1))
    }
}

/// Wide list card used on Home / trending.
struct TrendingCard: View {
    let labyrinth: Labyrinth
    var joined: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            MediaBox(ref: labyrinth.cover, height: 150, dim: 0.15)
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Display(text: labyrinth.name, size: 17)
                    Spacer(minLength: 8)
                    MonoLabel(text: labyrinth.official ? "Official" : labyrinth.priceLabel,
                              size: 10,
                              color: .white)
                }
                HStack(spacing: 6) {
                    Text("by \(labyrinth.ownerHandle)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Ink.muted)
                    if labyrinth.official {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Ink.signalSoft)
                    }
                }
                MonoLabel(text: "\(memberLabel) members · \(labyrinth.durationLabel) · \(labyrinth.level)",
                          size: 9,
                          color: Ink.faint)
                SlabButton(title: joined ? "Open" : "Details", filled: joined, accent: joined, height: 44, action: action)
                    .padding(.top, 2)
            }
            .padding(14)
        }
        .background(Ink.surface)
        .overlay(Rectangle().strokeBorder(Ink.hairline, lineWidth: 1))
    }

    private var memberLabel: String {
        labyrinth.memberCount >= 1_000
            ? String(format: "%.1fK", Double(labyrinth.memberCount) / 1_000)
            : "\(labyrinth.memberCount)"
    }
}

/// Compact card for the horizontal "Your Labyrinths" rail.
struct RailCard: View {
    let labyrinth: Labyrinth
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MediaBox(ref: labyrinth.cover, height: 120, dim: 0.3)
                .overlay(alignment: .topTrailing) {
                    Chip(text: "\(Int(progress * 100))%", accent: progress > 0).padding(8)
                }
            VStack(alignment: .leading, spacing: 8) {
                Display(text: labyrinth.name, size: 15)
                    .lineLimit(2)
                MonoLabel(text: labyrinth.ownerHandle, size: 9, color: Ink.faint)
                ProgressRule(value: progress)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 210)
        .background(Ink.surface)
        .overlay(Rectangle().strokeBorder(Ink.hairline, lineWidth: 1))
        .overlay(alignment: .top) {
            LinearGradient(colors: [Ink.signal, Ink.signal.opacity(0)], startPoint: .leading, endPoint: .trailing)
                .frame(height: 2)
        }
    }
}

/// Numbered row used in the profile's founded list.
struct FoundedRow: View {
    let index: Int
    let labyrinth: Labyrinth

    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    MonoLabel(text: String(format: "%03d", index), size: 10, color: Ink.faint)
                    Spacer()
                    Chip(text: labyrinth.priceLabel, accent: labyrinth.price != nil)
                }
                Display(text: labyrinth.name, size: 17)
                Text(labyrinth.tagline)
                    .font(.system(size: 13))
                    .foregroundStyle(Ink.muted)
                    .lineLimit(3)
                HStack(spacing: 16) {
                    MonoLabel(text: labyrinth.durationLabel, size: 9, color: Ink.faint, icon: "clock")
                    MonoLabel(text: labyrinth.level, size: 9, color: Ink.faint, icon: "chevron.left.forwardslash.chevron.right")
                    Spacer()
                    MonoLabel(text: "\(labyrinth.memberCount)", size: 9, color: Ink.faint, icon: "person.2")
                }
            }
        }
    }
}
