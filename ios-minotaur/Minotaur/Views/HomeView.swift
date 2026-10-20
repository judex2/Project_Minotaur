import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dynamicTypeSize) private var typeSize
    var onExplore: () -> Void = {}
    @State private var path: [Labyrinth] = []
    @State private var showBuilder = false
    @State private var showSchedule = false
    @State private var showWorkout = false
    @State private var glassScrollOffset: CGFloat = 0

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    BrandHeader()
                    VStack(alignment: .leading, spacing: 8) {
                        Text(state.library.isEmpty ? "Your next move." : "Make it your time.").font(TrainingType.display).tracking(-0.9)
                        if !typeSize.isAccessibilitySize {
                            Text("A little stronger. A little more you.").font(.body).foregroundStyle(Ink.muted)
                        }
                    }
                    if !state.library.isEmpty { today }
                    VStack(spacing: 10) {
                        if state.library.isEmpty {
                        action("Find a plan", subtitle: "Training that fits your goals", icon: "safari", primary: true, action: onExplore)
                            .accessibilityIdentifier("findPlan")
                        action("Build my workout", subtitle: "Your exercises. Your pace.", icon: "plus", primary: false) { showBuilder = true }
                            .accessibilityIdentifier("buildWorkout")
                        } else {
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 12) { quickActions }
                                VStack(spacing: 12) { quickActions }
                            }.font(.subheadline.weight(.semibold)).buttonStyle(PressStyle())
                        }
                    }
                    if state.library.isEmpty { today }
                    if !state.library.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                SectionTitle(title: "Your Labyrinths")
                                Spacer()
                                NavigationLink { TrainingLibraryView() } label: { Text("See all").font(.subheadline.weight(.semibold)).frame(minHeight: 44) }
                                    .accessibilityIdentifier("allTraining")
                            }
                            ForEach(state.library.prefix(4)) { program in
                                Button { path.append(program) } label: { ProgramRow(program: program) }
                                    .buttonStyle(PressStyle())
                            }
                        }
                    }
                    if !state.hypedTransformations.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionTitle(title: "Progress worth sharing", subtitle: "Real people. Shared momentum.")
                            ForEach(state.hypedTransformations.prefix(2)) { post in
                                if let program = state.labyrinths.first(where: { $0.id == post.labyrinthID }) {
                                    Button { path.append(program) } label: {
                                        TransformationCard(post: post, labyrinth: program, width: nil)
                                    }.buttonStyle(PressStyle())
                                }
                            }
                        }
                    }
                }
                .padding(20).padding(.bottom, 20)
            }
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                ((geometry.contentOffset.y + geometry.contentInsets.top) * 2).rounded() / 2
            } action: { _, offset in
                glassScrollOffset = offset
            }
            .background(ArchitecturalCanvas()).foregroundStyle(Ink.text)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Labyrinth.self) { LabyrinthDetailView(labyrinthID: $0.id) }
            .sheet(isPresented: $showSchedule) { ScheduleEditor().environment(state) }
            .fullScreenCover(isPresented: $showBuilder) {
                LabyrinthBuilderView(personal: true) { program in
                    state.createLabyrinth(program); showBuilder = false; path.append(program)
                }.environment(state)
            }
            .fullScreenCover(isPresented: $showWorkout) {
                if let program = state.scheduledProgram, let day = state.scheduledDay {
                    ActiveWorkoutView(labyrinth: program, day: day).environment(state)
                }
            }
        }
    }

    @ViewBuilder private var quickActions: some View {
        Button(action: onExplore) { Label("Find a plan", systemImage: "safari").frame(maxWidth: .infinity, minHeight: 50).padding(.horizontal, 12).background(Ink.surface, in: RoundedRectangle(cornerRadius: 16)) }
            .accessibilityIdentifier("findPlan")
        Button { showBuilder = true } label: { Label("Build workout", systemImage: "plus").frame(maxWidth: .infinity, minHeight: 50).padding(.horizontal, 12).background(Ink.surface, in: RoundedRectangle(cornerRadius: 16)) }
            .accessibilityIdentifier("buildWorkout")
    }

    private func action(_ title: String, subtitle: String, icon: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if !typeSize.isAccessibilitySize { Image(systemName: icon).font(.title2.weight(.semibold)).frame(width: 30) }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.subheadline).opacity(primary ? 0.92 : 0.75)
                }
                Spacer(minLength: 4)
                if !typeSize.isAccessibilitySize { Image(systemName: "arrow.up.right").font(.body.weight(.semibold)) }
            }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(primary ? .white : Ink.text)
                .background(primary ? Ink.signal : Ink.surface, in: RoutePanelShape(cut: 14))
        }.buttonStyle(PressStyle())
    }

    private var today: some View {
        VStack(alignment: .leading, spacing: 14) {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) { todayHeading }
            } else {
                HStack { todayHeading }
            }
            if let program = state.scheduledProgram, let day = state.scheduledDay {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 14) {
                        if !typeSize.isAccessibilitySize {
                        Image(systemName: day.isRest ? "leaf" : "figure.strengthtraining.traditional")
                            .font(.title2).foregroundStyle(Ink.signalSoft)
                            .frame(width: 48, height: 48).background(Ink.signalWash, in: RoutePanelShape(cut: 9))
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            Text(day.title).font(TrainingType.title)
                            Text(program.name).font(.subheadline).foregroundStyle(Ink.muted)
                            Text(day.isRest ? "Recovery is part of the plan." : "\(day.exerciseSummary) · About \(day.estimatedMinutes) min")
                                .font(.caption).foregroundStyle(Ink.muted)
                        }
                    }
                    if !day.isRest {
                        SlabButton(title: "Start workout", accent: true) { showWorkout = true }
                            .accessibilityIdentifier("startToday")
                    }
                    TrainingPath(program: program)
                }.padding(20).modifier(TodayGlass(scrollOffset: glassScrollOffset))
            } else {
                EmptyState(icon: "sun.max", title: state.todaySlot != nil ? "Room to recover" : "Make room for movement",
                           message: state.todaySlot != nil ? "You’ve planned a rest day. Your next session will be here when you’re ready." : "Find a plan or build a workout. Your next session will appear here.")
            }
        }
    }
    @ViewBuilder private var todayHeading: some View {
        SectionTitle(title: "Today")
        if !typeSize.isAccessibilitySize { Spacer() }
        Button("Schedule") { showSchedule = true }.font(.subheadline.weight(.semibold)).frame(minHeight: 44)
    }
}
