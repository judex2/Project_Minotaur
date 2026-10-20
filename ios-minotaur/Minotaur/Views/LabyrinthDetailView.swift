import SwiftUI

struct LabyrinthDetailView: View {
    @Environment(AppState.self) private var state
    let labyrinthID: UUID
    init(labyrinthID: UUID, initialSection: Int = 0) {
        self.labyrinthID = labyrinthID
        _tab = State(initialValue: initialSection)
    }
    @State private var tab = 0
    @State private var selectedDay: ProgramDay?
    @State private var showEditor = false
    @State private var showShare = false
    @State private var showPaymentNotice = false
    private var program: Labyrinth? { state.labyrinths.first { $0.id == labyrinthID } }

    var body: some View {
        Group {
            if let program {
                VStack(spacing: 0) {
                    if program.isPersonal != true {
                        Picker("Section", selection: $tab) {
                            Text("Program").tag(0); Text("Community").tag(1); Text("Progress").tag(2)
                        }.pickerStyle(.segmented).padding(.horizontal, 20).padding(.vertical, 12)
                    }
                    if tab == 0 { overview(program) }
                    else if state.isMember(of: program) || state.isOwner(of: program) {
                        CommunityTab(labyrinth: program, progressOnly: tab == 2)
                    } else {
                        ScrollView {
                            VStack(spacing: 20) {
                                CommunityPreview(program: program)
                                SlabButton(title: program.price == nil ? "Join this Labyrinth" : "Preview membership", accent: true) { join(program) }
                            }.padding(20)
                        }
                    }
                }
                .navigationTitle(program.isPersonal == true ? "Your workout" : "Labyrinth")
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        if state.isOwner(of: program) {
                            Button { showEditor = true } label: { Image(systemName: "pencil") }.accessibilityLabel("Edit workout")
                        }
                        Button { showShare = true } label: { Image(systemName: "square.and.arrow.up") }.accessibilityLabel("Share program")
                    }
                }
            } else { ContentUnavailableView("Program unavailable", systemImage: "square.stack") }
        }
        .background(Ink.canvas).foregroundStyle(Ink.text).navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedDay) { day in
            if let program { ActiveWorkoutView(labyrinth: program, day: day).environment(state) }
        }
        .fullScreenCover(isPresented: $showEditor) {
            if let program {
                LabyrinthBuilderView(labyrinth: program, personal: program.isPersonal == true) { updated in
                    state.updateLabyrinth(updated); showEditor = false
                }.environment(state)
            }
        }
        .sheet(isPresented: $showShare) {
            if let program { ShareLinkPreviewSheet(labyrinth: program).environment(state) }
        }
        .alert("Preview membership", isPresented: $showPaymentNotice) {
            Button("Join for this preview") { if let program { state.join(program) } }
            Button("Not now", role: .cancel) {}
        } message: { Text("Purchases aren’t connected yet. You can try this program locally without a charge.") }
    }

    private func join(_ program: Labyrinth) {
        if program.price != nil { showPaymentNotice = true } else { state.join(program) }
    }

    private func overview(_ program: Labyrinth) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if program.cover != nil {
                    MediaBox(ref: program.cover, height: 230).clipShape(RoutePanelShape(cut: 20))
                } else {
                    Label(program.isPersonal == true ? "Your personal training" : "Your training plan", systemImage: "dumbbell").font(.headline).foregroundStyle(Ink.blue)
                        .padding(18).frame(maxWidth: .infinity, alignment: .leading).background(Ink.blueWash, in: RoundedRectangle(cornerRadius: 18))
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text(program.name).font(TrainingType.display).tracking(-0.9)
                    if !program.tagline.isEmpty { Text(program.tagline).font(.body).foregroundStyle(Ink.muted) }
                    if let creator = state.creator(for: program) {
                        NavigationLink { CreatorProfileView(creator: creator) } label: { CreatorByline(creator: creator) }.buttonStyle(.plain)
                    } else {
                        Text("By \(program.ownerName)").font(.subheadline.weight(.medium)).foregroundStyle(Ink.muted)
                    }
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { metadata(program) }
                    VStack(alignment: .leading, spacing: 8) { metadata(program) }
                }
                if state.isMember(of: program) || state.isOwner(of: program) {
                    if let day = state.today(in: program) {
                        SlabButton(title: day.isRest ? "Log recovery day" : "Start workout", icon: "play.fill", accent: true) { selectedDay = day }
                            .accessibilityIdentifier("startProgram")
                    }
                    TrainingPath(program: program)
                } else {
                    SlabButton(title: program.price == nil ? "Join for free" : "Join · \(program.priceLabel)", accent: true) { join(program) }
                    Text(program.accessSummary)
                        .font(.subheadline).foregroundStyle(Ink.muted)
                }
                if program.isPersonal != true {
                    Button { tab = 1 } label: {
                        Label("Explore the community · \(program.memberCount.formatted()) members", systemImage: "person.2")
                            .font(.subheadline.weight(.semibold)).frame(minHeight: 44, alignment: .leading)
                    }
                }
                SectionTitle(title: "The workouts", subtitle: program.programFormat == .ongoing ? "A sequence you can repeat at your pace." : "Follow the plan, one session at a time.")
                ForEach(program.days) { day in
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 14) {
                            if !day.notes.isEmpty { Text(day.notes).font(.subheadline).foregroundStyle(Ink.muted) }
                            ForEach(day.blocks) { block in
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(block.name).font(.headline)
                                        Text(block.summary)
                                            .font(.subheadline).foregroundStyle(Ink.muted)
                                        if let note = block.note, !note.isEmpty { Text(note).font(.caption).foregroundStyle(Ink.muted) }
                                    }
                                    Spacer()
                                }
                            }
                            if state.isMember(of: program) || state.isOwner(of: program) {
                                Button(day.isRest ? "Log recovery" : "Start this workout") { selectedDay = day }
                                    .font(.headline).padding(.vertical, 8)
                            }
                        }.padding(.top, 14)
                    } label: {
                        HStack(spacing: 12) {
                            Text(String(format: "%02d", day.number)).font(.subheadline.bold()).monospacedDigit().foregroundStyle(Ink.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(day.title).font(.headline).foregroundStyle(Ink.text)
                                Text(day.isRest ? "Recovery" : "\(day.exerciseSummary) · \(day.estimatedMinutes) min")
                                    .font(.caption).foregroundStyle(Ink.muted)
                            }
                        }.padding(.vertical, 5)
                    }.padding(16).background(Ink.surface, in: RoundedRectangle(cornerRadius: 18))
                }
            }.padding(20)
        }
    }
    @ViewBuilder private func metadata(_ program: Labyrinth) -> some View {
        Chip(text: program.durationLabel)
        Chip(text: program.level)
        Chip(text: program.isPublic ? "Public" : "Private")
    }
}
