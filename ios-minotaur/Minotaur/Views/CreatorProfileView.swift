import SwiftUI

struct CreatorPortrait: View {
    let creator: CreatorProfile
    var size: CGFloat = 52
    var body: some View {
        Group {
            if let image = creator.portrait?.uiImage {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Text(creator.name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined())
                    .font(.system(size: size * 0.3, weight: .semibold))
                    .foregroundStyle(Ink.text).frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Ink.raised)
            }
        }.frame(width: size, height: size).clipShape(Circle()).accessibilityHidden(true)
    }
}

struct CreatorByline: View {
    let creator: CreatorProfile
    var body: some View {
        HStack(spacing: 10) {
            CreatorPortrait(creator: creator, size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(creator.name).font(.subheadline.weight(.semibold)).foregroundStyle(Ink.text)
                Text(creator.handle).font(.caption).foregroundStyle(Ink.muted)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(Ink.muted)
        }.frame(minHeight: 44).contentShape(Rectangle())
    }
}

struct CreatorRow: View {
    let creator: CreatorProfile
    @Environment(AppState.self) private var state
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            CreatorPortrait(creator: creator, size: 64)
            VStack(alignment: .leading, spacing: 5) {
                Text(creator.name).font(TrainingType.title).foregroundStyle(Ink.text)
                Text(creator.specialty).font(.subheadline).foregroundStyle(Ink.muted)
                Text(creator.handle).font(.caption).foregroundStyle(Ink.muted)
                if state.followedCreators.contains(creator.id) {
                    Label("Following", systemImage: "checkmark").font(.caption.weight(.medium)).foregroundStyle(Ink.signalSoft)
                }
            }
            Spacer(minLength: 0)
        }.padding(.vertical, 10).frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
    }
}

struct CreatorProfileView: View {
    let creator: CreatorProfile
    @Environment(AppState.self) private var state
    private var programs: [Labyrinth] { state.programs(by: creator.handle) }
    private var following: Bool { state.followedCreators.contains(creator.id) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    CreatorPortrait(creator: creator, size: 96)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(creator.name).font(TrainingType.display)
                        Text(creator.handle).font(.subheadline).foregroundStyle(Ink.muted)
                    }
                    Text(creator.specialty).font(.headline)
                    Text(creator.bio).font(.body).foregroundStyle(Ink.muted)
                    if creator.isDemo { Text("Demo creator").font(.caption).foregroundStyle(Ink.muted) }
                    if creator.id != state.user.handle.lowercased() {
                        Button {
                            var transaction = Transaction(animation: nil)
                            transaction.disablesAnimations = true
                            withTransaction(transaction) { state.toggleFollow(creator) }
                        } label: {
                            HStack(spacing: 10) {
                                Text(following ? "Following" : "Follow creator")
                                Image(systemName: following ? "checkmark" : "plus")
                            }.font(.headline).fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 16).padding(.vertical, 14)
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .foregroundStyle(following ? Ink.text : .white)
                                .background(following ? Ink.raised : Ink.signal, in: RoutePanelShape(cut: 10))
                                .id(following).transition(.identity)
                        }.buttonStyle(.plain).transaction { $0.animation = nil; $0.disablesAnimations = true }
                            .accessibilityIdentifier("followCreator")
                        Text("Following is free. Join a Labyrinth separately to access its community.")
                            .font(.caption).foregroundStyle(Ink.muted)
                    }
                }.padding(20).modifier(RouteSurface())
                SectionTitle(title: "Train with \(creator.name)", subtitle: "Choose a plan that fits your goals.")
                ForEach(programs) { program in
                    NavigationLink { LabyrinthDetailView(labyrinthID: program.id) } label: {
                        ProgramCover(program: program)
                    }.buttonStyle(PressStyle())
                }
                SectionTitle(title: "Find your people", subtitle: "Each Labyrinth has its own members’ community.")
                ForEach(programs) { program in
                    NavigationLink { LabyrinthDetailView(labyrinthID: program.id, initialSection: 1) } label: {
                        CommunityDiscoveryRow(program: program)
                    }.buttonStyle(PressStyle())
                }
            }.padding(20).padding(.bottom, 20)
        }.background(ArchitecturalCanvas()).foregroundStyle(Ink.text)
            .navigationTitle("Creator").navigationBarTitleDisplayMode(.inline)
    }
}

struct FollowingCreatorsView: View {
    @Environment(AppState.self) private var state
    private var following: [CreatorProfile] { state.creators.filter { state.followedCreators.contains($0.id) } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if following.isEmpty {
                    EmptyState(icon: "person.crop.circle.badge.plus", title: "Find your training people", message: "Follow creators from Explore to keep their profiles close. Following is free.")
                }
                ForEach(following) { creator in
                    NavigationLink { CreatorProfileView(creator: creator) } label: { CreatorRow(creator: creator) }.buttonStyle(.plain)
                }
            }.padding(20)
        }.background(Ink.canvas).navigationTitle("Following").navigationBarTitleDisplayMode(.inline)
    }
}

struct CommunityDiscoveryRow: View {
    let program: Labyrinth
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                MediaBox(ref: program.cover, height: 76).frame(width: 76).clipShape(RoutePanelShape(cut: 9))
                VStack(alignment: .leading, spacing: 5) {
                    Text(program.name).font(.headline).foregroundStyle(Ink.text)
                    Text("With \(program.ownerName)").font(.subheadline).foregroundStyle(Ink.muted)
                    Text("\(program.memberCount.formatted()) members").font(.caption).foregroundStyle(Ink.muted)
                }
            }
            Text(program.accessSummary).font(.subheadline.weight(.medium)).foregroundStyle(Ink.signalSoft)
            Label("Explore community", systemImage: "arrow.right").font(.subheadline.weight(.semibold)).foregroundStyle(Ink.text)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(18).modifier(RouteSurface())
    }
}

struct CommunityPreview: View {
    let program: Labyrinth
    @Environment(AppState.self) private var state
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "Train together", subtitle: "A community around \(program.name).")
            if let creator = state.creator(for: program) {
                NavigationLink { CreatorProfileView(creator: creator) } label: { CreatorByline(creator: creator) }.buttonStyle(.plain)
                if creator.isDemo { Text("Demo community · sample counts").font(.caption).foregroundStyle(Ink.muted) }
            }
            Text("\(program.memberCount.formatted()) members").font(.headline)
            Text(program.accessSummary).font(.subheadline.weight(.semibold)).foregroundStyle(Ink.signalSoft)
            Label("General discussions and creator updates", systemImage: "bubble.left.and.bubble.right")
            Label("Questions, replies, and shared progress", systemImage: "person.2")
            if program.dmEnabled { Label("Direct messaging with the creator", systemImage: "envelope") }
            Text("Join to read and post. Members’ conversations and photos stay inside the community.")
                .font(.subheadline).foregroundStyle(Ink.muted)
        }.font(.subheadline).frame(maxWidth: .infinity, alignment: .leading).padding(20).modifier(RouteSurface())
    }
}
