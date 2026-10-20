import SwiftUI

enum TrainingType {
    static let display = Font.custom("AvenirNext-DemiBold", size: 32, relativeTo: .largeTitle)
    static let section = Font.custom("AvenirNext-DemiBold", size: 23, relativeTo: .title2)
    static let title = Font.custom("AvenirNext-DemiBold", size: 20, relativeTo: .title3)
    static let number = Font.custom("AvenirNext-Medium", size: 32, relativeTo: .largeTitle)
}

/// Opposing corner cuts suggest a route changing direction. Insets keep text clear of the cuts.
struct RoutePanelShape: Shape {
    var cut: CGFloat = 12
    func path(in rect: CGRect) -> Path {
        let c = min(cut, min(rect.width, rect.height) / 3)
        return Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - c, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + c))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + c, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - c))
            path.closeSubpath()
        }
    }
}

struct RouteSurface: ViewModifier {
    var fill: Color = Ink.surface
    var highlighted = false
    func body(content: Content) -> some View {
        content.background(fill, in: RoutePanelShape(cut: 16))
            .overlay(alignment: .topLeading) {
                if highlighted {
                    Rectangle().fill(Ink.signal).frame(width: 44, height: 3).padding(.leading, 20).accessibilityHidden(true)
                }
            }
    }
}

/// A single glass focal surface for the current workout, matching the native tab material.
struct TodayGlass: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var scheme
    var scrollOffset: CGFloat = 0

    private var opaque: Bool { reduceTransparency || contrast == .increased }
    private var lightPosition: CGFloat { reduceMotion ? 0 : min(1, max(-0.3, scrollOffset / 420)) }
    private var shape: RoutePanelShape { RoutePanelShape(cut: 16) }

    func body(content: Content) -> some View {
        content.background {
            ZStack {
                if opaque {
                    shape.fill(Ink.surface)
                } else {
                    glass
                }
            }.allowsHitTesting(false).accessibilityHidden(true)
        }
        .overlay {
            if !opaque {
                GeometryReader { geometry in
                    ZStack {
                        // Broad, soft refraction is visible only inside the narrow glass rim.
                        RadialGradient(colors: [.white.opacity(scheme == .dark ? 0.38 : 0.70), .white.opacity(0.10), .clear],
                            center: UnitPoint(x: 0.12 + lightPosition * 0.76, y: 0),
                            startRadius: 0, endRadius: geometry.size.width * 0.65)
                        RadialGradient(colors: [.white.opacity(scheme == .dark ? 0.28 : 0.60), .clear],
                            center: UnitPoint(x: 0.88 - lightPosition * 0.70, y: 1),
                            startRadius: 0, endRadius: geometry.size.width * 0.55)
                    }
                    .mask(shape.stroke(lineWidth: 7).blur(radius: 1.2))
                    .overlay {
                        // A small sharp glint sits inside the soft lens; unlit edges stay clear.
                        shape.stroke(
                            LinearGradient(stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .white.opacity(scheme == .dark ? 0.72 : 0.95), location: 0.18),
                                .init(color: .white.opacity(0.03), location: 0.43),
                                .init(color: .clear, location: 0.60),
                                .init(color: .white.opacity(scheme == .dark ? 0.38 : 0.72), location: 0.84),
                                .init(color: .clear, location: 1)
                            ], startPoint: UnitPoint(x: -0.3 + lightPosition * 0.7, y: 0),
                               endPoint: UnitPoint(x: 0.7 + lightPosition * 0.7, y: 1)), lineWidth: 0.85)
                            .padding(0.75)
                    }
                }
                .clipShape(shape)
                .transaction { $0.animation = nil }
                .allowsHitTesting(false).accessibilityHidden(true)
            }
        }
        .overlay(alignment: .topLeading) {
            Rectangle().fill(Ink.signal).frame(width: 44, height: 3).padding(.leading, 20)
                .allowsHitTesting(false).accessibilityHidden(true)
        }
    }

    @ViewBuilder private var glass: some View {
        if #available(iOS 26.0, *) {
            shape.fill(.clear)
                .glassEffect(.regular.tint(Ink.surface.opacity(0.12)), in: shape)
        } else {
            shape.fill(.regularMaterial)
                .overlay(shape.fill(Ink.surface.opacity(0.15)))
        }
    }
}

/// Material is limited to transient controls and photo overlays, with a legible opaque fallback.
struct RestrainedGlass: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    var cut: CGFloat = 12
    func body(content: Content) -> some View {
        content.background {
            if reduceTransparency || contrast == .increased {
                RoutePanelShape(cut: cut).fill(Ink.surface)
            } else {
                RoutePanelShape(cut: cut).fill(.regularMaterial)
                    .overlay(RoutePanelShape(cut: cut).fill(Ink.surface.opacity(0.22)))
            }
        }
        .overlay {
            RoutePanelShape(cut: cut).stroke(Ink.glassEdge.opacity(0.65), lineWidth: 0.75)
                .clipShape(RoutePanelShape(cut: cut))
        }
    }
}

struct ArchitecturalCanvas: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            ZStack {
                Ink.canvas
                Path { path in
                    path.move(to: CGPoint(x: width * 0.58, y: 0))
                    path.addLine(to: CGPoint(x: width, y: 0))
                    path.addLine(to: CGPoint(x: width, y: height * 0.52))
                    path.closeSubpath()
                }.fill(Ink.facet)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height * 0.70))
                    path.addLine(to: CGPoint(x: width * 0.32, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()
                }.fill(Ink.facet.opacity(0.55))
            }
        }.ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
    }
}
