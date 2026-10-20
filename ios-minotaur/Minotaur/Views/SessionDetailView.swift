import SwiftUI

struct SessionDetailView: View {
    @Environment(AppState.self) private var state
    let record: WorkoutRecord
    var justFinished = false
    @State private var showShare = false
    private var program: Labyrinth? { state.labyrinths.first { $0.id == record.labyrinthID } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Label(record.isComplete ? "Workout complete" : "Session saved", systemImage: record.isComplete ? "checkmark.circle.fill" : "checkmark.circle")
                    .font(.headline).foregroundStyle(Ink.success)
                Text(justFinished ? (record.isComplete ? "You showed up.\nYou moved forward." : "Every set counts.") : record.workoutName)
                    .font(TrainingType.display).tracking(-0.9).fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: 6) {
                    if justFinished { Text(record.workoutName).font(.title3.bold()) }
                    if record.programName != record.workoutName { Text(record.programName).font(.subheadline).foregroundStyle(Ink.muted) }
                    Text(record.finishedAt, format: .dateTime.month(.wide).day().hour().minute()).font(.caption).foregroundStyle(Ink.muted)
                }
                HStack(spacing: 24) {
                    metric(record.durationLabel, "Time trained")
                    metric("\(record.completedSets)/\(record.totalSets)", "Sets completed")
                }.padding(20).background(Ink.surface, in: RoundedRectangle(cornerRadius: 20))
                if let day = record.daySnapshot {
                    if !day.blocks.isEmpty {
                        SectionTitle(title: "Your work")
                        ForEach(day.blocks) { block in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "dumbbell").foregroundStyle(Ink.blue).frame(width: 24)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(block.name).font(.headline)
                                    Text(block.targetLabel).font(.subheadline).foregroundStyle(Ink.muted)
                                }
                                Spacer()
                                Text("\(record.exerciseSets?[block.id.uuidString] ?? 0)/\(block.sets) sets").font(.subheadline).foregroundStyle(Ink.muted)
                            }
                        }
                    }
                } else {
                    Text("This earlier session has totals only. New sessions include an exercise breakdown.").font(.subheadline).foregroundStyle(Ink.muted)
                }
                if justFinished, let program {
                    if program.days.count > 1 { TrainingPath(program: program) }
                    if !record.isComplete {
                        Text("Your completed sets are saved. Your place in the plan hasn’t changed.").font(.subheadline).foregroundStyle(Ink.muted)
                    } else if let next = state.today(in: program), !state.isComplete(program) {
                        Label("Next in your plan: \(next.title)", systemImage: "arrow.turn.down.right").font(.subheadline)
                    }
                }
                if program != nil, record.daySnapshot != nil {
                    Button { showShare = true } label: {
                        Label("Share this session", systemImage: "square.and.arrow.up").font(.headline).frame(minHeight: 44)
                    }.accessibilityIdentifier("shareSession")
                }
            }.padding(24)
        }.background(Ink.canvas).foregroundStyle(Ink.text)
            .navigationTitle(justFinished ? "Session saved" : "Session details").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showShare) {
                if let program, let day = record.daySnapshot {
                    ShareLinkPreviewSheet(labyrinth: program, workout: WorkoutShareSummary(day: day, durationMinutes: max(1, record.seconds / 60), completedSets: record.completedSets, totalSets: record.totalSets), allowsCommunityPost: program.isPersonal != true && (state.isMember(of: program) || state.isOwner(of: program))).environment(state)
                }
            }
    }
    private func metric(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(.title.bold()).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(Ink.muted)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WorkoutHistoryView: View {
    @Environment(AppState.self) private var state
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                if state.history.isEmpty { ContentUnavailableView("Your next workout starts this story", systemImage: "clock", description: Text("Saved sessions will appear here.")) }
                ForEach(state.history) { record in
                    NavigationLink { SessionDetailView(record: record) } label: { SessionHistoryRow(record: record) }.buttonStyle(.plain)
                }
            }.padding(20)
        }.background(Ink.canvas).navigationTitle("Workout history").navigationBarTitleDisplayMode(.inline)
    }
}

struct SessionHistoryRow: View {
    let record: WorkoutRecord
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.isComplete ? "checkmark.circle.fill" : "circle.lefthalf.filled").foregroundStyle(Ink.success)
            VStack(alignment: .leading, spacing: 5) {
                Text(record.workoutName).font(.headline).foregroundStyle(Ink.text)
                Text("\(record.completedSets)/\(record.totalSets) sets · \(record.durationLabel)").font(.subheadline).foregroundStyle(Ink.muted)
                Text(record.finishedAt, format: .dateTime.month(.abbreviated).day()).font(.caption).foregroundStyle(Ink.muted)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Ink.muted)
        }.frame(minHeight: 60).contentShape(Rectangle())
    }
}
