import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var state
    @State private var path: [Labyrinth] = []
    @State private var showBuilder = false
    @State private var showSettings = false
    @State private var showSchedule = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack(spacing: 18) {
                        MediaBox(ref: state.user.avatar, height: 80).frame(width: 80).clipShape(Circle())
                        VStack(alignment: .leading, spacing: 5) {
                            Text(state.user.name).font(TrainingType.section)
                            Text(state.user.handle).font(.subheadline).foregroundStyle(Ink.muted)
                            if state.user.verified { Label("Founder", systemImage: "checkmark.seal.fill").font(.caption).foregroundStyle(Ink.blue) }
                        }
                    }
                    Text(state.user.tagline).font(.body).foregroundStyle(Ink.muted)
                    NavigationLink { FollowingCreatorsView() } label: {
                        Label("Following · \(state.followedCreators.count)", systemImage: "person.crop.circle.badge.checkmark")
                            .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                    }.accessibilityIdentifier("followingCreators")
                    if let creator = state.creators.first(where: { $0.id == state.user.handle.lowercased() }) {
                        NavigationLink { CreatorProfileView(creator: creator) } label: {
                            Label("View public creator profile", systemImage: "person.crop.square")
                                .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                        }
                    }
                    HStack(spacing: 12) {
                        stat("\(state.history.count)", "Workouts logged")
                        stat("\(state.history.reduce(0) { $0 + $1.completedSets })", "Sets completed")
                    }
                    HStack {
                        SectionTitle(title: "Your Labyrinths")
                        Spacer()
                        NavigationLink { TrainingLibraryView() } label: { Text("See all").font(.subheadline.weight(.semibold)).frame(minHeight: 44) }
                        Button { showSchedule = true } label: { Image(systemName: "calendar").frame(width: 44, height: 44) }
                            .accessibilityLabel("Edit weekly schedule")
                    }
                    if state.library.isEmpty {
                        EmptyState(icon: "square.stack", title: "Start with one workout", message: "Joined programs and your own workouts will live here.")
                    } else {
                        ForEach(state.library.prefix(3)) { program in
                            Button { path.append(program) } label: { ProgramRow(program: program) }.buttonStyle(PressStyle())
                        }
                    }
                    SlabButton(title: "Create a Labyrinth", icon: "plus", filled: false) { showBuilder = true }
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            SectionTitle(title: "Your recent work")
                            Spacer()
                            NavigationLink { WorkoutHistoryView() } label: { Text("History").font(.subheadline.weight(.semibold)).frame(minHeight: 44) }
                                .accessibilityIdentifier("workoutHistory")
                        }
                        if state.history.isEmpty {
                            Text("Finish a workout to start your history.").foregroundStyle(Ink.muted)
                        } else {
                            ForEach(state.history.prefix(3)) { record in
                                NavigationLink { SessionDetailView(record: record) } label: { SessionHistoryRow(record: record) }.buttonStyle(.plain)
                            }
                        }
                    }
                    if !state.progressGallery.isEmpty {
                        SectionTitle(title: "Progress journal")
                        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                            ForEach(Array(state.progressGallery.enumerated()), id: \.offset) { _, photo in
                                MediaBox(ref: photo, height: 190).clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                        }
                    }
                }.padding(20).padding(.bottom, 20)
            }.background(ArchitecturalCanvas()).foregroundStyle(Ink.text)
                .navigationTitle("Your space").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showSettings = true } label: { Image(systemName: "gearshape") }.accessibilityLabel("Settings")
                    }
                }
                .navigationDestination(for: Labyrinth.self) { LabyrinthDetailView(labyrinthID: $0.id) }
                .sheet(isPresented: $showSettings) { SettingsView().environment(state) }
                .sheet(isPresented: $showSchedule) { ScheduleEditor().environment(state) }
                .fullScreenCover(isPresented: $showBuilder) {
                    LabyrinthBuilderView { program in
                        state.createLabyrinth(program); showBuilder = false; path.append(program)
                    }.environment(state)
                }
        }
    }
    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(TrainingType.number).monospacedDigit().foregroundStyle(Ink.text)
            Text(label).font(.caption).foregroundStyle(Ink.muted)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(18)
            .modifier(RouteSurface())
    }
}

private struct SettingsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearance") private var appearance = "System"
    @State private var preferences = TrainingPreferences()
    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Theme", selection: $appearance) {
                        ForEach(["System", "Light", "Dark"], id: \.self) { Text($0) }
                    }
                }
                Section("Your training preferences") { PreferenceFields(preferences: $preferences) }
                Section("About this preview") {
                    Text("Your workouts, schedule, and posts are saved on this iPhone. Cloud accounts, purchases, and live sharing links will be connected before launch.")
                        .foregroundStyle(Ink.muted)
                }
            }.navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { state.setPreferences(preferences); dismiss() } } }
                .onAppear { preferences = state.preferences }
        }
    }
}
