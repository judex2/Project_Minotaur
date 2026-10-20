import SwiftUI

struct CommunityTab: View {
    @Environment(AppState.self) private var state
    let labyrinth: Labyrinth
    var progressOnly = false
    @State private var channel = 0

    @State private var showCompose = false
    @State private var showThread = false
    @State private var showOwnerSettings = false

    private var visiblePosts: [Post] {
        state.posts(in: labyrinth).filter { progressOnly ? $0.tag == .progress : (channel == 1 ? $0.tag == .question : $0.tag == .update) }
    }

    private var isOwner: Bool { state.isOwner(of: labyrinth) }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 14) {
                    if !progressOnly {
                        Picker("Channel", selection: $channel) { Text("General").tag(0); Text("Q&A").tag(1) }.pickerStyle(.segmented)
                        dmRow
                    }
                    ForEach(visiblePosts) { post in
                        PostCard(post: post, isOwner: isOwner)
                    }
                    if visiblePosts.isEmpty {
                        Panel {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(progressOnly ? "Progress starts somewhere" : channel == 1 ? "There are no small questions" : "Make yourself at home").font(.title3.bold())
                                Text(progressOnly ? "A photo and a few words can mark where you are today." : "This is a space for the people training alongside you.")
                                    .font(.body)
                                    .foregroundStyle(Ink.muted)
                                Button(progressOnly ? "Share your progress" : channel == 1 ? "Ask a question" : "Introduce yourself") { showCompose = true }
                                    .font(.headline).frame(minHeight: 44)
                            }
                        }
                    }
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .scrollIndicators(.hidden)

            if state.isMember(of: labyrinth) || isOwner {
                Button {
                    Haptics.tap()
                    showCompose = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(Ink.signal, in: Circle())
                }
                .buttonStyle(PressStyle())
                .accessibilityLabel("Write a post")
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showCompose) {
            ComposePostView(labyrinth: labyrinth, initialTag: progressOnly ? .progress : (channel == 1 ? .question : .update))
                .environment(state)
                .presentationBackground(Ink.canvas)
        }
        .sheet(isPresented: $showThread) {
            DirectThreadView(labyrinth: labyrinth)
                .environment(state)
                .presentationBackground(Ink.canvas)
        }
        .confirmationDialog("Direct messages", isPresented: $showOwnerSettings, titleVisibility: .visible) {
            Button(labyrinth.dmEnabled ? "Turn direct messages off" : "Turn direct messages on") {
                state.setDM(!labyrinth.dmEnabled, for: labyrinth)
                Haptics.success()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder private var dmRow: some View {
        if isOwner {
            Button {
                Haptics.soft()
                showOwnerSettings = true
            } label: {
                Panel(padding: 14) {
                    HStack {
                        MonoLabel(text: "Founder messages", size: 10, color: Ink.text, icon: "envelope")
                        Spacer()
                        Chip(text: labyrinth.dmEnabled ? "On" : "Off", inverted: labyrinth.dmEnabled)
                    }
                }
            }
            .buttonStyle(PressStyle())
        } else if labyrinth.dmEnabled && state.isMember(of: labyrinth) {
            Button {
                Haptics.soft()
                showThread = true
            } label: {
                Panel(padding: 14) {
                    HStack {
                        MonoLabel(text: "Message \(labyrinth.ownerHandle)", size: 10, color: Ink.text, icon: "envelope")
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(Ink.text)
                    }
                }
            }
            .buttonStyle(PressStyle())
        }
    }
}

struct PostCard: View {
    @Environment(AppState.self) private var state
    let post: Post
    let isOwner: Bool
    var showsRepliesLink = true
    @State private var showShare = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if post.pinned {
                MonoLabel(text: "Pinned", size: 9, color: Ink.text, icon: "pin.fill")
            }

            HStack(spacing: 12) {
                MediaBox(ref: post.authorAvatar, height: 40)
                    .frame(width: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 3) {
                    Text(post.isFounder ? "\(post.authorName) · Founder" : post.authorName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Ink.text)
                    MonoLabel(text: post.createdAt.shortAgo, size: 9, color: Ink.faint)
                }
                Spacer()
                if post.tag != .update {
                    Chip(text: post.tag.label, inverted: post.tag == .question)
                }
            }

            Text(post.text)
                .font(.body)
                .foregroundStyle(Ink.text)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if let pair = post.pair {
                HStack(spacing: 2) {
                    labelled(pair.baseline, "Baseline")
                    labelled(pair.current, "Day \(pair.daysIn)")
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else if let photo = post.photo {
                MediaBox(ref: photo, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Rectangle().fill(Ink.hairline).frame(height: 1)

            HStack(spacing: 22) {
                Button {
                    Haptics.soft()
                    state.toggleLike(post)
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: post.likedByMe ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 13, weight: .semibold))
                        Text("\(post.likes)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(post.likedByMe ? Ink.signalSoft : Ink.muted)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
                .accessibilityLabel("\(post.likedByMe ? "Unlike" : "Like") post, \(post.likes) likes")

                if showsRepliesLink {
                    NavigationLink { PostDetailView(postID: post.id) } label: {
                        Label("\(post.commentCount)", systemImage: "bubble.left").font(.subheadline).frame(minHeight: 44)
                    }.accessibilityLabel("View replies, \(post.commentCount) comments")
                }
                Button { showShare = true } label: {
                    Label("\(post.shares ?? 0)", systemImage: "arrowshape.turn.up.right").font(.subheadline).frame(minHeight: 44)
                }.accessibilityLabel("Share Labyrinth, \(post.shares ?? 0) shares")

                Spacer()

                if isOwner {
                    Button {
                        Haptics.tap()
                        state.togglePin(post)
                    } label: {
                        Image(systemName: post.pinned ? "pin.slash" : "pin")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(post.pinned ? Ink.signalSoft : Ink.muted)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Ink.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .leading) {
            if post.pinned {
                Rectangle().fill(Color.white).frame(width: 3)
            }
        }
        .sheet(isPresented: $showShare) {
            if let program = state.labyrinths.first(where: { $0.id == post.labyrinthID }) {
                // Share the program invitation, never gated post text or member photos.
                ShareLinkPreviewSheet(labyrinth: program, onShared: { state.recordShare(of: post.id) }).environment(state)
            }
        }
    }

    private func labelled(_ ref: PhotoRef, _ caption: String) -> some View {
        MediaBox(ref: ref, height: 190)
            .overlay(alignment: .bottomLeading) {
                Chip(text: caption)
                    .background(Color.black.opacity(0.6))
                    .padding(8)
            }
    }
}

struct PostDetailView: View {
    @Environment(AppState.self) private var state
    let postID: UUID
    @State private var reply = ""
    @FocusState private var replying: Bool
    private var post: Post? { state.posts.first { $0.id == postID } }
    private var replies: [PostReply] { state.replies.filter { $0.postID == postID }.sorted { $0.createdAt < $1.createdAt } }
    private var program: Labyrinth? { state.labyrinths.first { $0.id == post?.labyrinthID } }
    private var canRead: Bool { program.map { state.isOwner(of: $0) || state.isMember(of: $0) } ?? false }

    var body: some View {
        Group {
            if let post, let program, canRead {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            PostCard(post: post, isOwner: state.isOwner(of: program), showsRepliesLink: false)
                            SectionTitle(title: "Conversation")
                            if post.commentCount > replies.count {
                                Text("This sample post includes demo engagement. Replies you add below are saved on this iPhone.").font(.caption).foregroundStyle(Ink.muted)
                            }
                            if replies.isEmpty {
                                Text("Be the first to add a reply here.").font(.body).foregroundStyle(Ink.muted)
                            }
                            ForEach(replies) { item in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(item.authorName).font(.subheadline.weight(.semibold))
                                    Text(item.text).font(.body)
                                    Text(item.createdAt, style: .relative).font(.caption).foregroundStyle(Ink.muted)
                                }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Ink.surface, in: RoundedRectangle(cornerRadius: 18)).id(item.id)
                            }
                            Color.clear.frame(height: 1).id("conversationEnd")
                        }.padding(20)
                    }.onChange(of: replies.count) { _, _ in proxy.scrollTo("conversationEnd", anchor: .bottom) }
                        .safeAreaInset(edge: .bottom) {
                            HStack(alignment: .bottom, spacing: 12) {
                                TextField("Add a reply", text: $reply, axis: .vertical).lineLimit(1...4).focused($replying)
                                    .padding(14).background(Ink.surface, in: RoundedRectangle(cornerRadius: 16)).accessibilityIdentifier("replyText")
                                Button {
                                    if state.addReply(reply, to: postID) { reply = ""; replying = false; Haptics.soft() }
                                } label: { Image(systemName: "arrow.up").font(.headline).frame(width: 48, height: 48).foregroundStyle(.white).background(Ink.signal, in: Circle()) }
                                    .disabled(reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                    .accessibilityLabel("Send reply")
                            }.padding(16).background(Ink.canvas)
                        }
                }
            } else {
                ContentUnavailableView("Join to see this conversation", systemImage: "lock", description: Text("Community conversations are for members of this Labyrinth."))
            }
        }.background(Ink.canvas).foregroundStyle(Ink.text).navigationTitle("Post & replies").navigationBarTitleDisplayMode(.inline)
    }
}
