import SwiftUI

struct MinotaurMark: View {
    var color: Color = Ink.text

    var body: some View {
        Image("MinotaurMark")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(color)
            .accessibilityHidden(true)
    }
}

struct BrandHeader: View {
    @Environment(AppState.self) private var state
    var body: some View {
        HStack(spacing: 12) {
            brand
            Spacer(minLength: 8)
            NavigationLink { NotificationsView() } label: {
                Image(systemName: "bell")
                    .font(.system(size: 21, weight: .medium)).foregroundStyle(Ink.text)
                    .frame(width: 48, height: 48)
                    .background(Ink.surface.opacity(0.8), in: RoundedRectangle(cornerRadius: 15))
                    .overlay(alignment: .topTrailing) {
                        if state.unreadNotificationCount > 0 {
                            Circle().fill(Ink.signal).frame(width: 8, height: 8).padding(9)
                        }
                    }
            }.buttonStyle(.plain).accessibilityIdentifier("notifications")
                .accessibilityLabel("Notifications")
                .accessibilityValue(state.unreadNotificationCount == 0 ? "All read" : "\(state.unreadNotificationCount) unread")
        }
    }
    private var brand: some View {
        HStack(spacing: 9) {
            MinotaurMark().frame(width: 36, height: 36)
            Text("MINOTAUR").font(.system(size: 16, weight: .black)).tracking(2.5)
                .foregroundStyle(Ink.text)
        }.accessibilityElement(children: .combine)
    }
}

struct SectionTitle: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(TrainingType.section).tracking(-0.5).foregroundStyle(Ink.text)
            if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(Ink.muted) }
        }
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon).font(.title).foregroundStyle(Ink.blue)
            Text(title).font(.title3.bold()).foregroundStyle(Ink.text)
            Text(message).font(.body).foregroundStyle(Ink.muted)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(24)
            .background(Ink.surface, in: RoundedRectangle(cornerRadius: 22))
    }
}

struct ProgramRow: View {
    let program: Labyrinth
    var body: some View {
        HStack(spacing: 15) {
            MediaBox(ref: program.cover, height: 76).frame(width: 76)
                .clipShape(RoutePanelShape(cut: 9))
            VStack(alignment: .leading, spacing: 6) {
                Text(program.name).font(.headline).foregroundStyle(Ink.text)
                Text(program.isPersonal == true ? "Your personal workout" : program.durationLabel)
                    .font(.subheadline).foregroundStyle(Ink.muted)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(Ink.muted)
        }.padding(.vertical, 7).contentShape(Rectangle())
    }
}

struct ProgramCover: View {
    let program: Labyrinth
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MediaBox(ref: program.cover, height: 200)
                .clipShape(RoutePanelShape(cut: 18))
                .overlay(alignment: .topLeading) {
                    Text(program.price == nil ? "Free program" : program.priceLabel)
                        .font(.caption.weight(.semibold)).foregroundStyle(Ink.text).padding(.horizontal, 12).padding(.vertical, 9)
                        .modifier(RestrainedGlass(cut: 7)).padding(14)
                }
            VStack(alignment: .leading, spacing: 6) {
                Text(program.name).font(TrainingType.title).foregroundStyle(Ink.text)
                Text(program.tagline).font(.subheadline).foregroundStyle(Ink.muted).lineLimit(2)
                HStack(spacing: 16) {
                    Label(program.level, systemImage: "chart.bar")
                    Label(program.programFormat == .ongoing ? "\(program.days.count)-day cycle · Self-paced" : "\(program.daysPerWeek) days / week", systemImage: "calendar")
                }.font(.caption).foregroundStyle(Ink.muted).padding(.top, 4)
            }
        }.contentShape(Rectangle())
    }
}

struct PreferenceFields: View {
    @Binding var preferences: TrainingPreferences
    var body: some View {
        Picker("Your goal", selection: $preferences.goal) {
            ForEach(["Build muscle", "Get stronger", "Calisthenics", "General fitness"], id: \.self) { Text($0) }
        }
        Picker("Experience", selection: $preferences.experience) {
            ForEach(["Beginner", "Intermediate", "Advanced"], id: \.self) { Text($0) }
        }
        Picker("Equipment", selection: $preferences.equipment) {
            ForEach(["Any", "Gym", "Bodyweight"], id: \.self) { Text($0) }
        }
        Stepper("\(preferences.daysPerWeek) days per week", value: $preferences.daysPerWeek, in: 1...7)
    }
}

struct OrientationView: View {
    @Environment(AppState.self) private var state
    let onDone: () -> Void
    @State private var preferences = TrainingPreferences()
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 14) {
                        MinotaurMark().frame(width: 74, height: 74)
                        Text("Your training.\nYour way.").font(.largeTitle.bold()).tracking(-1)
                            .lineLimit(nil).fixedSize(horizontal: false, vertical: true)
                        Text("Find a program or build your own. We call a structured program a Labyrinth. Every one starts with a first workout.")
                            .font(.body).foregroundStyle(Ink.muted)
                    }.padding(.vertical, 12)
                }.listRowBackground(Color.clear)
                Section("Make it yours") { PreferenceFields(preferences: $preferences) }
                Section {
                    SlabButton(title: "Let's get started", accent: true) {
                        state.setPreferences(preferences); onDone()
                    }.accessibilityIdentifier("onboardingDone")
                }.listRowBackground(Color.clear)
            }.scrollContentBackground(.hidden).background(Ink.canvas)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Skip for now", action: onDone) } }
        }.onAppear { preferences = state.preferences }
    }
}

struct ScheduleEditor: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var slots: [String: ScheduleSlot] = [:]
    private let weekdays = [(2, "Monday"), (3, "Tuesday"), (4, "Wednesday"), (5, "Thursday"), (6, "Friday"), (7, "Saturday"), (1, "Sunday")]
    var body: some View {
        NavigationStack {
            Form {
                Section { Text("Choose a program and workout for each day. An unassigned day is for rest.").foregroundStyle(Ink.muted) }
                ForEach(weekdays, id: \.0) { number, title in
                    let key = String(number)
                    Section(title) {
                        Picker("Program", selection: Binding<UUID?>(get: { slots[key]?.labyrinthID }, set: {
                            slots[key] = ScheduleSlot(labyrinthID: $0, dayNumber: $0 == nil ? nil : 1)
                        })) {
                            Text("Rest day").tag(nil as UUID?)
                            ForEach(state.library) { Text($0.name).tag(Optional($0.id)) }
                        }
                        if let program = state.library.first(where: { $0.id == slots[key]?.labyrinthID }) {
                            Picker("Workout", selection: Binding(get: { slots[key]?.dayNumber ?? 1 }, set: { slots[key]?.dayNumber = $0 })) {
                                ForEach(program.days) { Text("\($0.number). \($0.title)").tag($0.number) }
                            }
                        }
                    }
                }
            }.navigationTitle("Your week").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") {
                        for (number, _) in weekdays where slots[String(number)] == nil { slots[String(number)] = ScheduleSlot() }
                        state.setSchedule(slots); dismiss()
                    } }
                }
        }.onAppear { slots = state.schedule }
    }
}
