import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct LabyrinthBuilderView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    let onSave: (Labyrinth) -> Void
    let personal: Bool
    let existing: Labyrinth?

    @State private var draft: LabyrinthDraft
    @State private var step = BuilderStep.details
    @State private var editingDayIndex: Int?
    @State private var bannerItem: PhotosPickerItem?
    @State private var mediaError: String?
    @State private var editingBlockDay: Int?
    @State private var editingBlockIndex = 0
    @State private var draftLoaded = false
    @State private var showClose = false
    @State private var pendingRemoval: UUID?
    @State private var confirmRemoveDay = false
    @AppStorage("labyrinthBuilderDraft") private var savedProgramDraft = Data()

    init(labyrinth: Labyrinth? = nil, personal: Bool = false, onSave: @escaping (Labyrinth) -> Void) {
        self.onSave = onSave
        self.personal = personal
        self.existing = labyrinth
        _draft = State(initialValue: labyrinth.map(LabyrinthDraft.init) ?? LabyrinthDraft())
    }

    var body: some View {
        if personal {
            PersonalWorkoutBuilder(existing: existing, onSave: onSave)
        } else { programBody }
    }

    private var programBody: some View {
        ZStack(alignment: .bottom) {
            Ink.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    progressHeader
                    stepContent
                    Color.clear.frame(height: 110)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

            actionBar
        }
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .onAppear {
            guard !draftLoaded else { return }
            if !draft.isEditing, let restored = try? JSONDecoder().decode(LabyrinthDraft.self, from: savedProgramDraft) { draft = restored }
            draftLoaded = true
        }
        .onChange(of: draft) { _, value in
            if draftLoaded, !value.isEditing, let data = try? JSONEncoder().encode(value) { savedProgramDraft = data }
        }
        .confirmationDialog(draft.isEditing ? "Discard unsaved edits?" : "Close the builder?", isPresented: $showClose, titleVisibility: .visible) {
            Button(draft.isEditing ? "Discard edits" : "Save draft and close") { dismiss() }
            if !draft.isEditing {
                Button("Discard draft", role: .destructive) { draftLoaded = false; savedProgramDraft = Data(); dismiss() }
            }
            Button("Keep editing", role: .cancel) {}
        }
        .confirmationDialog("Remove this exercise?", isPresented: Binding(get: { pendingRemoval != nil }, set: { if !$0 { pendingRemoval = nil } }), titleVisibility: .visible) {
            Button("Remove exercise", role: .destructive) {
                if let id = pendingRemoval { for index in draft.days.indices { draft.days[index].blocks.removeAll { $0.id == id } } }
                pendingRemoval = nil
            }
        }
        .confirmationDialog("Remove the last day and its exercises?", isPresented: $confirmRemoveDay, titleVisibility: .visible) {
            Button("Remove day", role: .destructive) { draft.removeLastDay() }
        }
        .sheet(isPresented: Binding(get: { editingBlockDay != nil }, set: { if !$0 { editingBlockDay = nil } })) {
            if let dayIndex = editingBlockDay, draft.days.indices.contains(dayIndex), draft.days[dayIndex].blocks.indices.contains(editingBlockIndex) {
                ExerciseEditor(block: $draft.days[dayIndex].blocks[editingBlockIndex])
            }
        }

        .alert("Media import failed", isPresented: Binding(
            get: { mediaError != nil },
            set: { if !$0 { mediaError = nil } }
        )) {
            Button("OK", role: .cancel) { mediaError = nil }
        } message: {
            Text(mediaError ?? "Please try another file.")
        }
        .sheet(isPresented: Binding(
            get: { editingDayIndex != nil },
            set: { if !$0 { editingDayIndex = nil } }
        )) {
            if let index = editingDayIndex, draft.days.indices.contains(index) {
                DaySettingsEditor(day: $draft.days[index])
                    .presentationBackground(Ink.canvas)
            }
        }
        .onChange(of: bannerItem) { _, item in
            guard let item else { return }
            Task {
                do {
                    let attachment = try await LocalMediaStore.importItem(item, forceKind: .image)
                    draft.cover = .file(attachment.relativePath)
                } catch {
                    mediaError = error.localizedDescription
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                Haptics.soft()
                showClose = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Ink.muted)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text(draft.isEditing ? "Edit Labyrinth" : "Create a Labyrinth")
                .font(.system(size: 14, weight: .black))
                .tracking(0)
                .foregroundStyle(Ink.signalSoft)
            Spacer()
            Text("\(step.rawValue + 1)/4")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(Ink.faint)
                .frame(width: 44)
        }
        .padding(.horizontal, 8)
        .background(Ink.canvas)
        .overlay(alignment: .bottom) { Rectangle().fill(Ink.hairline).frame(height: 1) }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            MonoLabel(text: step.kicker, size: 10, color: Ink.signalSoft)
            Display(text: step.title, size: 27)
            Text(step.subtitle)
                .font(.system(size: 13))
                .foregroundStyle(Ink.muted)
                .lineSpacing(4)
            ProgressRule(value: Double(step.rawValue + 1) / 4.0)
        }
    }

    @ViewBuilder private var stepContent: some View {
        switch step {
        case .details: detailsStep
        case .structure: structureStep
        case .workouts: workoutsStep
        case .review: reviewStep
        }
    }

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            BuilderField(title: "Name", text: $draft.name, placeholder: "e.g. Full body foundations")
            BuilderField(title: "Description", text: $draft.tagline,
                         placeholder: "Who is this plan for, and what will it help them do?", axis: .vertical)

            VStack(alignment: .leading, spacing: 10) {
                MonoLabel(text: "Banner image", size: 9, color: Ink.faint)
                PhotosPicker(selection: $bannerItem, matching: .images) {
                    ZStack {
                        if let cover = draft.cover, let image = cover.uiImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Ink.raised
                            VStack(spacing: 10) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 24, weight: .medium))
                                MonoLabel(text: "Choose banner", size: 10, color: Ink.text)
                            }
                        }
                    }
                    .foregroundStyle(Ink.signalSoft)
                    .frame(height: 170)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PressStyle())
            }

            VStack(spacing: 12) {
                Picker("Experience", selection: $draft.level) { ForEach(["Beginner", "Intermediate", "Advanced", "Open"], id: \.self) { Text($0) } }
                Picker("Goal", selection: $draft.goal) { ForEach(["Build muscle", "Get stronger", "Calisthenics", "General fitness"], id: \.self) { Text($0) } }
                Picker("Equipment", selection: $draft.equipment) { ForEach(["Gym", "Bodyweight", "Any"], id: \.self) { Text($0) } }
            }.pickerStyle(.menu)
            BuilderSegmentedControl(
                title: "Visibility",
                choices: ["Public", "Private"],
                selection: Binding(
                    get: { draft.isPublic ? 0 : 1 },
                    set: { draft.isPublic = $0 == 0 }
                )
            )
        }
    }

    private var structureStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            BuilderSegmentedControl(
                title: "Program type",
                choices: ["Fixed", "Ongoing"],
                selection: Binding(
                    get: { draft.format == .fixed ? 0 : 1 },
                    set: { index in
                        draft.format = index == 0 ? .fixed : .ongoing
                        draft.reconcileDays()
                    }
                )
            )

            Panel(padding: 16, fill: Ink.signalWash.opacity(0.35), borderColor: Ink.signalHairline) {
                VStack(alignment: .leading, spacing: 8) {
                    MonoLabel(text: draft.format.label, size: 10, color: Ink.signalSoft)
                    Text(draft.format == .fixed
                         ? "Build a weekly split that runs for a defined number of weeks."
                         : "Build a custom sequence of any length. After the final day, it loops back to Day 1.")
                        .font(.system(size: 13))
                        .foregroundStyle(Ink.muted)
                        .lineSpacing(3)
                }
            }

            if draft.format == .fixed && draft.isEditing {
                Text("You’re editing the full \(draft.days.count)-session sequence. Every existing workout is preserved. Reorder or duplicate sessions on the next screen.").font(.body).foregroundStyle(Ink.muted)
            } else if draft.format == .fixed {
                HStack(spacing: 12) {
                    BuilderNumberControl(title: "Weeks", value: $draft.weeks, range: 1...52)
                    BuilderNumberControl(title: "Days / week", value: Binding(
                        get: { draft.daysPerWeek },
                        set: { draft.daysPerWeek = $0; draft.reconcileDays() }
                    ), range: 1...7)
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        MonoLabel(text: "Cycle length", size: 9, color: Ink.faint)
                        Text("\(draft.days.count) \(draft.days.count == 1 ? "day" : "days")")
                            .font(.system(size: 22, weight: .black, design: .monospaced))
                            .foregroundStyle(Ink.text)
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Button {
                            if draft.days.last?.blocks.isEmpty == false { confirmRemoveDay = true } else { draft.removeLastDay() }
                        } label: {
                            Label("Remove", systemImage: "minus")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(draft.days.count > 1 ? Ink.muted : Ink.faint.opacity(0.35))
                                .padding(.horizontal, 10)
                                .frame(minHeight: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(PressStyle())
                        .disabled(draft.days.count <= 1)

                        Button {
                            draft.addDay()
                        } label: {
                            Label("Add day", systemImage: "plus")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .frame(minHeight: 44)
                                .background(Ink.signal, in: Capsule())
                        }
                        .buttonStyle(PressStyle())
                    }
                }
                .padding(16)
                .background(Ink.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Panel {
                VStack(alignment: .leading, spacing: 8) {
                    MonoLabel(text: "Next: workout blocks", size: 10, color: Ink.signalSoft)
                    Text("On the next screen, each day becomes a container for its exercise blocks. Sets, repetitions, and rest are programmed there.")
                        .font(.system(size: 13))
                        .foregroundStyle(Ink.muted)
                        .lineSpacing(3)
                }
            }
        }
    }

    private var workoutsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                MonoLabel(text: draft.format == .fixed ? "Program the split" : "Program the cycle",
                          size: 10, color: Ink.muted)
                Spacer()
                if draft.format == .ongoing {
                    Button { draft.addDay() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Ink.signalSoft)
                    }
                }
            }

            ForEach(Array(draft.days.enumerated()), id: \.element.id) { index, day in
                workoutBlockDay(index: index)
            }
        }
    }

    private func workoutBlockDay(index: Int) -> some View {
        let day = draft.days[index]
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    MonoLabel(text: "Day \(index + 1)", size: 9,
                              color: day.isRest ? Ink.faint : Ink.signalSoft)
                    Display(text: day.title, size: 18)
                    MonoLabel(text: day.isRest ? "Recovery day" : "\(day.exerciseSummary)",
                              size: 9, color: Ink.faint)
                }
                Spacer()
                Button { editingDayIndex = index } label: {
                    Label("Day settings", systemImage: "slider.horizontal.3")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Ink.text)
                        .padding(.horizontal, 10)
                        .frame(minHeight: 44)
                        .background(Ink.raised, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PressStyle())
            }

            if !day.isRest {
                ForEach(Array(day.blocks.enumerated()), id: \.element.id) { blockIndex, block in
                    workoutBlock(dayIndex: index, blockIndex: blockIndex, block: block)
                }
                SlabButton(title: "Add exercise", icon: "plus", filled: false) { addBlock(to: index) }
            }

            HStack(spacing: 8) {
                moveButton("arrow.up", enabled: index > 0) { draft.days.swapAt(index, index - 1); draft.renumberDays() }
                moveButton("arrow.down", enabled: index < draft.days.count - 1) { draft.days.swapAt(index, index + 1); draft.renumberDays() }
                Button { draft.duplicateDay(at: index) } label: {
                    Label("Duplicate day", systemImage: "plus.square.on.square")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Ink.muted)
                        .frame(maxWidth: .infinity).frame(minHeight: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }.buttonStyle(PressStyle())
            }
        }
        .padding(16)
        .background(Ink.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func workoutBlock(dayIndex: Int, blockIndex: Int, block: ExerciseBlock) -> some View {
        ExerciseBlockCard(block: block, position: blockIndex + 1, canMoveUp: blockIndex > 0,
            canMoveDown: blockIndex + 1 < draft.days[dayIndex].blocks.count, fill: Ink.raised,
            edit: { editingBlockDay = dayIndex; editingBlockIndex = blockIndex },
            moveUp: { draft.days[dayIndex].blocks.swapAt(blockIndex, blockIndex - 1) },
            moveDown: { draft.days[dayIndex].blocks.swapAt(blockIndex, blockIndex + 1) },
            remove: { pendingRemoval = block.id })
    }

    private func addBlock(to dayIndex: Int) {
        draft.days[dayIndex].blocks.append(ExerciseBlock(name: "New Exercise", target: "", sets: 3, reps: "10",
                                                         restSeconds: 60, note: nil, transitionRestSeconds: 0))
        editingBlockDay = dayIndex
        editingBlockIndex = draft.days[dayIndex].blocks.count - 1
    }

    private func moveButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(enabled ? Ink.muted : Ink.faint.opacity(0.35))
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!enabled)
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let cover = draft.cover {
                MediaBox(ref: cover, height: 190, dim: 0.15)
                    .overlay(alignment: .bottomLeading) {
                        Display(text: draft.displayName, size: 24, color: .white).padding(16)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Panel(padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    MonoLabel(text: draft.format.label, size: 10, color: Ink.signalSoft)
                    Display(text: draft.displayName, size: 22)
                    Text(draft.displayTagline)
                        .font(.system(size: 13))
                        .foregroundStyle(Ink.muted)
                    HStack(spacing: 8) {
                        Chip(text: draft.isPublic ? "Public" : "Private", accent: draft.isPublic)
                        Chip(text: draft.format == .ongoing ? "\(draft.days.count)-day cycle" : "\(draft.weeks) weeks")
                        Chip(text: "\(draft.days.count) \(draft.days.count == 1 ? "workout" : "workouts")")
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                MonoLabel(text: "Workout summary", size: 10, color: Ink.muted)
                ForEach(Array(draft.days.enumerated()), id: \.element.id) { index, day in
                    HStack {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(Ink.signalSoft)
                        Text(day.title)
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(Ink.text)
                        Spacer()
                        MonoLabel(text: day.isRest ? "Rest" : "\(day.exerciseSummary)", size: 8, color: Ink.faint)
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: 48)
                    .background(Ink.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            if step != .details {
                SlabButton(title: "Back", filled: false, height: 52) {
                    withAnimation(.easeOut(duration: 0.2)) { step = BuilderStep(rawValue: step.rawValue - 1) ?? .details }
                }.frame(width: 90)
            }
            SlabButton(title: step == .review ? (draft.isEditing ? "Save Changes" : "Create Labyrinth") : "Continue",
                       icon: step == .review ? "checkmark" : "arrow.right",
                       accent: true,
                       height: 52) {
                advance()
            }
            .opacity(canAdvance ? 1 : 0.45)
            .disabled(!canAdvance)
        }
        .padding(16)
        .background(Ink.canvas)
        .overlay(alignment: .top) { Rectangle().fill(Ink.hairline).frame(height: 1) }
    }

    private var canAdvance: Bool {
        switch step {
        case .details: return !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .structure: return !draft.days.isEmpty
        case .workouts: return draft.days.allSatisfy { $0.recovery == true || !$0.blocks.isEmpty }
        case .review: return true
        }
    }

    private func advance() {
        Haptics.tap()
        if step == .review {
            Haptics.success()
            draftLoaded = false
            savedProgramDraft = Data()
            onSave(draft.makeLabyrinth(owner: state.user))
        } else {
            if step == .structure { draft.reconcileDays() }
            withAnimation(.easeOut(duration: 0.2)) {
                step = BuilderStep(rawValue: step.rawValue + 1) ?? .review
            }
        }
    }
}

private enum BuilderStep: Int, CaseIterable {
    case details, structure, workouts, review

    var kicker: String { ["Basics", "Schedule", "Workout blocks", "Ready to go"][rawValue] }
    var title: String { ["Make it yours", "Find your rhythm", "Build your workouts", "One final look"][rawValue] }
    var subtitle: String {
        [
            "Give the Labyrinth a clear identity and a visual banner.",
            "Choose a fixed weekly split or a custom sequence that repeats indefinitely.",
            "Add workout and recovery days, then program exercises, rests, notes, photos, and clips.",
            "Confirm the sequence before saving it locally."
        ][rawValue]
    }
}

nonisolated struct LabyrinthDraft: Codable, Equatable {
    var original: Labyrinth?
    var name = ""
    var tagline = ""
    var cover: PhotoRef?
    var isPublic = true
    var level = "Beginner"
    var goal = "General fitness"
    var equipment = "Any"
    var format: ProgramFormat = .fixed
    var weeks = 8
    var daysPerWeek = 3
    var days: [ProgramDay] = (1...3).map { LabyrinthDraft.blankDay(number: $0) }

    var isEditing: Bool { original != nil }

    init() {}

    init(_ labyrinth: Labyrinth) {
        original = labyrinth
        name = labyrinth.name
        tagline = labyrinth.tagline
        cover = labyrinth.cover
        isPublic = labyrinth.isPublic
        level = labyrinth.level
        goal = labyrinth.goal ?? "General fitness"
        equipment = labyrinth.equipment ?? "Any"
        format = labyrinth.programFormat
        weeks = max(1, labyrinth.weeks)
        daysPerWeek = max(1, labyrinth.daysPerWeek)
        days = labyrinth.days
        if days.isEmpty { days = [Self.blankDay(number: 1)] }
        renumberDays()
    }

    var displayName: String { name.isEmpty ? "Untitled Labyrinth" : name }
    var displayTagline: String { tagline.isEmpty ? "A workout plan, at your pace." : tagline }

    mutating func reconcileDays() {
        guard format == .fixed && original == nil else {
            if days.isEmpty { days = [Self.blankDay(number: 1)] }
            renumberDays()
            return
        }
        while days.count < daysPerWeek { days.append(Self.blankDay(number: days.count + 1)) }
        if days.count > daysPerWeek { days = Array(days.prefix(daysPerWeek)) }
        renumberDays()
    }

    mutating func addDay() {
        days.append(Self.blankDay(number: days.count + 1))
    }

    mutating func removeLastDay() {
        guard days.count > 1 else { return }
        days.removeLast()
        renumberDays()
    }

    mutating func duplicateDay(at index: Int) {
        guard days.indices.contains(index) else { return }
        var copy = days[index]
        copy.id = UUID()
        copy.blocks = copy.blocks.map { block in
            var copyBlock = block
            copyBlock.id = UUID()
            return copyBlock
        }
        days.insert(copy, at: index + 1)
        if format == .fixed && original == nil { daysPerWeek = days.count }
        renumberDays()
    }

    mutating func renumberDays() {
        for index in days.indices {
            days[index].number = index + 1
            days[index].weekday = "Day \(index + 1)"
        }
        if format == .fixed && original == nil { daysPerWeek = days.count }
    }

    func makeLabyrinth(owner: UserProfile) -> Labyrinth {
        let programmedDays: [ProgramDay]
        if format == .ongoing || original != nil {
            programmedDays = numberedCopies(of: days)
        } else {
            let expanded = (0..<weeks).flatMap { _ in days }
            programmedDays = numberedCopies(of: expanded)
        }

        return Labyrinth(
            id: original?.id ?? UUID(),
            name: displayName,
            ownerName: owner.name,
            ownerHandle: owner.handle,
            ownerAvatar: owner.avatar,
            tagline: displayTagline,
            cover: cover,
            weeks: format == .fixed ? weeks : 0,
            daysPerWeek: format == .fixed ? daysPerWeek : days.count,
            level: level,
            category: original?.category ?? "Custom",
            price: original?.price,
            memberCount: original?.memberCount ?? 0,
            official: original?.official ?? false,
            isPublic: isPublic,
            dmEnabled: original?.dmEnabled ?? true,
            days: programmedDays,
            format: format,
            goal: goal,
            equipment: equipment,
            isPersonal: original?.isPersonal
        )
    }

    private func numberedCopies(of source: [ProgramDay]) -> [ProgramDay] {
        source.enumerated().map { index, original in
            var day = original
            day.id = UUID()
            day.number = index + 1
            day.weekday = "Day \(index + 1)"
            day.blocks = (day.isRest ? [] : day.blocks).map { block in
                var copied = block
                copied.id = UUID()
                return copied
            }
            return day
        }
    }

    static func blankDay(number: Int) -> ProgramDay {
        ProgramDay(number: number, weekday: "Day \(number)", title: "Workout \(number)",
                   notes: "", estimatedMinutes: 45, blocks: [], recovery: false)
    }
}

private struct ExerciseEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var block: ExerciseBlock
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var mediaError: String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Ink.canvas.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        BuilderField(title: "Exercise", text: $block.name, placeholder: "e.g. Dumbbell bench press")
                        BuilderField(title: "Target", text: $block.target, placeholder: "e.g. Chest / triceps")
                        Picker("Measure exercise by", selection: Binding(get: { block.measurement }, set: { block.measure = $0 })) {
                            ForEach(ExerciseMeasure.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }.pickerStyle(.segmented).accessibilityIdentifier("exerciseMeasure")
                        BuilderNumberControl(title: "Sets", value: $block.sets, range: 1...20)
                        BuilderField(title: block.measurement.rawValue, text: $block.reps, placeholder: block.measurement.prompt)
                        if block.measurement != .reps {
                            Text(block.measurement == .time ? "Include a unit, such as 30 sec or 2 min. Numbers alone mean seconds." : "Include a unit, such as 400 m or 2 miles. Numbers alone mean meters.")
                                .font(.caption).foregroundStyle(Ink.muted)
                        }

                        RestSelector(title: "Rest between sets", seconds: $block.restSeconds, allowsNone: false)
                        RestSelector(title: "Transition after exercise", seconds: Binding(
                            get: { block.transitionRestSeconds ?? 0 },
                            set: { block.transitionRestSeconds = $0 }
                        ), allowsNone: true)

                        BuilderField(title: "Coaching comment", text: Binding(
                            get: { block.note ?? "" }, set: { block.note = $0.isEmpty ? nil : $0 }
                        ), placeholder: "Technique cues or a helpful variation", axis: .vertical)

                        GuidanceMediaPicker(title: "Exercise guidance", media: Binding(
                            get: { block.media ?? [] },
                            set: { block.media = $0.isEmpty ? nil : $0 }
                        ), pickerItems: $pickerItems, error: $mediaError)
                        Color.clear.frame(height: 80)
                    }
                    .padding(20)
                }
                SlabButton(title: "Save exercise", accent: true, height: 52) { dismiss() }
                    .padding(16)
                    .background(Ink.canvas)
            }
            .navigationTitle("Exercise")
            .navigationBarTitleDisplayMode(.inline)

            .toolbarBackground(Ink.canvas, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .alert("Media import failed", isPresented: Binding(
            get: { mediaError != nil }, set: { if !$0 { mediaError = nil } }
        )) { Button("OK", role: .cancel) {} } message: { Text(mediaError ?? "Please try another file.") }
    }
}

private struct RestSelector: View {
    let title: String
    @Binding var seconds: Int
    var allowsNone: Bool
    private let presets = [30, 45, 60, 90, 120, 180, 300]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                MonoLabel(text: title, size: 9, color: Ink.faint)
                Spacer()
                Text(seconds == 0 ? "NONE" : "\(seconds) SEC")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(Ink.signalSoft)
            }
            ScrollView(.horizontal) {
                HStack(spacing: 7) {
                    if allowsNone { presetButton(0, label: "NONE") }
                    ForEach(presets, id: \.self) { value in presetButton(value, label: restLabel(value)) }
                }
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            HStack {
                MonoLabel(text: "Custom seconds", size: 9, color: Ink.faint)
                Spacer()
                Button { seconds = max(allowsNone ? 0 : 5, seconds - 5) } label: { Image(systemName: "minus") }
                Text("\(seconds)")
                    .font(.system(size: 15, weight: .black, design: .monospaced))
                    .frame(width: 52)
                Button { seconds = min(900, seconds + 5) } label: { Image(systemName: "plus") }
            }
            .foregroundStyle(Ink.text)
            .padding(.horizontal, 12)
            .frame(height: 42)
            .background(Ink.raised)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func presetButton(_ value: Int, label: String) -> some View {
        Button { seconds = value } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(seconds == value ? .white : Ink.muted)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(seconds == value ? Ink.signal : Color.clear)
                .overlay(Rectangle().strokeBorder(seconds == value ? Ink.signalSoft : Ink.hairline, lineWidth: 1))
        }
        .buttonStyle(PressStyle())
    }

    private func restLabel(_ value: Int) -> String {
        value >= 60 && value % 60 == 0 ? "\(value / 60)M" : "\(value)S"
    }
}

private struct GuidanceMediaPicker: View {
    let title: String
    @Binding var media: [MediaAttachment]
    @Binding var pickerItems: [PhotosPickerItem]
    @Binding var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                MonoLabel(text: title, size: 9, color: Ink.faint)
                Spacer()
                PhotosPicker(selection: $pickerItems, maxSelectionCount: 6,
                             matching: .any(of: [.images, .videos])) {
                    Label("ADD MEDIA", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Ink.signalSoft)
                }
            }

            if media.isEmpty {
                Text("Add photos or uploaded clips for technique and coaching guidance.")
                    .font(.system(size: 12))
                    .foregroundStyle(Ink.faint)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Ink.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                ForEach(media.indices, id: \.self) { index in
                    let attachment = media[index]
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 12) {
                            if let image = attachment.uiImage {
                                Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
                                    .frame(width: 54, height: 54).clipped()
                            } else {
                                Image(systemName: "play.rectangle.fill")
                                    .font(.system(size: 22)).foregroundStyle(Ink.signalSoft)
                                    .frame(width: 54, height: 54).background(Ink.raised)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                MonoLabel(text: attachment.kind == .video ? "Uploaded clip" : "Guidance photo",
                                          size: 9, color: Ink.text)
                                Text(attachment.fileURL.lastPathComponent)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(Ink.faint)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Button { media.remove(at: index) } label: {
                                Image(systemName: "trash").foregroundStyle(Ink.signalSoft)
                            }
                        }

                        TextField("Add a short caption or context…", text: Binding(
                            get: { media[index].caption ?? "" },
                            set: { media[index].caption = $0.isEmpty ? nil : $0 }
                        ), axis: .vertical)
                        .font(.system(size: 12))
                        .foregroundStyle(Ink.text)
                        .lineLimit(1...3)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .background(Ink.raised)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(10)
                    .background(Ink.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task {
                do {
                    let imported = try await LocalMediaStore.importItems(items)
                    media.append(contentsOf: imported)
                    pickerItems = []
                } catch {
                    self.error = error.localizedDescription
                }
            }
        }
    }
}

private struct BuilderField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MonoLabel(text: title, size: 9, color: Ink.faint)
            TextField(title, text: $text, prompt: Text(placeholder).foregroundColor(Ink.faint), axis: axis)
                .font(.body)
                .accessibilityLabel(title)
                .foregroundStyle(Ink.text)
                .lineLimit(axis == .vertical ? 3...6 : 1...1)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .frame(minHeight: axis == .vertical ? 86 : 44, alignment: .topLeading)
                .background(Ink.raised)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .frame(maxWidth: .infinity)
    }
}

private struct BuilderSegmentedControl: View {
    let title: String
    let choices: [String]
    @Binding var selection: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            MonoLabel(text: title, size: 9, color: Ink.faint)
            HStack(spacing: 0) {
                ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                    Button { selection = index } label: {
                        Text(choice)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selection == index ? .white : Ink.muted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(selection == index ? Ink.signal : Color.clear)
                            .overlay(Rectangle().strokeBorder(selection == index ? Ink.signalSoft : Ink.hairline, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct BuilderNumberControl: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MonoLabel(text: title, size: 9, color: Ink.faint)
            HStack {
                Text("\(value)")
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundStyle(Ink.text)
                Spacer()
                Button { value = max(range.lowerBound, value - 1) } label: { Image(systemName: "minus").frame(width: 44, height: 44) }.accessibilityLabel("Decrease \(title)")
                Button { value = min(range.upperBound, value + 1) } label: { Image(systemName: "plus").frame(width: 44, height: 44) }.accessibilityLabel("Increase \(title)")
            }
            .foregroundStyle(Ink.signalSoft)
            .padding(.horizontal, 10)
            .frame(height: 44)
            .background(Ink.raised)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .frame(maxWidth: .infinity)
    }
}

private enum LocalMediaStore {
    static func importItems(_ items: [PhotosPickerItem]) async throws -> [MediaAttachment] {
        var attachments: [MediaAttachment] = []
        for item in items {
            attachments.append(try await importItem(item))
        }
        return attachments
    }

    static func importItem(_ item: PhotosPickerItem, forceKind: MediaKind? = nil) async throws -> MediaAttachment {
        guard let data = try await item.loadTransferable(type: Data.self) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let isVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) }
        let kind = forceKind ?? (isVideo ? .video : .image)
        let ext = kind == .video ? "mov" : "jpg"
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MinotaurMedia", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let filename = "\(UUID().uuidString).\(ext)"
        let url = directory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return MediaAttachment(kind: kind, relativePath: "MinotaurMedia/\(filename)")
    }
}

/// A single-canvas, private workout builder. Advanced program structure stays in the Labyrinth builder.
private struct PersonalWorkoutBuilder: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let existing: Labyrinth?
    let onSave: (Labyrinth) -> Void
    @State private var name = ""
    @State private var notes = ""
    @State private var day = LabyrinthDraft.blankDay(number: 1)
    @State private var editingIndex: Int?
    @State private var showDiscard = false
    @State private var removingExercise: UUID?
    @State private var loaded = false
    @State private var bannerItem: PhotosPickerItem?
    @State private var cover: PhotoRef?
    @State private var mediaError: String?
    @AppStorage("personalWorkoutDraft") private var savedDraft = Data()

    private var valid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !day.blocks.isEmpty &&
        day.blocks.allSatisfy { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Built around you.").font(.largeTitle.bold()).tracking(-1)
                        Text("One workout, ready whenever you are. Private by default.")
                            .font(.body).foregroundStyle(Ink.muted)
                    }
                    BuilderField(title: "Workout name", text: $name, placeholder: "e.g. My full body workout")
                        .accessibilityIdentifier("workoutName")
                    BuilderField(title: "Notes (optional)", text: $notes, placeholder: "A reminder for your future self", axis: .vertical)
                    PhotosPicker(selection: $bannerItem, matching: .images) {
                        if let cover {
                            MediaBox(ref: cover, height: 150).clipShape(RoundedRectangle(cornerRadius: 18))
                        } else { Label("Add a cover photo", systemImage: "photo.badge.plus").font(.subheadline).padding(.vertical, 8) }
                    }
                    SectionTitle(title: "Workout blocks", subtitle: "Tap an exercise to edit sets, reps, rest, and guidance.")
                    ForEach(Array(day.blocks.enumerated()), id: \.element.id) { index, block in
                        ExerciseBlockCard(block: block, position: index + 1, canMoveUp: index > 0,
                            canMoveDown: index + 1 < day.blocks.count,
                            edit: { editingIndex = index }, moveUp: { day.blocks.swapAt(index, index - 1) },
                            moveDown: { day.blocks.swapAt(index, index + 1) }, remove: { removingExercise = block.id })
                    }
                    if day.blocks.isEmpty {
                        EmptyState(icon: "dumbbell", title: "Start with an exercise", message: "Add a movement, set your reps, and choose how long to rest.")
                    }
                    SlabButton(title: "Add exercise", icon: "plus", filled: false) {
                        day.blocks.append(ExerciseBlock(name: "New exercise", target: "", sets: 3, reps: "10", restSeconds: 60, note: nil, transitionRestSeconds: 60))
                        editingIndex = day.blocks.count - 1
                    }.accessibilityIdentifier("addExercise")
                }.padding(20)
            }.background(Ink.canvas).foregroundStyle(Ink.text)
                .navigationTitle(existing == nil ? "Build my workout" : "Edit workout")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Close") { persistDraft(); dismiss() } }
                    ToolbarItem(placement: .topBarTrailing) {
                        if existing == nil { Button("Discard", role: .destructive) { showDiscard = true } }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    SlabButton(title: "Save workout", icon: "checkmark", accent: true) { save() }
                        .disabled(!valid).opacity(valid ? 1 : 0.45).padding(16).background(Ink.canvas)
                        .accessibilityIdentifier("savePersonalWorkout")
                }
                .sheet(isPresented: Binding(get: { editingIndex != nil }, set: { if !$0 { editingIndex = nil } })) {
                    if let index = editingIndex, day.blocks.indices.contains(index) {
                        ExerciseEditor(block: $day.blocks[index])
                    }
                }
                .confirmationDialog("Remove this exercise?", isPresented: Binding(get: { removingExercise != nil }, set: { if !$0 { removingExercise = nil } }), titleVisibility: .visible) {
                    Button("Remove exercise", role: .destructive) {
                        if let id = removingExercise { day.blocks.removeAll { $0.id == id } }
                        removingExercise = nil
                    }
                }
                .confirmationDialog("Discard this draft?", isPresented: $showDiscard, titleVisibility: .visible) {
                    Button("Discard draft", role: .destructive) { savedDraft = Data(); loaded = false; dismiss() }
                }
                .onAppear { restore() }
                .onChange(of: name) { _, _ in persistDraft() }
                .onChange(of: notes) { _, _ in persistDraft() }
                .onChange(of: day) { _, _ in persistDraft() }
                .onChange(of: bannerItem) { _, item in
                    guard let item else { return }
                    Task {
                        do { cover = .file(try await LocalMediaStore.importItem(item, forceKind: .image).relativePath); persistDraft() }
                        catch { mediaError = error.localizedDescription }
                    }
                }
                .alert("Couldn’t import photo", isPresented: Binding(get: { mediaError != nil }, set: { if !$0 { mediaError = nil } })) {
                    Button("OK", role: .cancel) {}
                } message: { Text(mediaError ?? "") }
        }
    }

    private func restore() {
        guard !loaded else { return }
        if let existing {
            name = existing.name; notes = existing.tagline; day = existing.days.first ?? day; cover = existing.cover
        } else if let draft = try? JSONDecoder().decode(QuickDraft.self, from: savedDraft) {
            name = draft.name; notes = draft.notes; day = draft.day; cover = draft.cover
        }
        loaded = true
    }
    private func persistDraft() {
        guard existing == nil, loaded else { return }
        if let data = try? JSONEncoder().encode(QuickDraft(name: name, notes: notes, day: day, cover: cover)) { savedDraft = data }
    }
    private func save() {
        day.title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        day.notes = notes
        day.estimatedMinutes = max(5, day.blocks.reduce(0) { $0 + $1.sets * (45 + $1.restSeconds) } / 60)
        let program = Labyrinth(id: existing?.id ?? UUID(), name: day.title, ownerName: state.user.name,
            ownerHandle: state.user.handle, ownerAvatar: state.user.avatar, tagline: notes, cover: cover,
            weeks: 0, daysPerWeek: 1, level: state.preferences.experience, category: "Personal", price: nil,
            memberCount: 0, official: false, isPublic: false, dmEnabled: false, days: [day], format: .ongoing,
            goal: state.preferences.goal, equipment: state.preferences.equipment, isPersonal: true)
        savedDraft = Data(); loaded = false; onSave(program)
    }
}
nonisolated private struct QuickDraft: Codable {
    var name: String
    var notes: String
    var day: ProgramDay
    var cover: PhotoRef?
}

private struct DaySettingsEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var day: ProgramDay
    @State private var items: [PhotosPickerItem] = []
    @State private var error: String?
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    BuilderField(title: "Day name", text: $day.title, placeholder: "e.g. Upper body")
                    BuilderField(title: "Notes", text: $day.notes, placeholder: "Focus, intent, or modifications", axis: .vertical)
                    Toggle("Recovery day", isOn: Binding(get: { day.recovery ?? false }, set: { day.recovery = $0 }))
                    Text("Recovery hides exercise blocks without deleting them.").font(.caption).foregroundStyle(Ink.muted)
                    BuilderNumberControl(title: "Estimated minutes", value: $day.estimatedMinutes, range: 5...240)
                    GuidanceMediaPicker(title: "Day guidance", media: Binding(get: { day.media ?? [] }, set: { day.media = $0 }), pickerItems: $items, error: $error)
                }.padding(20)
            }.background(Ink.canvas).foregroundStyle(Ink.text)
                .navigationTitle("Day \(day.number)").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
                .alert("Media import failed", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                    Button("OK", role: .cancel) {}
                } message: { Text(error ?? "") }
        }
    }
}
