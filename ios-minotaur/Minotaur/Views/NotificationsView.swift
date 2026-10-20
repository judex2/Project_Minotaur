import SwiftUI

struct NotificationsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var unreadOnly = false

    private var items: [ActivityNotification] {
        state.notifications.filter { !unreadOnly || !state.readActivityIDs.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                SectionTitle(title: "Your people. Your progress.", subtitle: "Updates from your Labyrinths and conversations.")
                if typeSize.isAccessibilitySize { filter.pickerStyle(.menu) }
                else { filter.pickerStyle(.segmented) }
                if items.isEmpty {
                    EmptyState(icon: "bell.badge", title: unreadOnly ? "You’re all caught up" : "Your activity starts here",
                        message: unreadOnly ? "You’ve read all your updates." : "New members, creator posts, and replies to your posts will appear here.")
                }
                ForEach(items) { item in
                    NavigationLink {
                        NotificationDestinationView(item: item)
                    } label: {
                        notificationRow(item)
                    }.buttonStyle(.plain).accessibilityIdentifier("notification-\(item.id)")
                }
            }.padding(20).padding(.bottom, 20)
        }.background(ArchitecturalCanvas()).foregroundStyle(Ink.text)
            .navigationTitle("Notifications").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Mark all read") { state.markAllNotificationsRead() }
                        .disabled(state.unreadNotificationCount == 0)
                        .accessibilityIdentifier("markNotificationsRead")
                }
            }
    }

    private var filter: some View {
        Picker("Activity", selection: $unreadOnly) {
            Text("All").tag(false)
            Text("Unread").tag(true)
        }.accessibilityIdentifier("notificationFilter")
    }

    private func notificationRow(_ item: ActivityNotification) -> some View {
        let unread = !state.readActivityIDs.contains(item.id)
        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.icon).font(.title3).foregroundStyle(unread ? Ink.signalSoft : Ink.muted)
                .frame(width: 30, height: 30).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title).font(unread ? .body.weight(.semibold) : .body).multilineTextAlignment(.leading)
                if let program = state.labyrinths.first(where: { $0.id == item.labyrinthID }), item.kind == .reply {
                    Text(program.name).font(.subheadline).foregroundStyle(Ink.muted)
                }
                HStack(spacing: 8) {
                    Text(item.createdAt, style: .relative)
                    if item.isDemo { Text("· Demo activity") }
                }.font(.caption).foregroundStyle(Ink.muted)
            }.frame(maxWidth: .infinity, alignment: .leading)
            if unread { Circle().fill(Ink.signal).frame(width: 7, height: 7).padding(.top, 8).accessibilityHidden(true) }
        }.padding(18).modifier(RouteSurface())
            .accessibilityElement(children: .combine).accessibilityValue(unread ? "Unread" : "Read")
    }
}

private struct NotificationDestinationView: View {
    @Environment(AppState.self) private var state
    let item: ActivityNotification
    var body: some View {
        Group {
            if let program = state.labyrinths.first(where: { $0.id == item.labyrinthID }),
               state.isOwner(of: program) || state.isMember(of: program) {
                if let postID = item.postID { PostDetailView(postID: postID) }
                else { LabyrinthDetailView(labyrinthID: program.id, initialSection: 1) }
            } else {
                ContentUnavailableView("Update unavailable", systemImage: "bell.slash", description: Text("This Labyrinth may no longer be in your library."))
            }
        }.onAppear { state.markNotificationRead(item) }
    }
}
