import Combine
import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    let labyrinth: Labyrinth
    let day: ProgramDay
    @State private var index = 0
    @State private var completedSets: [UUID: Int] = [:]
    @State private var elapsed = 0
    @State private var accumulated = 0
    @State private var startedAt = Date()
    @State private var running = true
    @State private var restRemaining = 0
    @State private var restDeadline: Date?
    @State private var customRest: [UUID: Int] = [:]
    @State private var showRestSettings = false
    @State private var showFinish = false
    @State private var showExit = false
    @State private var showShare = false
    @State private var savedRecord: WorkoutRecord?
    @State private var saved = false
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var block: ExerciseBlock? { day.blocks.indices.contains(index) ? day.blocks[index] : nil }
    private var totalSets: Int { day.blocks.reduce(0) { $0 + $1.sets } }
    private var doneSets: Int { completedSets.values.reduce(0, +) }
    private var fraction: Double { totalSets == 0 ? 1 : Double(doneSets) / Double(totalSets) }
    private var readingLayout: AnyLayout {
        typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12)) : AnyLayout(HStackLayout(spacing: 18))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    readingLayout {
                        Label(clock(elapsed), systemImage: "clock").font(.subheadline.weight(.semibold)).monospacedDigit()
                        if !typeSize.isAccessibilitySize { Spacer() }
                        Button(running ? "Pause" : "Resume", systemImage: running ? "pause.fill" : "play.fill") { toggleTimer() }
                            .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                    }.foregroundStyle(Ink.muted)
                    VStack(alignment: .leading, spacing: 10) {
                        readingLayout {
                            Text(day.title).font(.subheadline).foregroundStyle(Ink.muted)
                            if !typeSize.isAccessibilitySize { Spacer() }
                            Text("\(doneSets) / \(totalSets) sets").font(.caption.bold()).foregroundStyle(Ink.signalSoft)
                        }
                        ProgressView(value: min(1, fraction)).tint(Ink.signal)
                    }
                    if let block {
                        exercise(block)
                    } else {
                        EmptyState(icon: "leaf", title: "Take a breath.", message: "A little movement, some recovery, and time to recharge.")
                    }
                    if !day.notes.isEmpty {
                        Label { Text(day.notes) } icon: { Image(systemName: "info.circle") }
                            .font(.subheadline).foregroundStyle(Ink.muted)
                    }
                    if let media = day.media, !media.isEmpty {
                        GuidanceMediaGallery(media: media, height: 200).clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    if !day.blocks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionTitle(title: "Your session")
                            ForEach(Array(day.blocks.enumerated()), id: \.element.id) { number, exercise in
                                Button { changeExercise(number) } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: completedSets[exercise.id, default: 0] >= exercise.sets ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(completedSets[exercise.id, default: 0] >= exercise.sets ? Ink.success : Ink.muted)
                                        Text(exercise.name).font(.subheadline.weight(number == index ? .bold : .regular))
                                        Spacer()
                                        Text("\(completedSets[exercise.id, default: 0])/\(exercise.sets)").font(.caption).monospacedDigit()
                                    }.foregroundStyle(Ink.text).frame(minHeight: 48).contentShape(Rectangle())
                                }.buttonStyle(.plain)
                            }
                        }.padding(18).background(Ink.surface, in: RoundedRectangle(cornerRadius: 20))
                    }
                    Button(doneSets == totalSets ? "Finish workout" : "Finish early") {
                        if doneSets == totalSets { finish() } else { showFinish = true }
                    }.font(.headline).frame(maxWidth: .infinity, minHeight: 48)
                        .accessibilityIdentifier("finishWorkout")
                }.padding(20)
            }.background(Ink.canvas).foregroundStyle(Ink.text)
                .navigationTitle("In your element").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showExit = true } label: { Image(systemName: "xmark") }.accessibilityLabel("Close workout")
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 0) {
                        if restRemaining > 0 { restCard.padding(.horizontal, 16).padding(.top, 8) }
                        if !typeSize.isAccessibilitySize || restRemaining == 0 { actionBar }
                    }.frame(maxWidth: .infinity).background(Ink.canvas)
                }
        }
        .onReceive(ticker) { _ in updateClock() }
        .confirmationDialog("Finish this session?", isPresented: $showFinish, titleVisibility: .visible) {
            Button("Save \(doneSets) completed sets") { finish() }
            Button("Keep training", role: .cancel) {}
        } message: { Text("Your completed sets will be saved. The program advances only when every set is complete.") }
        .confirmationDialog("Leave this workout?", isPresented: $showExit, titleVisibility: .visible) {
            if doneSets > 0 { Button("Save completed sets") { finish() } }
            Button("Discard session", role: .destructive) { running = false; dismiss() }
            Button("Keep training", role: .cancel) {}
        }
        .sheet(isPresented: $showRestSettings) {
            NavigationStack {
                Form {
                    if let block {
                        Section("Between sets") {
                            Stepper("\(customRest[block.id] ?? block.restSeconds) seconds",
                                    value: Binding(get: { customRest[block.id] ?? block.restSeconds }, set: { customRest[block.id] = $0 }),
                                    in: 0...900, step: 15)
                        }
                        Section { Text("This changes the rest time for this exercise in this session. The original plan stays the same.").foregroundStyle(Ink.muted) }
                    }
                }.navigationTitle("Your rest time").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showRestSettings = false } } }
            }.presentationDetents([.medium])
        }
        .sheet(isPresented: $showShare, onDismiss: { dismiss() }) {
            if let record = savedRecord {
                NavigationStack {
                    SessionDetailView(record: record, justFinished: true)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showShare = false } } }
                }.environment(state)
            }
        }
    }

    private func exercise(_ block: ExerciseBlock) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Exercise \(index + 1) of \(day.blocks.count)").font(.subheadline.weight(.medium)).foregroundStyle(Ink.signalSoft)
            Text(block.name).font(TrainingType.display).tracking(-0.9).fixedSize(horizontal: false, vertical: true)
            readingLayout {
                Label("\(block.sets) sets", systemImage: "square.stack")
                Text(block.targetLabel)
            }.font(.headline).foregroundStyle(Ink.muted)
            if let media = block.media, !media.isEmpty {
                GuidanceMediaGallery(media: media, height: 230).clipShape(RoundedRectangle(cornerRadius: 22))
            }
            if let note = block.note, !note.isEmpty {
                Text(note).font(.body).foregroundStyle(Ink.muted)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))], spacing: 10) {
                ForEach(0..<block.sets, id: \.self) { number in
                    let complete = number < completedSets[block.id, default: 0]
                    Button {
                        if complete { completedSets[block.id] = number; restRemaining = 0; restDeadline = nil }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: complete ? "checkmark" : "circle").font(.headline)
                            Text("\(number + 1)").font(.caption)
                        }.frame(maxWidth: .infinity, minHeight: 60)
                            .foregroundStyle(complete ? Ink.inverse : Ink.muted)
                            .background(complete ? Ink.text : Ink.raised, in: RoutePanelShape(cut: 8))
                    }.buttonStyle(PressStyle()).disabled(!complete)
                        .accessibilityLabel("Set \(number + 1), \(complete ? "complete, tap to undo" : "not complete")")
                }
            }
            Button { showRestSettings = true } label: {
                Label("\(customRest[block.id] ?? block.restSeconds)s rest · Adjust", systemImage: "timer")
                    .font(.subheadline).frame(minHeight: 44)
            }
        }
    }
    private var restCard: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) { restTime; restActions }
            } else {
                HStack(spacing: 18) { restTime; Spacer(); restActions }
            }
        }.padding(16).modifier(RestrainedGlass(cut: 14))
    }
    private var restTime: some View {
            VStack(alignment: .leading, spacing: 6) {
                if !typeSize.isAccessibilitySize { Text(running ? "Breathe. Reset." : "Rest paused").font(.subheadline.weight(.semibold)) }
                Text(clock(restRemaining)).font(TrainingType.number).monospacedDigit()
                    .accessibilityLabel("\(restRemaining) seconds of rest remaining\(running ? "" : ", paused")")
            }
    }
    private var restActions: some View {
            VStack(spacing: 8) {
                Button("+30 seconds") {
                    restRemaining += 30
                    if running { restDeadline = Date().addingTimeInterval(Double(restRemaining)) }
                }.frame(minHeight: 44)
                Button("Skip rest") { restRemaining = 0; restDeadline = nil }.frame(minHeight: 44)
            }.font(.subheadline.weight(.semibold))
    }
    private var actionBar: some View {
        HStack(spacing: 12) {
            if let block {
                if !typeSize.isAccessibilitySize {
                Button { changeExercise(max(0, index - 1)) } label: {
                    Image(systemName: "chevron.left").font(.headline).frame(width: 48, height: 54).background(Ink.raised, in: RoundedRectangle(cornerRadius: 16))
                }.disabled(index == 0).accessibilityLabel("Previous exercise")
                }
                if completedSets[block.id, default: 0] >= block.sets {
                    SlabButton(title: index + 1 < day.blocks.count ? "Next exercise" : "Finish workout", accent: true) {
                        if index + 1 < day.blocks.count { changeExercise(index + 1) }
                        else if doneSets == totalSets { finish() } else { showFinish = true }
                    }
                } else {
                    SlabButton(title: restRemaining > 0 ? "Resting…" : "\(typeSize.isAccessibilitySize ? "Log set" : "Complete set") \(completedSets[block.id, default: 0] + 1)", icon: "checkmark", accent: true) {
                        completedSets[block.id, default: 0] += 1
                        Haptics.success()
                        let seconds = completedSets[block.id, default: 0] >= block.sets
                            ? (block.transitionRestSeconds ?? block.restSeconds) : (customRest[block.id] ?? block.restSeconds)
                        restRemaining = seconds
                        restDeadline = seconds > 0 ? Date().addingTimeInterval(Double(seconds)) : nil
                    }.disabled(restRemaining > 0 || !running).opacity(restRemaining > 0 || !running ? 0.55 : 1)
                        .accessibilityIdentifier("completeSet")
                }
                if !typeSize.isAccessibilitySize {
                Button { changeExercise(min(day.blocks.count - 1, index + 1)) } label: {
                    Image(systemName: "chevron.right").font(.headline).frame(width: 48, height: 54).background(Ink.raised, in: RoundedRectangle(cornerRadius: 16))
                }.disabled(index + 1 >= day.blocks.count).accessibilityLabel("Next exercise")
                }
            } else {
                SlabButton(title: "Log recovery day", accent: true) { finish() }
            }
        }.padding(16).background(Ink.canvas)
    }
    private func changeExercise(_ value: Int) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { index = value }
    }
    private func updateClock() {
        guard running, !saved else { return }
        elapsed = accumulated + max(0, Int(Date().timeIntervalSince(startedAt)))
        if let deadline = restDeadline {
            restRemaining = max(0, Int(ceil(deadline.timeIntervalSinceNow)))
            if restRemaining == 0 { restDeadline = nil; Haptics.success() }
        }
    }
    private func toggleTimer() {
        if running { updateClock(); accumulated = elapsed; restDeadline = nil }
        else {
            startedAt = Date()
            if restRemaining > 0 { restDeadline = Date().addingTimeInterval(Double(restRemaining)) }
        }
        running.toggle()
    }
    private func finish() {
        guard !saved else { return }
        updateClock(); running = false; saved = true; restDeadline = nil
        let record = WorkoutRecord(labyrinthID: labyrinth.id, programName: labyrinth.name,
            workoutName: day.title, seconds: elapsed, completedSets: doneSets, totalSets: totalSets,
            daySnapshot: day, exerciseSets: Dictionary(uniqueKeysWithValues: completedSets.map { ($0.key.uuidString, $0.value) }))
        state.saveWorkout(record, day: day, program: labyrinth)
        savedRecord = record
        Haptics.success(); showShare = true
    }
    private func clock(_ seconds: Int) -> String { String(format: "%02d:%02d", seconds / 60, seconds % 60) }
}
