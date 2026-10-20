import SwiftUI

struct TrainingLibraryView: View {
    @Environment(AppState.self) private var state
    @State private var filter = "All"
    @State private var query = ""
    private var programs: [Labyrinth] {
        state.library.filter { program in
            let matches = filter == "All" || (filter == "My workouts" && program.isPersonal == true)
                || (filter == "Joined" && state.isMember(of: program) && !state.isOwner(of: program))
                || (filter == "Created" && state.isOwner(of: program) && program.isPersonal != true)
            return matches && (query.isEmpty || program.name.localizedCaseInsensitiveContains(query))
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Menu {
                    Picker("Show", selection: $filter) {
                        ForEach(["All", "My workouts", "Joined", "Created"], id: \.self) { Text($0).tag($0) }
                    }
                } label: {
                    Label(filter, systemImage: "line.3.horizontal.decrease").font(.headline).frame(minHeight: 44)
                }.accessibilityIdentifier("libraryFilter")
                if programs.isEmpty {
                    ContentUnavailableView("No workouts here yet", systemImage: "square.stack", description: Text("Try another filter, or find and build workouts from Home."))
                }
                ForEach(programs) { program in
                    NavigationLink { LabyrinthDetailView(labyrinthID: program.id) } label: { ProgramRow(program: program) }
                        .buttonStyle(PressStyle())
                }
            }.padding(20)
        }.background(Ink.canvas).foregroundStyle(Ink.text)
            .navigationTitle("Your training").navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Find a workout in your library")
    }
}

/// A short, literal route through the plan—not a decorative progress score.
struct TrainingPath: View {
    @Environment(AppState.self) private var state
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    let program: Labyrinth
    private var current: Int { state.membership(for: program)?.currentDay ?? 1 }
    private var visibleDays: [ProgramDay] {
        let index = program.days.firstIndex { $0.number == current } ?? 0
        let start = min(max(0, index - 1), max(0, program.days.count - 4))
        return Array(program.days.dropFirst(start).prefix(4))
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(program.programFormat == .ongoing ? "Your repeating path" : "Your path").font(.subheadline.weight(.semibold))
                Spacer()
                if program.programFormat == .ongoing { Image(systemName: "repeat").accessibilityLabel("Repeats after the last day") }
            }
            if typeSize.isAccessibilitySize {
                ForEach(visibleDays) { day in
                    let complete = state.membership(for: program)?.completedDays.contains(day.number) == true
                    Label("Day \(day.number): \(complete ? "complete" : day.number == current ? "next" : "upcoming")", systemImage: complete ? "checkmark.circle.fill" : day.number == current ? "location.circle.fill" : "circle")
                        .font(.body).foregroundStyle(day.number == current ? Ink.signalSoft : Ink.muted)
                }
            } else {
            HStack(spacing: 0) {
                ForEach(Array(visibleDays.enumerated()), id: \.element.id) { index, day in
                    let complete = state.membership(for: program)?.completedDays.contains(day.number) == true
                    VStack(spacing: 7) {
                        ZStack {
                            RoutePanelShape(cut: 6).fill(complete ? Ink.text : day.number == current ? Ink.signal : Ink.raised).frame(width: 32, height: 32)
                            if complete { Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(Ink.inverse) }
                            else { Text("\(day.number)").font(.caption.bold()).foregroundStyle(day.number == current ? .white : Ink.muted) }
                        }
                        Text(day.isRest ? "Rest" : "Day \(day.number)").font(.caption).foregroundStyle(Ink.muted)
                    }.accessibilityElement(children: .ignore)
                        .accessibilityLabel("Day \(day.number), \(day.title), \(complete ? "complete" : day.number == current ? "next in plan" : "upcoming")")
                    if index + 1 < visibleDays.count {
                        Rectangle().fill(complete ? Ink.text.opacity(0.65) : Ink.raised).frame(height: 2).padding(.horizontal, 8).padding(.bottom, 23).accessibilityHidden(true)
                    }
                }
            }.animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: current)
            }
            Text(state.isComplete(program) ? "Path complete. You can revisit any workout." : program.programFormat == .ongoing ? "Finish the sequence, then return to day one." : "Day \(current) of \(program.days.count). One session at a time.")
                .font(.caption).foregroundStyle(Ink.muted)
        }.foregroundStyle(Ink.text)
    }
}
