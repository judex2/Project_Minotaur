import SwiftUI

struct ExploreView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var query = ""
    @State private var level = "All"
    @State private var equipment = "All"
    @State private var category = "All"
    @State private var goal = "All"
    @State private var duration = "All"
    @State private var freeOnly = false
    @State private var maxDays = 7
    @State private var showFilters = false
    @State private var discovery = "Plans"

    private var searchText: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var creatorResults: [CreatorProfile] {
        state.creators.filter { creator in
            (creator.id != state.user.handle.lowercased() || !searchText.isEmpty) &&
            (creator.matches(searchText) || state.programs(by: creator.handle).contains { $0.matchesDiscovery(searchText) })
        }
    }
    private var communities: [Labyrinth] {
        state.publicPrograms.filter { $0.matchesDiscovery(searchText) }
            .sorted { $0.memberCount > $1.memberCount }
    }

    private var results: [Labyrinth] {
        state.labyrinths.filter { program in
            program.isPublic && program.isPersonal != true &&
            program.matchesDiscovery(searchText) &&
            (goal == "All" || (program.goal ?? inferredGoal(program)) == goal) &&
            (duration == "All" || (duration == "Ongoing" ? program.programFormat == .ongoing : program.programFormat == .fixed)) &&
            (level == "All" || program.level.localizedCaseInsensitiveContains(level)) &&
            (category == "All" || program.category.localizedCaseInsensitiveContains(category)) &&
            (equipment == "All" || (program.equipment ?? (program.category == "Calisthenics" ? "Bodyweight" : "Gym")) == equipment) &&
            (!freeOnly || program.price == nil) && (program.programFormat == .ongoing || program.daysPerWeek <= maxDays)
        }.sorted { score($0) > score($1) }
    }
    private var filterCount: Int {
        [goal != "All", duration != "All", level != "All", equipment != "All", category != "All", freeOnly, maxDays < 7].filter { $0 }.count
    }
    private func inferredGoal(_ program: Labyrinth) -> String {
        program.category == "Strength" ? "Get stronger" : program.category == "Hypertrophy" ? "Build muscle" : program.category == "Calisthenics" ? "Calisthenics" : "General fitness"
    }
    private func score(_ program: Labyrinth) -> Int {
        (program.level == state.preferences.experience ? 2 : 0) +
        (program.programFormat == .fixed && program.daysPerWeek == state.preferences.daysPerWeek ? 1 : 0) +
        ((program.goal ?? inferredGoal(program)) == state.preferences.goal ? 3 : 0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Find your rhythm.").font(TrainingType.display).tracking(-0.9)
                        if !typeSize.isAccessibilitySize { Text("Find your plan. Meet your people.")
                            .foregroundStyle(Ink.muted)
                        }
                        if discovery == "Plans" {
                        Button("Match my preferences", systemImage: "sparkle.magnifyingglass") {
                            goal = state.preferences.goal
                            level = state.preferences.experience
                            equipment = state.preferences.equipment == "Any" ? "All" : state.preferences.equipment
                            maxDays = state.preferences.daysPerWeek
                            showFilters = true
                        }.font(.subheadline.weight(.semibold)).padding(.top, 8)
                        }
                    }
                    if typeSize.isAccessibilitySize {
                        scopePicker.pickerStyle(.menu)
                    } else {
                        scopePicker.pickerStyle(.segmented)
                    }
                    if discovery == "Creators" {
                        SectionTitle(title: "People to train with", subtitle: typeSize.isAccessibilitySize ? nil : "Find a familiar name or discover a new approach.")
                        Text("Demo creators")
                            .font(.caption).foregroundStyle(Ink.muted)
                        if creatorResults.isEmpty {
                            EmptyState(icon: "person.crop.circle", title: "No creators found", message: "Try a name, handle, or training specialty.")
                        }
                        ForEach(creatorResults) { creator in
                            NavigationLink { CreatorProfileView(creator: creator) } label: { CreatorRow(creator: creator) }
                                .buttonStyle(.plain).accessibilityIdentifier("creator-\(creator.id)")
                        }
                    } else if discovery == "Communities" {
                        SectionTitle(title: "A shared rhythm", subtitle: "Find people following a path like yours.")
                        Text("Demo communities · sample member counts").font(.caption).foregroundStyle(Ink.muted)
                        if communities.isEmpty {
                            EmptyState(icon: "person.2", title: "No communities found", message: "Try another creator or program name.")
                        }
                        ForEach(communities) { program in
                            NavigationLink { LabyrinthDetailView(labyrinthID: program.id, initialSection: 1) } label: {
                                CommunityDiscoveryRow(program: program)
                            }.buttonStyle(PressStyle())
                        }
                    } else {
                    HStack {
                        Text("\(results.count) plans to explore").font(.subheadline).foregroundStyle(Ink.muted)
                        Spacer()
                        Button { showFilters = true } label: {
                            Label(filterCount == 0 ? "Filters" : "Filters · \(filterCount)", systemImage: "slider.horizontal.3")
                                .font(.subheadline.weight(.semibold)).padding(.vertical, 10).padding(.horizontal, 14)
                                .background(Ink.surface, in: RoutePanelShape(cut: 8))
                        }.accessibilityIdentifier("exploreFilters")
                    }
                    if results.isEmpty {
                        EmptyState(icon: "magnifyingglass", title: "A fresh search?", message: "Try fewer filters or another exercise or goal.")
                        Button("Clear filters") { reset(); query = "" }
                    } else {
                        ForEach(results) { program in
                            VStack(alignment: .leading, spacing: 10) {
                            NavigationLink { LabyrinthDetailView(labyrinthID: program.id) } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    ProgramCover(program: program)
                                    if score(program) >= 3 {
                                        Label((program.goal ?? inferredGoal(program)) == state.preferences.goal ? "Fits your \(state.preferences.goal.lowercased()) goal" : "Fits your experience and weekly rhythm", systemImage: "checkmark.circle")
                                            .font(.caption).foregroundStyle(Ink.blue)
                                    }
                                }
                            }.buttonStyle(PressStyle())
                            if let creator = state.creator(for: program) {
                                NavigationLink { CreatorProfileView(creator: creator) } label: { CreatorByline(creator: creator) }.buttonStyle(.plain)
                            }
                            }
                        }
                    }
                    }
                }.padding(20)
            }
            .background(ArchitecturalCanvas()).foregroundStyle(Ink.text)
            .navigationTitle("Explore").navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Creator, goal, or plan")
            .sheet(isPresented: $showFilters) {
                NavigationStack {
                    Form {
                        Section("Find your fit") {
                            Picker("Goal", selection: $goal) { ForEach(["All", "Build muscle", "Get stronger", "Calisthenics", "General fitness"], id: \.self) { Text($0) } }
                            Picker("Length", selection: $duration) { ForEach(["All", "Fixed", "Ongoing"], id: \.self) { Text($0) } }
                            Picker("Experience", selection: $level) {
                                ForEach(["All", "Beginner", "Intermediate", "Advanced"], id: \.self) { Text($0) }
                            }
                            Picker("Training style", selection: $category) {
                                ForEach(["All", "Strength", "Hypertrophy", "Calisthenics", "Hybrid"], id: \.self) { Text($0) }
                            }
                            Picker("Equipment", selection: $equipment) {
                                ForEach(["All", "Gym", "Bodyweight"], id: \.self) { Text($0) }
                            }
                            Stepper("Up to \(maxDays) days a week", value: $maxDays, in: 1...7)
                            Toggle("Free plans only", isOn: $freeOnly)
                        }
                        Button("Reset filters") { reset() }
                    }.navigationTitle("Your kind of training").navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Show \(results.count) plans") { showFilters = false } } }
                }.presentationDetents([.medium, .large])
            }
        }
    }
    private var scopePicker: some View {
        Picker("Explore", selection: $discovery) {
            Text("Plans").tag("Plans")
            Text("Creators").tag("Creators")
            Text("Communities").tag("Communities")
        }.accessibilityIdentifier("discoveryScope")
    }
    private func reset() { goal = "All"; duration = "All"; level = "All"; equipment = "All"; category = "All"; freeOnly = false; maxDays = 7 }
}
